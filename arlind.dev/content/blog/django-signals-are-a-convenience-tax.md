---
title: "Django signals don't have a bulk path"
date: 2026-04-06T14:00:00
slug: "django-signals-are-a-convenience-tax"
description: "Django's bulk operations skip signals, so if your side effects live in receivers you have no batch path, and you find out the day an admin action times out. Notes on what that cost us and how to keep both paths open."
tags: ["engineering"]
draft: false
featured: true
---

The first time I used Django signals I liked them a lot. Business logic out of the models, side effects in their own receivers, new behavior added without touching the code that creates the record. The first time I had to process a few hundred records that depended on them, I liked them a lot less.

## The setup

This pattern exists in almost every Django codebase that's been around for a while. A model does something important when it's created: sends a notification, adjusts a quota, creates a billing record. So it gets a receiver:

```python
from django.db import transaction
from django.db.models import Q
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone


@receiver(post_save, sender=Order)
def handle_order_created(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            user=instance.user,
            message=f"Order #{instance.id} confirmed",
        )
        Invoice.objects.create(
            order=instance,
            amount=instance.total,
        )
```

This works fine one order at a time. Django fires the signal, the receivers run, everything stays consistent, and you can add more receivers later without touching the creation code.

Then someone needs to create 500 orders at once.

## Where it breaks

`bulk_create` does not fire `pre_save` or `post_save`. It doesn't call `save()` at all, so anything in an overridden `save()` is skipped too. The same goes for `bulk_update` and `QuerySet.update()`. This is documented, it's intentional, and it's still true in Django 6.1. Adding signal support to the bulk methods has come up on the developers list and in the ticket tracker more than once, and it hasn't happened, for a reasonable reason: firing a signal per instance would throw away most of what makes the bulk methods fast.

`QuerySet.delete()` is the exception. It can fire `pre_delete` and `post_delete` per instance, because the deletion collector already walks objects to resolve cascades. There's a subtlety, though. The collector has a fast-delete path that skips fetching objects when there are no cascades and no delete receivers connected. Connect a receiver and you've turned that off for the model. So delete iterates when it has to, and your receivers are one of the things that make it have to. Create and update have no equivalent fallback.

A related trap is `m2m_changed`. Writing to a through model directly with `Through.objects.bulk_create()` skips `m2m_changed` the same way `bulk_create` skips `post_save`. It catches more people because the M2M API hides the through model, so the gap is less obvious.

It's worth separating `pre_save` from `post_save` here, because they fail differently. `post_save` receivers usually trigger side effects: notifications, invoices, syncing with an external system. Skip them and something didn't happen, but the rows in the database are still right. `pre_save` receivers often mutate the instance: setting a slug, normalizing a field, computing a denormalized value. Skip those and you've written wrong data. That's a worse failure and a quieter one.

For completeness, `update_or_create()` and `get_or_create()` do fire signals, even though the names sound bulk-ish. The gap is specifically in the set-based methods.

So when you need to create or update in bulk you have two options. You loop:

```python
for order_data in order_list:
    Order.objects.create(**order_data)  # fires signals, one at a time
```

Each `create()` is an INSERT, and each receiver runs its own queries. With K queries across your receivers and N records you're at roughly N * (1 + K) queries as a floor. In practice it's higher, because `create()` can also run unique checks, FK existence checks, and any `pre_save` receivers that query. For 500 orders and three receivers doing one query each, that's about 2,000 queries before you've done anything interesting.

Or you use `bulk_create`:

```python
Order.objects.bulk_create(orders)
```

A handful of queries, no signals, and nothing downstream happens. No notifications, no invoices.

This isn't a bug. Signals are a per-instance abstraction and bulk operations are a set-based one, and Django doesn't pretend otherwise.

One scope note: everything here is about synchronous Django. Django 5.0 added async dispatch (`Signal.asend()` and `asend_robust()`), and async plus signals plus bulk is its own problem. The bulk-skip behavior is identical, but sync receivers called from an async context get wrapped in `sync_to_async`, which serializes them further. The advice below transfers, with extra care around `on_commit` in async code.

## Where it actually hurt

The order example is simplified to show the mechanism. Where I hit this for real was an admin action that archived every pending item in a group. Originally it looked like this:

```python
def archive_items(queryset):
    for item in queryset:
        item.status = "archived"
        item.save()  # fires post_save
```

The receivers handled everything: clearing related timestamps, cancelling pending charges, notifying external services. Each concern in its own receiver. It was tidy.

Then the groups got bigger, and archiving one took long enough that the load balancer killed the request. Nothing in the code was wrong. It just had no batch path.

## Should signals own business logic at all?

Before getting into patterns that make signals survive a batch, it's worth asking whether they should own business logic in the first place.

Signals hide coupling. You can't read `Order.objects.create()` and know what happens next. You have to grep for every `post_save` receiver registered against `Order` across every app in the project, and in a large codebase with several teams adding receivers, that list gets long.

There's a second problem: receivers only fire if their module has been imported. That's why every project ends up with `from . import signals` inside `AppConfig.ready()`. People forget, the signals module never loads in a management command or a test setup that bypasses the app loader, and you get bugs of the form "works in the web request, doesn't work in the cron job". So the coupling isn't just hard to find. You can't even be sure it's active.

The alternative is a service layer, which is where most teams end up after enough of this:

```python
from functools import partial

def create_order(data):
    with transaction.atomic():
        order = Order.objects.create(**data)
        Notification.objects.create(
            user=order.user,
            message=f"Order #{order.id} confirmed",
        )
        Invoice.objects.create(order=order, amount=order.total)
        transaction.on_commit(partial(send_confirmation.delay, order.pk))
    return order


def create_orders_bulk(data_list):
    with transaction.atomic():
        orders = Order.objects.bulk_create(
            [Order(**d) for d in data_list]
        )
        Notification.objects.bulk_create([
            Notification(
                user_id=o.user_id,
                message=f"Order #{o.id} confirmed",
            ) for o in orders
        ])
        Invoice.objects.bulk_create([
            Invoice(order_id=o.pk, amount=o.total) for o in orders
        ])
        transaction.on_commit(
            partial(send_confirmations_batch.delay, [o.pk for o in orders])
        )
    return orders
```

No signals. You can read `create_order` and know exactly what happens. Each piece is testable on its own. And when someone adds a side effect, there's one obvious place for the single-record version and one for the bulk version, right next to each other, which is the point.

One assumption in the bulk path is worth spelling out. It reads `o.total` off the `Order` instances that `bulk_create` returned, which works because `total` was set in Python before the insert. If `total` came from a database default, a generated column, or a `pre_save` receiver (which, as above, won't fire), it would be `None` or stale. The bulk path assumes everything it needs is Python-side. Where that doesn't hold, re-fetch after the insert.

On `transaction.on_commit`: the Celery tasks are registered inside the atomic block but only dispatched after the transaction commits. That avoids the classic bug where the worker picks up the task before the row is visible. `functools.partial` instead of a lambda is the idiomatic way to do it, and it matters in loops, where closures over the loop variable will bite you.

Also notice the bulk path registers one on-commit callback that enqueues one batch task, not N tasks. If you registered N callbacks you'd have solved the database problem and moved the fan-out to the message broker. Whether that matters depends on N and your broker, but if you're already optimizing the database path it's worth thinking about.

One more backend note: whether `bulk_create` returns objects with primary keys set depends on your database. The docs currently list PostgreSQL, MariaDB, and SQLite. On MySQL the PKs won't be set. Check your backend and Django version if your bulk side effects need PKs. The examples here assume PostgreSQL.

Signals still have legitimate uses. Framework hooks like `django.contrib.auth`, third-party integrations that really are decoupled, and cases where the producer genuinely shouldn't know about its consumers. The problem is when they become the default place for all business logic in a growing codebase.

## Stuck with signals: the bulk-split

Back to the archive action. If the codebase already leans on signals, rewriting it into a service layer isn't happening this sprint. What worked for us was splitting the records: which ones genuinely need per-record side effects, and which can be handled as a set?

```python
def archive_items(queryset):
    with transaction.atomic():
        # Materialize once and lock rows to avoid re-evaluation surprises
        needs_dispatch = list(
            queryset.select_for_update().filter(
                Q(has_webhook=True) | Q(has_integration=True)
            )
        )
        dispatch_pks = [item.pk for item in needs_dispatch]
        bulk_safe = queryset.exclude(pk__in=dispatch_pks)

        # Bulk path: direct SQL for the common case
        RelatedRecord.objects.filter(
            item__in=bulk_safe,
        ).update(cleared_at=timezone.now())

        PendingCharge.objects.filter(
            item__in=bulk_safe,
        ).update(status="cancelled")

        bulk_safe.update(status="archived")

        # Signal path: per-record, only for the exceptions
        for item in needs_dispatch:
            item.status = "archived"
            item.save()  # signals fire for integration cleanup
```

The detail that matters: `needs_dispatch` is materialized into a list early, and the rows are locked with `select_for_update()`. If you left it as a lazy queryset it would be re-evaluated when the loop iterates it, and that happens after `bulk_safe.update()` has run. The moment someone edits the filter to include `status`, the second evaluation silently returns a different set of rows. Materializing once makes the intent explicit.

For a batch of 500 items where none have external dependencies, which was the common case for us, this takes roughly 2,000 queries down to a handful. The few items that need the full signal treatment still get it.

The transaction wrapper isn't optional. Without it, a failure halfway through leaves you with some charges cancelled and some not, some items archived and some stuck.

The tradeoff is real: you now have two code paths, and the bulk one manually replicates what the receivers do. When someone adds a receiver they have to update the bulk path too, or the two diverge without anyone noticing. This is debt you're taking on deliberately to fix a performance problem. Name it, write it down, and keep the two paths physically close so the divergence stays visible.

## A convention worth setting early

If I could set one convention early in every Django project, it would be this: every receiver is a thin wrapper around a plain function.

```python
def create_invoice(order):
    """Business logic. Callable from anywhere."""
    Invoice.objects.create(order=order, amount=order.total)


@receiver(post_save, sender=Order)
def on_order_created(sender, instance, created, **kwargs):
    """Thin wrapper. Calls the real function."""
    if created:
        create_invoice(instance)
```

That gives you an escape hatch. When you need a bulk path, or want to call the logic from a management command, or want to test it without saving anything, the function already exists. You don't have to pull it out of the signal machinery under time pressure.

It's a half step toward a service layer. Not the end state, but it keeps your options open.

## The strangler fig

Different codebase, different problem, same tension. We had two parallel paths for creating the same object. The original used `Model.objects.create()` with signals for the side effects. A newer one used a builder class with `bulk_create` for performance. They'd coexisted for years and slowly drifted: one had bug fixes the other didn't, one handled edge cases the other didn't know existed.

Killing the old path was a 42-file merge request. Every test that called the legacy method needed updating, and every edge case the old code handled had to be ported. The builder was changed to always do the database operation and then run the side-effect logic explicitly, whether for one record or a thousand.

It took weeks. Afterwards there was one way to create that object, one set of business rules, and one place to add side effects. We deleted about a thousand lines of duplicated edge-case handling, and the next three features that touched creation took days instead of weeks, mostly because nobody had to ask which path a change belonged in. The 42 files were the bill for years of "we'll unify these later".

## The tax, roughly

If your receivers make K queries per record and you're operating on N records:

| Approach | Queries |
|----------|---------|
| Per-record with signals | N * (1 + K) |
| Bulk operations only | ~K (one query per side-effect type) |
| Bulk + signal split | ~K + S * (1 + K), where S = signal-requiring records |

For most internal systems S is zero or close to it, so the split gives you a roughly constant query count regardless of N. The per-record path is linear. At small N nobody notices. At large N it's the difference between a sub-second response and a timeout.

## Starting a new Django project

Start with a service layer, not signals. Put business logic in plain functions and call them from views, management commands, and tasks. You can add signals later where you genuinely need decoupling. Removing them once they're load-bearing is much harder.

If you do use signals, keep the receivers thin. One call per receiver, pointing at logic that lives somewhere you can reach from anywhere.

Think about the batch path before you need it. You don't have to build it on day one, but if the answer to "how would this work for 500 records" is "I'd have to restructure everything", that's worth knowing early.

And accept that signals are a single-record abstraction. They're not broken, and they're well designed for what they do. But the convenience gets paid for later, and the bill arrives with your first real batch.
