# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

arlind.dev: personal blog for Arlind. Built with Hugo. Topics: career lessons, technical deep-dives, personal reflections.

## Architecture

- Hugo static site (v0.123.7)
- Layouts in `layouts/` (no external theme)
- Articles are markdown files in `content/blog/`
- Single CSS file in `static/css/style.css`
- Fonts: Inter (body/UI) and Lora (home intro) via Google Fonts
- No custom JavaScript (only Google Analytics gtag)
- Deploy: cron polls GitHub every 3 minutes, pulls new commits, runs `hugo --minify`
- Deploy script tracks last built commit in `/var/www/arlind.dev/.built-commit` to handle local pushes
- Served by Caddy at https://arlind.dev
- For local pushes, run `hugo --minify --destination /var/www/arlind.dev` directly (deploy script skips when HEAD matches origin)

## Commands

- **Build site:** `hugo --minify`
- **Dev server:** `hugo server -D` (includes drafts, live reload on localhost:1313)
- **New post:** `hugo new blog/my-post-slug.md` (or create the file directly)

## Writing Articles

### File location

`content/blog/<slug>.md` where the slug becomes the URL: `arlind.dev/blog/<slug>/`

### Front matter format

```yaml
---
title: "The Post Title"
date: 2026-04-06T12:00:00
slug: "the-post-title"
description: "A one-sentence summary for SEO and social sharing."
tags: ["career", "engineering"]
draft: false
---
```

Note: Include a time component in `date` to control ordering when multiple posts share the same date.

### Writing guidelines

- Use Arlind's voice: thoughtful, direct, technically precise but accessible
- First person, conversational but not casual
- Include concrete examples and specific details
- Structure with clear H2/H3 headings
- Keep paragraphs short (3-4 sentences max)
- For technical posts: include code blocks with language annotation
- Target 800-1500 words unless the topic demands more
- The `description` field is critical -- it appears in search results, social cards, and as the TL;DR at the top of each article
- Never use em dashes. Use commas, periods, or restructure the sentence instead
- Never use the surname "Hoxha". Just use "Arlind" or nothing at all
- Reference the site as arlind.dev, not by full name

### Content categories (use as tags)

- `career`: leadership, management, career growth
- `engineering`: software architecture, tools, practices
- `reflection`: personal essays, lessons learned
- `tutorial`: step-by-step technical guides

## Publishing

1. Create the markdown file in `content/blog/`
2. Set `draft: false` in front matter
3. Commit and push to `main`
4. The deploy cron picks it up within 3 minutes

Commit messages: imperative mood, concise (e.g. "Add post on distributed systems tradeoffs").

## Topic Generation

When asked to suggest article topics, draw from:

- Any MCP-connected sources available at runtime (Notion, Linear, Slack, Confluence, etc.)
- The user's professional context as a technical leader
- Current trends in software engineering relevant to the user's domain
- Gaps in the existing content (check `content/blog/` for what's already published)

Propose topics as a numbered list with:
1. A working title
2. One-sentence description
3. Suggested tags
4. Estimated reading time
