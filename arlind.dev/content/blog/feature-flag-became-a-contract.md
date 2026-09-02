---
title: "The Feature Flag That Became a Contract"
date: 2026-04-20T13:30:00
slug: "feature-flag-became-a-contract"
description: "A feature flag stays a temporary switch only until something else starts reading it. From that point it's a contract, and deleting it is a migration, not a cleanup ticket."
tags: ["engineering"]
draft: false
featured: true
---

You sit down to clean up a flag. It was meant to be temporary. It shipped eighteen months ago, the new code path is the default everywhere, and the old path is dead.

You find the `if` that reads it and delete it. Two tests fail. They aren't testing the flag's branches. They're testing a revenue report that reads the flag to decide which customers to include. You check the callers. There are twelve.

That's not a flag anymore.

## The usual advice misses the point

Every article on feature flags ends with "remember to clean up your flags", and every flag platform ships a stale-flag detector. Both treat flags as code-level toggles whose only risk is clutter.

The failure that actually costs you is different. Somewhere between the day you added the flag and the day you tried to remove it, a second consumer started reading it. Another service. A dashboard. A customer's integration. From that moment the flag stopped being a rollout switch and became a contract, and removing a contract is a migration, not a pull request.

## How it happens

Once you look for it you see this everywhere. The ways I've seen it happen most often:

A downstream report keys off it. You ship `new_billing_flow` to roll out usage-based pricing. A month later the finance dashboard filters customers by it to split revenue. Now the flag is load-bearing for revenue attribution, and turning it off is a conversation with finance, not a cleanup.

A customer integration observes it. Your API exposes the flag's state, directly or by shape: a new field, a changed error code, a different payload. A customer wires their integration to that difference. The flag is now part of your public contract, and you never published it.

Support uses it as a tier indicator. Someone asks whether a customer is on Enterprise. A support engineer checks `enterprise_scim=true`. Fast, convenient, wrong. The flag has become the tier check across four internal tools, because nobody gave support a better one.

Observability keys off it. Dashboards group by flag, alert rules filter by flag, incident reports reference flag state. The flag is a segmentation column now, and the on-call engineer is the last person you want to surprise by deleting it.

Tests pin it. The test suite hard-codes one branch because "that's the one customers use". Removing the flag means rewriting the test matrix. This is the smallest version of the problem, and often the first sign that the branches have drifted further apart than you thought.

## Why it keeps happening

The mechanism is nearly always the same: product and engineering are using one primitive for lifecycles that have nothing in common.

A rollout toggle lives for days or weeks. Someone flips it on, watches, and removes it. A billing entitlement lives for years, because a customer signed a contract for the thing it gates. A kill switch lives indefinitely and gets used once a year during an incident.

All three read `flag_on("x")` in code. None of them share a risk profile. And flag platforms make the collapse easy: same API, same UI, same retention policy. You end up with `new_billing_flow` and `emergency_shutdown_writes` in the same dashboard, and your stale-flag audit treats them identically.

## Three kinds of flag

A habit worth adopting is naming the kind at creation time, in the flag name or a tag, and then treating each kind differently.

| Type | Lifespan | Owner | Removal |
|---|---|---|---|
| **Release flag** | Days to weeks | Originating engineer | Delete once rolled out to 100% |
| **Ops flag** | Indefinite | On-call / SRE | Rare; tested on a cadence |
| **Entitlement flag** | Years | Product / Billing | Migration + customer comms |

The mistake is using a release flag's primitive for an entitlement. Entitlements need a data model: a subscriptions table, a capabilities matrix, something with guarantees. When a flag drifts from toggle to entitlement by accretion, you've built a capability system with none of the properties of one.

## Signs you've already crossed the line

If more than one of these is true, the flag is a contract, and its removal should be planned as a migration:

- Customers know the flag's name. It's in your public API surface.
- Support answers tier questions by reading flag values. It's a billing source of truth.
- Dashboards group customers by it. It's an observability column.
- Alerts filter by it. It's part of incident response.
- Tests hard-code a specific combination of flags. The branches have diverged past easy rollback.
- The removal ticket is blocked on "let's check with the other team first". The flag has owners outside your service.

## Prevention is cheaper

A few habits that cost a little discipline now and save a migration later.

Scope flag readers to the service that owns the branch. Reports, observability, and integrations should read from stable contracts that are populated from the flag, not from the flag itself. An entitlement column on the account. A capabilities endpoint. A published field on a billing object. If that sounds like extra work, it's the same work you'd otherwise do at removal time, under worse conditions.

For each new reader, ask whether the branch outlives the rollout. If it does, don't use the flag. Use an entitlement.

Name the kind at creation. A `release_`, `ops_`, or `ent_` prefix is a small habit that makes the flag platform filterable by lifecycle and makes the audit mean something.

Retire graduated flags the way you deprecate an API. Publish a date, give consumers time, provide the stable replacement. A flag that has become a contract deserves a changelog entry, not a cleanup ticket.

## The dangerous day

It isn't the day you add the flag. It's the day someone, usually on a different team, adds a second code path that reads it without telling you. From then on you own a contract, and you'll pay for it the day you try to remove the thing you thought was temporary.

So the rule isn't "clean up your flags". It's: know who reads your flags, and treat the second reader as the moment the flag changes what it is.
