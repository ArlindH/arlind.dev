---
name: write
description: Suggest article topics and draft a blog post for arlind.dev
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Agent]
---

# Write a new article for arlind.dev

You are helping Arlind write a blog post. The full process is: suggest topics, draft, refine, publish.

## Step 0: Check existing topic backlog

Before researching, check memory for an existing topic backlog (project_blog_topics.md). If one exists with approved ideas, present those first. Only do fresh research if Arlind wants new ideas beyond the backlog.

## Step 1: Gather source material

Focus on things Arlind is directly involved in (tagged, assigned, stakeholder, author). Don't search broadly across all company activity.

**Primary sources (in order of value):**
- **GitLab**: Use `glab api` CLI (authenticated on gitlab.codility.net as arlind.hoxha, user ID 245). Search MRs: `glab api "/merge_requests?scope=all&author_id=245&state=merged&order_by=updated_at&sort=desc&per_page=100" --hostname gitlab.codility.net`. Get MR details: `glab api "/projects/{url_encoded_project}/merge_requests/{iid}" --hostname gitlab.codility.net`
- **Jira/Confluence**: Search with Atlassian MCP tools, filter by Arlind's account_id: 61f65e13c224b80069b8edb6
- **Slack**: Search with `from:U030VS3LH2Q` filter
- **Notion**: Search for meeting notes and docs involving Arlind (user ID: 573525c9-6619-4971-9676-1c79e970afc3)

Gmail and Linear are low value. Skip unless specifically asked.

Also check `content/blog/` for existing posts to avoid repeating topics.

## Step 2: Propose ideas

Present 20-30 ideas (Arlind is selective). For each:

1. **Working title**
2. One-sentence pitch
3. Suggested tags
4. Why readers care

**What Arlind wants:**
- Technical topics grounded in real problems he solved (MRs, code, architecture decisions)
- Universal lessons, not specific stories about specific people
- Generic code examples, never copied from the actual codebase
- Concrete and actionable, not abstract leadership advice

**What Arlind does NOT want:**
- Topics that name or could identify colleagues, teams, or companies
- Abstract "lessons learned" without technical substance
- Anything that reads as bragging
- Drafts that are too autobiographical or diary-like ("too specific, a lot of Is"). Use "you" more than "I". Keep it universal and compact, not a sequence of personal anecdotes.

**Anonymization is non-negotiable.** No company names, no product names, no people's names, no team names, no identifiable situations.

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

**For technical posts specifically:**
- Use generic code examples that illustrate the concept, never copy from the codebase
- Ensure code is idiomatic and would pass a code review (Pythonic, proper Django patterns)
- Fact-check all framework version claims and API behavior
- Verify examples handle transactions, error cases, and edge cases correctly
- Include `functools.partial` over lambdas in Django `on_commit` patterns
- Note database backend differences where relevant (PostgreSQL vs MySQL)

Show the full draft to Arlind for review.

## Step 4: Technical review

Before showing the draft, run a principal-engineer-level self-review:
- Is every claim about framework behavior factually correct and version-specific?
- Would a Django core contributor find anything wrong?
- Do the code examples have bugs, race conditions, or missing transaction wrappers?
- Do before/after examples match (same side effects in both)?
- Are war stories technically accurate (e.g., "connection pool exhaustion" vs "request timeout")?
- Are numbers internally consistent across sections?
- Does the post acknowledge tradeoffs honestly, not just present patterns as clean wins?

Fix issues before showing the draft.

## Step 5: Refine

Iterate based on Arlind's feedback. He may ask to:
- Change the angle or tone
- Add or remove sections
- Make it more/less technical
- Sharpen the intro or conclusion
- Fix anything that feels too identifiable

Keep editing the file in place. Show relevant sections after changes.

## Step 6: Publish

Only when Arlind explicitly approves:

1. Set `draft: false` in the frontmatter
2. Verify the `description` field is compelling (it shows in search results, social cards, and as the TL;DR at the top of the article)
3. Verify the `date` is set to today
4. Run `hugo --minify` to verify the build succeeds
5. Commit with message like: `Add post: <title>`
6. Push to main

For immediate deploy: `hugo --minify --destination /var/www/arlind.dev`

The deploy cron also picks it up within 3 minutes at `arlind.dev/blog/<slug>/`.

**Do NOT push until Arlind says to publish.** Drafting and pushing are separate approvals.
