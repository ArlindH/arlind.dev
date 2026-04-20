---
title: "Push the Aggregation Down"
date: 2026-04-20T13:00:00
slug: "push-the-aggregation-down"
description: "When your dashboard fetches 40,000 rows to compute three numbers, the fix isn't a cache. It's an annotation."
tags: ["engineering", "tutorial"]
draft: false
---

Dashboards die the same way twice a year. Someone opens a page, it spins for eighteen seconds, and you find a function that looks like this:

```python
def dashboard_summary(user):
    orders = user.orders.all()
    return {
        "count": len(orders),
        "revenue": sum(o.total_price for o in orders),
        "avg_order": sum(o.total_price for o in orders) / len(orders) if orders else 0,
    }
```

There is nothing obviously wrong here. It reads like Python. It passes review. It works on your laptop with four seed orders. Then it ships and hits a customer with 40,000 rows, and now the web process is pulling every column of every order into memory to compute three numbers.

The fix is not a cache. The fix is to stop reducing in Python when the database is a specialist at reducing.

## The symptom

Every team I've worked with has some version of this pattern. It shows up with a few tells:

- A `total = 0` before a `for` loop
- A `sum(x.field for x in qs)` where `qs` might return thousands of rows
- A `len(qs)` used for counting, which evaluates the entire queryset as a side effect
- A comprehension that builds a list just to take its length

The cost is almost always the same: full rows materialized from Postgres, shipped over the connection, hydrated into model instances, looped, garbage-collected. The database did a sequential scan it didn't need to, and Python did reduction it shouldn't be doing.

## The fix, in three moves

Django's ORM gives you three aggregation levers. All three push the work to the database.

`aggregate()` for whole-queryset scalars.
`annotate()` for per-row computed columns.
`Count("id", filter=Q(...))` for conditional aggregates on the same set.

Rewriting the dashboard:

```python
from django.db.models import Avg, Count, Sum

def dashboard_summary(user):
    return user.orders.aggregate(
        count=Count("id"),
        revenue=Sum("total_price"),
        avg_order=Avg("total_price"),
    )
```

One query. One row back. The SQL is roughly:

```sql
SELECT COUNT(id), SUM(total_price), AVG(total_price)
FROM orders
WHERE user_id = %s;
```

The database has an index on `user_id`, it uses it, and the whole thing takes a few milliseconds regardless of whether the user has forty orders or forty thousand.

## Per-row aggregates: `annotate()`

The same instinct applies when you want one row per entity with a computed total.

Before:

```python
def customers_with_totals():
    results = []
    for customer in Customer.objects.all():
        total = sum(o.total_price for o in customer.orders.all())
        results.append({"customer": customer, "total": total})
    return results
```

This is the textbook N+1. One query to list customers, then one query per customer to pull their orders. A hundred customers, a hundred and one queries.

After:

```python
from django.db.models import Sum

def customers_with_totals():
    return Customer.objects.annotate(
        total_spent=Sum("orders__total_price"),
    )
```

One query, with a `LEFT OUTER JOIN` and a `GROUP BY customer.id`. Every row in the result already carries the computed field.

## Conditional aggregation

The hidden superpower is counting slices of the same queryset without issuing a second query.

Before:

```python
def order_breakdown(user):
    orders = list(user.orders.all())
    return {
        "total": len(orders),
        "completed": sum(1 for o in orders if o.status == "completed"),
        "refunded": sum(1 for o in orders if o.status == "refunded"),
    }
```

After:

```python
from django.db.models import Count, Q

def order_breakdown(user):
    return user.orders.aggregate(
        total=Count("id"),
        completed=Count("id", filter=Q(status="completed")),
        refunded=Count("id", filter=Q(status="refunded")),
    )
```

The `filter=` keyword on aggregates has been in Django since 2.0, and it's one of the most under-used features of the ORM. It compiles to a `FILTER (WHERE ...)` clause on Postgres and a `CASE WHEN` expression on MySQL. Either way, still one query.

## What you gain

| | Python reduce | ORM aggregate |
|---|---|---|
| Queries | 1 (N+1 for per-row totals) | 1 |
| Rows over the wire | All matching rows | 1 (or 1 per group for `annotate`) |
| Memory | O(rows) | O(1) |
| Readable intent | Hidden in a loop | Named in a dict |
| Scales with data | No | Yes |

The last row matters most. Python reductions have a failure mode that only shows up in production, at scale, on the customer who matters.

## When not to push down

Pushing down is almost always right, but not always. A few cases where reducing in Python is correct:

- **Non-SQL business logic.** If the reduction involves a Python library call, a regex, or a rule that's easier to read in code than in `Case/When`, keep it in Python. Filter the input set in the database first, then reduce the small remainder in Python.
- **Already-loaded small sets.** If you already paid to load ten rows for another reason, a Python `sum()` is fine. Don't issue a second query to save a microsecond.
- **Precision-sensitive math.** `Avg` over an integer field returns a float. If you need deterministic decimal math, specify `output_field=DecimalField()` or do the division in Python with explicit rounding.

## Gotchas worth knowing

`Sum()` returns `None`, not `0`, on empty sets. Wrap it with `Coalesce(Sum(...), Value(0))` or handle `None` at the call site. I've watched more than one report show blank totals for a perfectly valid reason, because nobody expected `None + Decimal("0")` to explode.

`annotate()` across multiple relations inflates rows. Annotating `Sum("orders__total_price")` and `Count("reviews")` in the same queryset double-counts both, because the join matrix multiplies. Use subqueries for independent aggregates on the same parent.

`values()` changes your `GROUP BY`. If you combine `annotate()` with `values()`, the grouped columns become whatever you passed to `values()`. This is occasionally what you want and frequently a surprise.

Default ordering leaks into `GROUP BY`. If your model has `Meta.ordering = ["created_at"]`, that column joins the `GROUP BY` list and silently splits your groups. Strip it with a bare `.order_by()` before aggregating.

None of these are reasons to avoid aggregation. They're reasons to run `str(qs.query)` the first time you write one, look at the SQL, and confirm the database is doing what you intended.

## The shift

The mental shift isn't "use `aggregate()` more." It's recognizing that a Python loop over a queryset is a database query you chose to write in the wrong language. The ORM didn't force that choice. You did, because the loop felt like real code and the annotation felt like a database trick.

It's the other way around. The database is the specialist. Give it the work.
