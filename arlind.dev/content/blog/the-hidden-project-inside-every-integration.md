---
title: "The Hidden Project Inside Every Integration"
date: 2026-04-10T12:00:00
slug: "the-hidden-project-inside-every-integration"
description: "If you estimate an enterprise integration by reading the API docs, you've estimated the wrong project. The sandbox, the credentials, the certificates, and the customer's own IT team are most of the calendar."
tags: ["engineering", "career"]
aliases:
  - /blog/the-vendor-sandbox-is-the-project/
draft: false
---

When you scope an enterprise integration, the natural thing to estimate is the code. You read the API docs, sketch the request flow, note the auth method, and give a number, maybe padded a bit for whatever the docs don't mention.

That number is wrong by a lot, and not because the code takes longer than you think. In my experience the code is somewhere around a fifth of the work. The rest is getting a sandbox that works, getting credentials, getting certificates, getting a setting enabled by someone you can't reach, and getting the customer's IT team to do their half. None of that happens in your editor. All of it happens on your calendar.

## Where the time goes

If you haven't built one of these end to end, this is the part that will surprise you.

The sandbox doesn't exist when you start. Or it exists but belongs to someone else. Or it exists but the feature you need to test is behind a setting that only the vendor's provisioning team can flip. Getting a sandbox you can actually use is its own multi-week subproject, and you can't really start the engineering until it lands.

Credentials are not a download. They're a sequence of requests, approvals, and forms. API user, client ID, client secret, certificate, partner registration. Each one comes from a different team on a different timeline, sometimes from a different company. They arrive in the wrong order, and one of them is wrong on the first try.

OAuth with enterprise systems is not the OAuth from the tutorial. It involves generating a certificate, registering it through a portal you've never seen, mapping it to a client identity, and testing the handshake against a sandbox that may or may not be configured to accept it. The first successful token exchange on your machine will feel like a milestone. It's a paperwork milestone.

Settings have to be enabled in places you can't reach. Half the integrations I've worked on hinged on one checkbox in a vendor admin panel that nobody on the team could see. Finding the person who can tick it is a task. Convincing them you're allowed to ask is another one.

The customer has their own side. Even when your half is perfect, the customer has to configure theirs, and they'll be slower than you expect by a wide margin. Sometimes they'll decline. Sometimes they'll ask you to do it for them. Either way, more engineering work.

## Why everyone underestimates it

"An integration" sounds like a coding task to anyone who hasn't built one. Your PM thinks you're shipping a feature. Sales thinks you're following a recipe. Leadership assumes the vendor has a button somewhere.

You think the same until the day you find out the vendor's sandbox provisioning takes eight business days and the customer's IT lead is out until next month.

The work that eats the calendar isn't technically interesting. It's email threads. Screenshots in tickets. Video calls with consultants who use a portal you don't have access to. A sixty-page integration guide that turns out to describe a different product. Discovering on day fourteen that the credential format in the docs was deprecated two years ago.

None of that shows up on the sprint board, and all of it is the project.

## Planning honestly

The fix isn't multiplying the estimate by five. It's treating the access work as engineering work and making it visible from day one.

Before committing to a date, I go through roughly this list:

- Who owns the sandbox, and what does it take to get a working one?
- Which credentials do we need, who issues each one, and what's the longest path from request to delivery?
- Are there vendor-side settings to enable, and who can flip them?
- Does auth involve certificates? If yes, double the auth estimate.
- What does the customer have to do on their side, and have we written those instructions yet?
- How many separate parties need to be in a room for one end-to-end test?

What comes out of this isn't the engineering estimate. It's the access estimate. The engineering runs in parallel with most of it, but the access estimate is the one that controls the date.

## Saying it out loud

Half the value of doing this is being able to walk a PM or a leader through it. The version of the conversation that goes well sounds like: "The code is two weeks. The sandbox will take three weeks to land and the customer-side setup will take four. We can't ship faster than the slowest of those, and we don't control the slowest one."

The version that goes badly is the one where you give a coding estimate, the access work blows up, and you spend a month looking behind. You weren't behind. You were doing engineering in parallel with paperwork nobody scoped.

So put the paperwork in the plan. Put the credentials checklist in the kickoff doc. Track sandbox provisioning as a milestone. Name the customer-side dependency in week one. The work is the same either way, but now everyone around you understands why the project looks the way it does.

## What to budget for

Next time, budget for the sandbox before the SDK, the certificate before the request body, and the customer's onboarding day before the deploy. Then add a week for the vendor's ops team being out over the holidays, because they will be.

The integration you build is small. The project around it is what you actually ship.
