---
title: "The Feature Flag That Became a Contract"
date: 2026-04-20T13:30:00
slug: "feature-flag-became-a-contract"
description: "A feature flag is a temporary rollout switch until a second piece of code reads it. After that, it's a contract, and removing it is a migration."
tags: ["engineering"]
draft: false
---

You sit down to clean up a flag. It was supposed to be temporary. It shipped eighteen months ago, the new code path is the default everywhere, and the old one is dead code.

You find the `if` that reads it and delete it. Run the tests. Two fail. You check the tests. They aren't testing the flag's branches, they're testing a revenue report that reads the flag to decide which customers to include. You check the callers. There are twelve.

That flag is not a flag anymore.

## The textbook rule doesn't say what matters

Every feature-flag article ends with "remember to clean up your flags." Every flag platform has a stale-flag detector. The framing treats flags as code-level toggles whose only risk is clutter.

That framing misses the failure that actually costs you. A flag's danger is not that the code path goes stale. It's that, somewhere between the day you added it and the day you tried to remove it, a second consumer started reading it. A different service. A dashboard. A customer's integration. From that moment on, the flag has stopped being a rollout switch and started being a contract.

Removing a contract is a migration, not a pull request.

## The five ways a flag becomes a contract

Once you start looking, you see this pattern everywhere.

**A downstream report keys off it.** You ship `new_billing_flow` to roll out usage-based pricing. A month later, the finance dashboard filters customers by it to split MRR. The flag is now load-bearing for revenue attribution. Flipping it off isn't a cleanup, it's a finance team conversation.

**A customer integration observes it.** Your API response exposes the flag's state, directly or by shape (a new field, a changed error code, a reshaped payload). A customer wires their integration to that difference. Your flag is part of your public contract, and you didn't publish it.

**Support uses it as a tier indicator.** Someone asks "is this customer on Enterprise?" A support engineer checks `enterprise_scim=true`. Fast, convenient, wrong. The flag is now the tier check across four internal systems, because nobody gave Support a better one.

**Observability keys off it.** Dashboards group by flag. Alert rules filter by flag. Incident reports reference flag state. The flag has become a segmentation column in your observability stack, and the oncall engineer is the last person you want to surprise by removing it.

**Tests pin it.** The test suite hard-codes one branch because "that's the one customers use." Removing the flag means rewriting the test matrix. This is the smallest version of the problem, but it's often the first sign the branches diverged further than you thought.

## Why this keeps happening

The mechanism is almost always the same: your product organization and your engineering organization are using the same primitive for two radically different lifecycles.

A rollout toggle lives for days or weeks. Someone flips it on, monitors, and removes it. A billing entitlement lives for years. A customer signs a contract, and the capability it gates on is something they paid for. A kill switch lives indefinitely, used once a year in an incident.

All three read `flag_on("x")` in the code. None of them share a risk profile. Flag platforms encourage the collapse. Same API, same UI, same retention policy. You end up with `new_billing_flow` and `emergency_shutdown_writes` in the same dashboard, and your stale-flag audit treats them the same way.

## Three types of flag

A useful habit is to name the type at creation time, in the flag itself or in a tag. Then treat each type differently.

| Type | Lifespan | Owner | Removal |
|---|---|---|---|
| **Release flag** | Days to weeks | Originating engineer | Delete once rolled out to 100% |
| **Ops flag** | Indefinite | On-call / SRE | Rare; tested on a cadence |
| **Entitlement flag** | Years | Product / Billing | Migration + customer comms |

The mistake is using a release flag's primitive for an entitlement. Entitlements need a data model, a subscriptions table, a capabilities matrix, not a runtime toggle. When a flag crosses from "toggle" to "entitlement" by accretion, you've built a capability system with none of the guarantees of one.

## Signs you've already crossed the line

If more than one of these is true, the flag is a contract. Plan its removal as a migration.

| Sign | What it actually means |
|---|---|
| Customers know your flag names | The flag is in your public API surface |
| Support uses flag values to answer tier questions | The flag is a billing source of truth |
| Dashboards group customers by flag value | The flag is an observability column |
| Alerts filter by flag value | The flag is in your incident response |
| Tests hard-code a specific flag combination | Branches have diverged past easy rollback |
| Removal ticket is blocked by "let's check with another team" | The flag has owners outside your service |

## Prevention, not cleanup

Prevention is cheaper than removal. A few habits worth the discipline:

**Scope flag readers to the service that owns the branch.** Observability, reports, and integrations should read from stable contracts populated from the flag, not from the flag itself. An entitlement column in the user record. A capabilities endpoint. A published field on a billing object. If that sounds like extra work, it's the work that would have come due at removal time anyway.

**Audit readers, not writers.** When you add `flag_on("x")` in a new codebase, ask: does this branch need to outlive the rollout? If yes, don't use the flag. Use an entitlement.

**Name the type at creation.** A `release_` prefix, an `ops_` prefix, an `ent_` prefix. Small habit, big downstream clarity. You also make it trivial to filter your flag platform by lifecycle.

**Retire flags with the ceremony you use for API deprecation.** Publish a date. Give consumers time. Provide a stable replacement. A flag that's graduated into a contract deserves a changelog entry, not a cleanup ticket.

## The most dangerous day for a flag

It isn't the day you add it. It's the day someone, usually in a different team, adds a second code path that reads it without telling you.

From that moment, you own a contract, and you'll pay for it the day you try to remove the flag you thought was temporary.

The rule isn't "clean up your flags." It's: **track who reads your flags, and treat the second reader as a contract event.**
