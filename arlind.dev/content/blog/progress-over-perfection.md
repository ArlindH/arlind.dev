---
title: "Knowing when good enough is good enough"
date: 2026-04-06T12:00:00
slug: "progress-over-perfection"
description: "The engineers who ship slowest are often the strongest ones, because they keep polishing code that already solves the problem. This is the definition of good enough I actually use, and the tells that you've gone past it."
tags: ["engineering", "reflection"]
draft: false
---

At some point in most projects you end up looking at the code you're about to ship and not liking it. It works, the tests pass, it does what the customer asked for. But you can see the shortcuts. The abstraction you didn't build, the two functions that should be one, the retry logic you know you'll want eventually.

If you're good at this job, that feeling is familiar. It's also, in my experience, the main reason good engineers ship slowly.

## Caring too much

Early on I thought the best engineers were the ones with the cleanest code. The people who took an extra day to refactor before merging, who wouldn't ship until the interface was right. I still respect that, but I no longer think it's what makes someone effective.

The best people I've worked with care a lot about quality and also ship constantly. Somewhere along the way they built an instinct for when the polish matters and when it doesn't, and that instinct turned out to be harder to learn than any of the technical skills.

The trap is that it never feels like procrastination. You're not being lazy, you're making the code better. The problem is that "better" has no end, and someone is waiting.

## The pattern

I've watched this happen on several teams and it always looks about the same. Someone picks up a feature. The straightforward version would take a few days. But they can see where it might go, the scale it might need to handle one day, the abstraction that would make it "right", so they build the robust version instead. Background jobs, retries, graceful degradation, the works.

The feature ships weeks later. The customer uses it at a fraction of the load anyone imagined. The infrastructure sits idle. And the three other things that could have shipped in that time didn't.

The person who does this is almost always one of the strongest on the team, which is what makes it hard to push back on. It isn't incompetence. It's good engineering pointed at a system that doesn't exist yet.

## The cost you don't see

When you ship something ugly but working, the cost is right in front of you. The TODO comments. The slight cringe when a colleague opens the file. You feel it during standup.

When you over-engineer, nobody sees the cost, because the cost is everything that didn't happen. The features that didn't ship. The customer conversations that didn't happen because the product wasn't ready. The deadline that slipped by two weeks because "we're almost done, just cleaning things up".

I've seen teams lose months to this. Building for scale they didn't have, designing for flexibility they didn't need, perfecting interfaces for integrations that hadn't been signed. And it feels responsible the whole time, because you're "avoiding tech debt". Debt you take on deliberately is a tool. Debt you avoid by not shipping is fear with a professional excuse.

## What good enough means

I want to be specific here, because "just ship it" is bad advice on its own. I'm not talking about skipping tests, ignoring security, or writing something so tangled that the next person loses a week understanding it.

My working definition is short. The code solves the problem the customer has today. The critical paths have tests. It doesn't introduce a security hole. And another engineer can read it and understand what it does and why.

That's the whole bar. Not every edge case you can imagine. Not ten times the current load. Not the perfect abstraction. Not something you'd show at a conference.

A few things I've learned to let go of:

- The perfect abstraction. If you're building something for the first time, you don't know enough to design it yet. Write the concrete version. By the second or third time you need it, the right shape is usually obvious.
- Scale you don't have. With a hundred users, don't build for ten thousand. Those hundred users will teach you things that change what "scaling" even means. I've seen caching layers built for data that customers never ended up requesting.
- Theoretical edge cases. If no customer has hit it and no realistic path triggers it, it's a thought experiment, not a bug. Fix it when someone hits it, with real context instead of an imagined scenario.

## The conversation nobody enjoys

The hard part isn't technical. It's a conversation I've had a few times with an engineer about code they wrote under pressure. It works. Customers use it every day. And they're embarrassed by it and want to rewrite it before anyone else has to touch that part of the codebase.

What I tell them is that the code that shipped and solves a real problem is better than the beautiful version sitting in a branch. Not philosophically better. Better in the plain sense: it's producing value, it's showing you what the customer actually needs, and it's buying you the right to do the rewrite later with real usage data instead of guesses.

Nobody likes hearing this. The urge to make things right is what makes them good in the first place. Knowing when to override it is what makes them effective.

## Building the instinct

I don't think you can reason your way into this. It comes from experience, but a few habits speed it up:

- Ask who is waiting. A real customer, a real user, a teammate blocked on your work. Perfection for its own sake is a luxury. Shipping for someone who needs it is a responsibility.
- Pick a ship date before you start. Not a deadline in the stressful sense, a decision point. "Thursday we ship what we have." It forces scope decisions early instead of letting you discover at the end that you've been gold-plating.
- Read your own diff like a stranger. Before adding one more improvement, read it from scratch. Is it clear? Does it work? Would you approve it as a reviewer? Then stop touching it.
- Keep track of what you actually go back and fix. I started paying attention to which of my shortcuts came back to bite me. It was maybe one in five. The rest were fine. That number did more for my relationship with imperfect code than any argument.

## Holding both

Caring about code quality is necessary but not sufficient. The engineers with the most impact can hold two things at once: this could be better, and it's time to ship. The "and" is doing all the work in that sentence.

Progress over perfection isn't a lower standard. It's the same standard aimed at the right thing. Not "is this code beautiful" but "does this solve the problem it needs to solve, reliably, now". That's a harder question than it sounds, because answering it means knowing the problem, knowing the customer, and being honest with yourself about whether the extra day of polish is for them or for you.

Most of the time, good enough is.
