---
title: "Progress Over Perfection: How to Ship When Your Code Embarrasses You"
date: 2026-04-06T12:00:00
slug: "progress-over-perfection"
description: "Why the best engineers struggle most with shipping imperfect code, and how to build the instinct for when good enough actually is."
tags: ["engineering", "reflection"]
draft: false
---

There's a moment in every project where you look at the code you're about to ship and feel a quiet dread. Not because it's broken. It works. It passes tests. It does what the customer needs. But it's not *right*. You can see the shortcuts, the places where you traded elegance for speed, the abstractions you didn't have time to build.

If you're a good engineer, this feeling is familiar. And if you're not careful, it will make you slow.

## The trap of caring too much

Early in my career, I thought the best engineers were the ones who wrote the cleanest code. I admired the people who would spend an extra day refactoring before a merge, who insisted on getting the interface exactly right before shipping.

I was wrong. The best engineers I've worked with care deeply about quality *and* ship constantly. They've developed an instinct for when perfection matters and when it doesn't. That instinct is harder to build than any technical skill.

The trap is subtle. You're not procrastinating. You're not being lazy. You're doing what feels like the right thing: making the code better. But "better" is infinite, and the customer is waiting.

## The pattern I keep seeing

I've watched this play out on multiple teams now, and it almost always looks the same. Someone picks up a feature. The straightforward approach would take a few days. But they see the bigger picture, the scale it might need to handle someday, the abstraction that would make it "right." So instead of the simple approach, they start building the robust one. Background jobs, retry logic, graceful degradation, the works.

Weeks later, the feature finally ships. The customer uses it for a fraction of the load anyone imagined. The elegant infrastructure sits idle. And the three other things that could have shipped in that time didn't.

This isn't a story about one team or one person. I've seen it happen everywhere I've worked. And the engineer who does it is almost always one of the strongest on the team. That's what makes it so insidious. It's not incompetence. It's misplaced excellence. They're solving for the system they imagine, not the one that exists.

## The cost of over-engineering is invisible

When you ship something ugly but functional, the cost is visible. You can see the TODO comments. You can feel the cringe when a colleague reads your code. It sits in your chest during standup.

But when you over-engineer, the cost is invisible. Nobody sees the features that didn't ship while you were perfecting the one that did. Nobody counts the customer conversations that didn't happen because the product wasn't ready. Nobody measures the morale cost of a deadline that slipped because "we're almost done, just cleaning things up."

I've seen teams lose months to premature abstraction. Building for scale they didn't have. Designing for flexibility they didn't need. Perfecting interfaces for integrations that hadn't been signed yet.

The worst part is that it feels responsible. You're "doing it right." You're "avoiding tech debt." But tech debt you take on deliberately, with eyes open, is a tool. Tech debt you avoid at the cost of not shipping is just fear wearing a professional mask.

## What I actually mean by "good enough"

I want to be precise here, because "just ship it" can be terrible advice. I'm not talking about skipping tests. I'm not talking about ignoring security. I'm not talking about writing code so sloppy that the next person who touches it will waste a week understanding it.

Here's my working definition of "good enough":

**The code solves the actual problem the customer has today. It has tests for the critical paths. It doesn't introduce security vulnerabilities. And another engineer can understand what it does and why.**

That's it. Not: it handles every edge case you can imagine. Not: it scales to 10x the current load. Not: the abstraction is perfect. Not: you'd be proud to show it at a conference.

A few specific things I've learned to let go of:

**Let go of the perfect abstraction.** If you're building something for the first time, you don't know enough to design the right abstraction yet. Write the concrete thing. When you build the second and third version, the right abstraction will be obvious.

**Let go of premature scale.** If you have a hundred users, don't build for ten thousand. You'll learn things from those hundred users that completely change what "scaling" even means. I've seen teams build elaborate caching layers for data that customers didn't even end up accessing.

**Let go of theoretical edge cases.** If no customer has hit a bug, and no realistic scenario would trigger it, it's not a bug. It's a thought experiment. Fix it when someone encounters it, and you'll fix it with real context instead of imagined scenarios.

## The hardest conversation

The real challenge isn't technical. It's emotional.

I had a conversation with an engineer once about a piece of code he'd written during a crunch period. It worked perfectly. Customers were using it daily. But he was embarrassed by it. He wanted to rewrite it before anyone else had to work in that part of the codebase.

I told him something I believe deeply: the code that ships and solves real problems is better than the code that's beautiful and sitting in a branch. Not in some abstract philosophical sense. Literally better. It's generating value. It's teaching you what the customer actually needs. It's earning the right for you to spend time on the rewrite later, because now you have real usage data instead of guesses.

He didn't love hearing it. Good engineers never do. The instinct to make things right is what makes them good in the first place. But learning when to override that instinct is what makes them effective.

## How to build the instinct

I don't think you can reason your way into this. It's a pattern you develop through experience. But a few practices have helped me and the teams I've worked with:

**Ask "who is waiting for this?"** If there's a real customer, a real user, a real teammate blocked on your work, that changes the calculus. Perfection for its own sake is a luxury. Shipping for someone who needs it is a responsibility.

**Set a "ship date" before you start.** Not a deadline in the stressful sense. A decision point. "By Thursday, we ship what we have." It forces you to make scope decisions early instead of discovering at the end that you've been gold-plating.

**Review your own PR like a stranger would.** Before you add "one more improvement," read your diff from scratch. Is it clear? Does it work? Would a reviewer approve it? If yes, stop touching it.

**Track what you actually go back and fix.** I started paying attention to which shortcuts I took that I actually had to revisit. The answer was maybe 20%. The other 80% were fine. That data changed my relationship with imperfect code.

## The paradox

Here's what I've come to believe: caring about code quality is necessary, but insufficient. The engineers who have the biggest impact are the ones who can hold two things in their head at once. This code could be better, *and* it's time to ship.

That "and" is everything. Not "but." Not "so let me just." And.

The code could be better, and the customer needs it now. The abstraction isn't perfect, and we'll learn more from shipping than from thinking. I'm not fully proud of this, and it's solving a real problem.

Progress over perfection isn't about lowering your standards. It's about applying them to the right thing. The standard isn't "is this code beautiful?" The standard is "is this solving the problem it needs to solve, reliably, right now?"

That's a harder standard to meet than it sounds. Because it requires you to know the problem, know the customer, and know yourself well enough to recognize when your desire to improve the code is serving them and when it's serving your ego.

Most of the time, good enough actually is.
