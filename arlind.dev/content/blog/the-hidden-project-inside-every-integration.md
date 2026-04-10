---
title: "The Hidden Project Inside Every Integration"
date: 2026-04-10T12:00:00
slug: "the-hidden-project-inside-every-integration"
description: "When you scope an enterprise integration as a coding task, you've already underestimated it. The credentials, certificates, and portal-access dance is the project."
tags: ["engineering", "career"]
aliases:
  - /blog/the-vendor-sandbox-is-the-project/
draft: false
---

When you scope an enterprise integration, your instinct is to estimate the code. You read the API docs, you sketch the request flow, you note the auth method, and you give a number. Maybe you pad it for the bits the docs don't tell you.

That number is wrong, and it's wrong by an embarrassing margin. Not because the code takes longer than you think. Because the code is twenty percent of the work.

The other eighty percent is the part nobody warned you about: getting a working sandbox, getting credentials, getting certificates, getting settings enabled by people you can't reach, getting your customer's IT team to do their half of the setup. None of that lives in your IDE. All of it lives on your calendar.

## Where the time actually goes

If you've never built an enterprise integration end to end, here is the part of the project that will surprise you.

**The sandbox does not exist when you start.** Or it exists but it belongs to somebody else. Or it exists but the feature you need to test is gated behind a setting only the vendor's provisioning team can flip. Getting a sandbox you can actually use is its own multi-week subproject, and you will not be able to start the engineering work in earnest until it lands.

**Credentials are not a download.** They are a sequence of requests, approvals, and forms. The API user, the client ID, the client secret, the certificate, the partner registration. Each of these comes from a different team, on a different timeline, sometimes from a different company. They will arrive in the wrong order and one of them will be wrong on the first try.

**OAuth with enterprise systems is a ritual.** It is not the OAuth flow you read about in a tutorial. It involves generating an SSL certificate, registering it through a portal you've never seen, mapping it to a client identity, and testing the handshake against a sandbox that may or may not be configured to accept it. The first successful token exchange in your local environment will feel like a small miracle. It is not a code milestone. It is a paperwork milestone.

**Settings have to be enabled in places you can't reach.** Half the integrations I've worked on have hinged on a single checkbox in a vendor admin panel that nobody on the team has access to. Finding the right person to flip that checkbox is a project. Convincing them you're allowed to ask is another one.

**Your customer has a customer side.** Even if your half of the integration is perfect, the customer has to do their half, and they will be slower than you expect by an order of magnitude. Sometimes they will refuse. Sometimes they will ask you to do it for them. Either answer becomes more engineering work.

## Why this surprises everyone

The reason these timelines blow up is that "an integration" sounds like a coding task to anyone who has not built one. Your PM thinks you're shipping a feature. Your sales team thinks you're following a recipe. Your leadership thinks the vendor has a button somewhere that says "integrate."

You think the same thing too, right up until the day you discover that the vendor's sandbox provisioning takes eight business days and the customer's IT lead is out until next month.

The work that consumes the calendar is not technically interesting. It is correspondence. It is screenshots in tickets. It is video calls with consultants who use a portal you don't have access to. It is reading a sixty-page integration guide that turns out to describe a different product. It is discovering, on day fourteen, that the credential format the docs gave you was deprecated two years ago.

None of that work shows up on your sprint board. All of it is the project.

## How to plan honestly

The fix is not to pad your estimate by five times. The fix is to scope the access dance as engineering work and make it visible from the start.

A rough checklist worth running before you commit a date:

- Who owns the sandbox, and how do you get a working one?
- What credentials do you need, who issues them, and what is the longest path between request and delivery?
- Are there vendor-side settings that have to be enabled? Who has access to flip them?
- Does the auth method involve certificates? If yes, double your auth estimate.
- Who on the customer side has to do work, what is that work, and have you written the instructions yet?
- How many distinct parties have to be in a room for a successful end-to-end test?

The number you get from this exercise is not your engineering estimate. It is your access estimate. The engineering work happens in parallel with most of it, but the access estimate is the one that controls the date.

## How to communicate it

Half the value of running this exercise is being able to walk a PM or a leader through it. The conversation that goes well sounds like this: "The code for this is two weeks, but the sandbox will take three weeks to land and the customer-side setup will take four. We can't ship faster than the slowest of those, and we don't control the slowest one."

The conversation that goes badly is the one where you give a coding estimate, the access work blows up, and you spend the next month looking like you're behind. You were not behind. You were running engineering work in parallel with paperwork that nobody scoped.

Make the paperwork part of the plan. Put the credentials checklist in the kickoff doc. Track sandbox provisioning as a milestone. Name the customer-side blocker as a dependency in week one. The work is the same either way, but now the team around you understands why the project looks the way it does.

## What to budget for

The next time you scope an enterprise integration, budget for the sandbox, not the SDK. Budget for the certificate, not the request body. Budget for the customer's onboarding day, not the deploy. Budget for the vendor's ops team being out for the holidays, because they will be.

The integration you build will be small. The project around it is the part you actually ship.
