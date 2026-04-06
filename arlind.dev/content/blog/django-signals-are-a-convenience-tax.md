---
title: "Django Signals Are a Convenience Tax"
date: 2026-04-06T14:00:00
slug: "django-signals-are-a-convenience-tax"
description: "Django signals make single-record workflows elegant, but they quietly make bulk operations impossible. Here's what that costs at scale, and how to design for both paths from the start."
tags: ["engineering"]
draft: false
---

The first time I used Django signals, I thought they were brilliant. Decouple your business logic from your models. Fire a signal when a record is created, and let receivers handle the side effects. Clean. Elegant. Extensible.

The first time I had to bulk-process 500 records that relied on signals, I thought they were a trap.

## The setup

Here's a pattern you'll find in almost every mature Django codebase. You have a model that does something important when it's created. Maybe it sends a notification, adjusts a quota, or creates a billing record. So you wire up a signal:

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

This works perfectly when you create one order at a time. Django fires the signal, the receivers run, everything is consistent. You can add more receivers later without touching the creation code. The side effects live in their own module.

Now try creating 500 orders at once.

## Where it breaks

Django's `bulk_create` does not fire `pre_save` or `post_save` signals. Neither does `bulk_update`. Neither does `QuerySet.update()`. This is documented, intentional, and has been this way since these methods were introduced. It remains the case through Django 6.0. Multiple community proposals to add signal support have been discussed and declined, because firing per-instance signals would eliminate the performance benefit of bulk operations.

Worth noting: `QuerySet.delete()` is the exception. It *does* fire `pre_delete` and `post_delete` per instance, because Django's deletion collector iterates over each object to resolve cascades. So the rule isn't "set-based operations skip signals." It's more nuanced than that, which is part of what makes this tricky.

When you need to create or update records in bulk, you have two options. Loop:

```python
for order_data in order_list:
    Order.objects.create(**order_data)  # fires signals, one at a time
```

Each `.create()` triggers a database INSERT. Each signal receiver runs its own queries. If you have K queries across your receivers and you're creating N records, that's roughly N * (1 + K) total queries: N inserts plus K side-effect queries per record. For 500 orders with 3 receivers doing one query each, that's around 2,000 queries.

Or you can use `bulk_create`:

```python
Order.objects.bulk_create(orders)
```

Far fewer queries. But no signals fire. No notifications. No invoices. Everything downstream is out of sync.

This isn't a bug. It's a design tension baked into the framework. Signals are a per-instance abstraction. Bulk operations are a set-based abstraction. Django doesn't pretend they're the same thing.

## The real cost

I've hit this in systems where a batch operation needed to process hundreds of records. An admin action to archive all pending items in a group. The original code looked something like this:

```python
def archive_items(queryset):
    for item in queryset:
        item.status = "archived"
        item.save()  # fires post_save
```

The signal receivers handled everything: clearing related timestamps, cancelling pending charges, notifying external services. Each concern lived in its own receiver. It was well-organized.

Then the dataset grew. Archiving started taking minutes. Database connections piled up. Timeouts hit. The code was correct, just architecturally unprepared for the batch path.

## The deeper question: should signals own your business logic?

Before jumping to patterns that make signals work at scale, it's worth asking whether signals should own business logic at all.

Signals create invisible coupling. You can't look at `Order.objects.create()` and know what happens next. You have to grep for every `post_save` receiver registered against `Order`, across every app in your project. In a large codebase with many teams contributing receivers, that search gets long.

The alternative is an explicit service layer:

```python
from functools import partial

def create_order(data):
    with transaction.atomic():
        order = Order.objects.create(**data)
        Invoice.objects.create(order=order, amount=order.total)
        transaction.on_commit(partial(send_confirmation.delay, order.pk))
    return order


def create_orders_bulk(data_list):
    with transaction.atomic():
        orders = Order.objects.bulk_create(
            [Order(**d) for d in data_list]
        )
        Invoice.objects.bulk_create([
            Invoice(order_id=o.pk, amount=o.total) for o in orders
        ])
        for order in orders:
            transaction.on_commit(partial(send_confirmation.delay, order.pk))
    return orders
```

No signals. The call graph is explicit. You can read `create_order` and know exactly what happens. You can test each piece in isolation. When someone adds a new side effect, there's one place to put it for single-record and one for bulk, right next to each other.

A note on `transaction.on_commit`: the Celery tasks are registered *inside* the atomic block but only dispatched *after* the transaction commits. This avoids a subtle but common bug where the async worker picks up the task before the data is actually visible in the database. Using `functools.partial` instead of a lambda is the idiomatic Django pattern, especially inside loops where closures over loop variables can bite you.

Also worth noting: `bulk_create` returns objects with primary keys on PostgreSQL and SQLite, but not on MySQL. If you're on MySQL and your bulk side-effect logic needs PKs, you'll need to re-fetch the created records. The examples here assume PostgreSQL, which is the most common setup I've worked with.

This is what many mature Django codebases evolve toward. The service layer is where most teams end up after enough signal-related pain.

That said, signals still have legitimate uses: framework-level hooks (like `django.contrib.auth`), genuinely decoupled third-party integrations, and cases where the producer truly shouldn't know about its consumers. The problem is when they become the default mechanism for all business logic in a growing codebase.

## When you're stuck with signals: the bulk-split pattern

If you're working in a codebase that already relies heavily on signals, a full rewrite to a service layer isn't realistic overnight. Here's a pragmatic pattern. Split records by their characteristics: which ones genuinely need per-record side effects, and which can be handled in bulk?

```python
def archive_items(queryset):
    with transaction.atomic():
        needs_dispatch = queryset.filter(
            Q(has_webhook=True) | Q(has_integration=True)
        )
        bulk_safe = queryset.exclude(
            pk__in=needs_dispatch.values("pk")
        )

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

For a batch of 500 items where none have external dependencies (the typical case in my experience), this collapses ~2,000 queries down to a handful. For the occasional item that needs the full signal treatment, it still gets it.

The transaction wrapper matters. Without it, a failure partway through leaves you with partially archived data: some charges cancelled, some not, some items updated, some stuck.

The tradeoff is honest: you now have two code paths. The bulk path manually replicates what the signal receivers do. If someone adds a new receiver, they need to update the bulk path too, or the two paths diverge silently. This is technical debt you're taking on deliberately to solve a performance problem. Name it, document it, and keep the two paths close together so the divergence stays visible.

## A convention worth setting early

If I could go back and set one convention early in every Django project I've worked on, it would be this: every signal receiver should be a thin wrapper around a standalone function.

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

This gives you an escape hatch. When the day comes that you need a bulk path, or you want to call the logic from a management command, or you need to test it without triggering a save, the function is already extracted. You don't have to untangle it from the signal machinery under time pressure.

It's a half-step toward a full service layer. Not the final architecture, but a convention that keeps your options open.

## The strangler fig

In one codebase I worked in, we had two parallel code paths for creating the same object. The original path used `Model.objects.create()` with signals for all the side effects. A newer path used a builder class with `bulk_create` for performance. They'd coexisted for years, slowly diverging. One path had bug fixes the other didn't. One handled edge cases the other didn't know about.

Killing the old path was a 42-file merge request. Every test that called the legacy method needed updating. Every edge case the old code handled had to be ported. The builder was updated to always handle the database operation, then explicitly run side-effect logic afterward, whether for one record or a thousand.

It took weeks. But after it landed, there was one way to create that object. One set of business rules. One place to add new side effects. The 42 files were the cost of years of "we'll unify these later."

## The tax, quantified

Here's a rough model. If your signal receivers make a total of K database queries per record, and you're operating on N records:

| Approach | Queries |
|----------|---------|
| Per-record with signals | N * (1 + K) |
| Bulk operations only | ~K (one query per side-effect type) |
| Bulk + signal split | ~K + S * (1 + K), where S = signal-requiring records |

For most internal systems where S is zero or near-zero, the split gives you effectively constant query count regardless of N. The per-record path scales linearly. At small N, nobody notices. At large N, it's the difference between a sub-second response and a timeout.

## What I'd tell someone starting a new Django project

**Start with a service layer, not signals.** Put your business logic in explicit functions. Call them from views, management commands, Celery tasks. Make the call graph visible. You can always add signals later for specific decoupling needs. You can't easily remove them once they're load-bearing.

**If you use signals, keep receivers thin.** One function call per receiver, pointing to logic that lives elsewhere. This keeps the logic testable, composable, and extractable when you need the bulk path.

**Think about the batch path before you need it.** You don't have to build it on day one. But if the answer to "how would I do this for 500 records?" is "I'd have to restructure everything," that's a design smell worth acknowledging early.

**Accept that signals are a single-record abstraction.** They're not broken. They're well-designed for what they do. But they're a convenience that compounds as your data grows. The convenience is real on day one. The tax comes due when you hit your first batch.

Build for both paths, migrate to a service layer, or plan for the rewrite. The only wrong option is pretending the batch path will never come.
