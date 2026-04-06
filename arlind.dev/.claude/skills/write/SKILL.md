---
name: write
description: Suggest article topics and draft a blog post for arlind.dev
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Agent]
---

# Write a new article for arlind.dev

You are helping Arlind write a blog post. The full process is: suggest topics, draft, refine, publish.

## Step 1: Gather source material

Pull from all available MCP-connected sources at runtime. Cast a wide net with multiple searches across different keyword groups:
- **Slack**: Search messages and threads for interesting discussions, incidents, decisions, debates
- **Notion**: Search documents, meeting notes, retrospectives, design docs broadly
- **Confluence**: Search for technical docs, architecture decisions, project wrap-ups
- **Gmail**: Search for relevant threads about technical decisions or project outcomes

Also check `content/blog/` for existing posts to avoid repeating topics.

If no MCP sources are connected, ask Arlind to describe recent work themes and draw topics from that conversation.

## Step 2: Propose 5-10 ideas

Present a numbered list. For each idea:

1. **Working title**
2. One-sentence pitch (what's the insight or lesson?)
3. Suggested tags
4. Why this is interesting to readers (not just to Arlind)

Focus on ideas that have a transferable lesson, not just "here's what happened." Good angles:
- A decision that looked wrong at the time but paid off (or vice versa)
- A technical problem with a non-obvious solution
- A pattern that keeps recurring across different teams or projects
- A common belief that turned out to be wrong in practice
- A tradeoff that nobody talks about honestly

**Important: Anonymization is non-negotiable.** No company names, no product names, no people's names, no team names, no identifiable situations. Stakeholders and colleagues who might read the blog should not be able to trace any story back to a specific person, team, or org. Keep lessons universal and change details where needed to make stories untraceable while preserving the insight.

Wait for Arlind to pick one (or suggest a variation).

## Step 3: Write the draft

Create the file at `content/blog/<slug>.md` with proper frontmatter:

```yaml
---
title: "The Post Title"
date: YYYY-MM-DDTHH:MM:SS
slug: "the-slug"
description: "One sentence for SEO, social cards, and the article TL;DR."
tags: ["relevant", "tags"]
draft: true
---
```

Set `draft: true` initially.

Writing style:
- First person, Arlind's voice: thoughtful, direct, technically precise but accessible
- Conversational but not casual
- Short paragraphs (3-4 sentences max)
- Clear H2/H3 structure
- Concrete examples and specific details (anonymized)
- 800-1500 words unless the topic demands more
- Never use em dashes. Use commas, periods, or restructure instead
- Never use the surname "Hoxha". Just "Arlind" or nothing
- Reference the site as arlind.dev

Show the full draft to Arlind for review.

## Step 4: Refine

Iterate based on Arlind's feedback. He may ask to:
- Change the angle or tone
- Add or remove sections
- Make it more/less technical
- Sharpen the intro or conclusion
- Fix anything that feels too identifiable

Keep editing the file in place. Show relevant sections after changes.

## Step 5: Publish

Only when Arlind explicitly approves:

1. Set `draft: false` in the frontmatter
2. Verify the `description` field is compelling (it shows in search results, social cards, and as the TL;DR at the top of the article)
3. Verify the `date` is set to today
4. Run `hugo --minify` to verify the build succeeds
5. Commit with message like: `Add post: <title>`
6. Push to main

The deploy cron picks it up within 3 minutes and it goes live at `arlind.dev/blog/<slug>/`.

**Do NOT push until Arlind says to publish.** Drafting and pushing are separate approvals.
