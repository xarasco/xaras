# Sync Notes Posts to Blog — Design

**Date:** 2026-05-24
**Status:** Approved

## Problem

Finished posts live in `/Users/steve/notes/posts/` as plain markdown (no frontmatter). The published blog lives in `/Users/steve/projects/personal/xaras/src/content/blog/` and requires Astro-compatible frontmatter (`title`, `date`, `draft`, `slug`, `tags`, `description`). Today there is no automation: copying a post requires manually creating the frontmatter and committing in the xaras repo. We want this to happen automatically when a post is committed in notes.

## Goals

- Sync new posts from `notes/posts/` into `xaras/src/content/blog/` with valid frontmatter.
- Sync body edits to already-published posts without clobbering their frontmatter.
- Commit the result in the xaras repo with a descriptive message.
- Triggered automatically when committing in the notes repo, while still runnable manually.

## Non-Goals

- No two-way sync. The blog is the canonical store after publication for frontmatter; the notes file remains canonical for body.
- No per-post commits — one commit per sync run.
- No watcher daemon, no Astro plugin, no CMS-style editing.
- No support for frontmatter living in the notes source file. Notes files are body-only.

## Workflow

1. User edits `/Users/steve/notes/posts/foo.md` and commits in the notes repo.
2. A `post-commit` hook in `/Users/steve/notes/.git/hooks/` invokes the sync script in the xaras repo.
3. The sync script walks `notes/posts/`, classifies each file (new / updated / unchanged), prompts interactively for frontmatter on new files, writes results into `xaras/src/content/blog/`, and creates one commit in xaras summarizing what changed.

## Components

### 1. Sync script — `xaras/scripts/sync-posts.sh`

Bash script. Single entry point. Can be invoked by the hook or run manually.

**Inputs (via env vars with sensible defaults):**
- `NOTES_DIR` — default `/Users/steve/notes/posts`
- `BLOG_DIR` — default `/Users/steve/projects/personal/xaras/src/content/blog`
- `XARAS_REPO` — default `/Users/steve/projects/personal/xaras`

**Algorithm:**

For each `*.md` in `$NOTES_DIR`:

- **Case A — file does not exist in `$BLOG_DIR`** → new post.
  - If no TTY: print `[skip-new] <filename> (no TTY for prompts)` and continue. Do NOT create the file.
  - If TTY: prompt for:
    - `title` (default: filename with dashes → spaces, title-cased)
    - `description` (required, free text)
    - `tags` (comma-separated, may be empty → `[]`)
  - Auto-fill:
    - `date: <today, YYYY-MM-DD>`
    - `draft: false`
    - `slug: <filename without .md>`
  - Write `<frontmatter>\n<body from notes file>` to `$BLOG_DIR/<filename>`.

- **Case B — file exists in `$BLOG_DIR`** → check body.
  - Parse the blog file's frontmatter: the file must start with a line `---`, then YAML, then a closing line `---`. Everything after the closing `---` (skipping one trailing newline) is the body.
  - If the blog file has no parseable frontmatter (shouldn't happen for a synced post, but guard anyway): print `[skip-malformed] <filename>` and continue.
  - Compare blog body (trimmed) vs notes file content (trimmed).
  - **Identical** → skip silently.
  - **Different** → overwrite blog file with `<existing frontmatter block>\n<notes file content>`. Print `[update] <filename>`.

Files in `$BLOG_DIR` that have no counterpart in `$NOTES_DIR` are left alone.

**Commit step:**

After processing all files, in `$XARAS_REPO`:
- `git status --porcelain src/content/blog/` — if empty, exit 0 silently.
- Otherwise, build a commit message:

  ```
  blog: sync N post(s) from notes

  - add: foo.md, bar.md
  - update: baz.md
  ```

- `git add src/content/blog/` and `git commit -m "<message>"`.

**Exit codes:**
- `0` — success (including "nothing to do").
- Non-zero — only on truly broken state (e.g., `BLOG_DIR` missing, git command fails). Crucially, the script must NEVER exit non-zero in the post-commit hook context; a failure here must not surface as a notes-repo problem. The hook wraps the call to guarantee `exit 0`.

### 2. Post-commit hook — `/Users/steve/notes/.git/hooks/post-commit`

Two-line shell script:

```sh
#!/bin/sh
/Users/steve/projects/personal/xaras/scripts/sync-posts.sh || true
```

Marked executable. The `|| true` ensures the hook never reports failure to git even if the sync script bails. Because the sync commits in a *different* repo, there is no risk of recursive triggering.

## Data Flow

```
notes commit
   └─> post-commit hook
         └─> sync-posts.sh
               ├─ scan notes/posts/
               ├─ for each .md:
               │    ├─ new → prompt → write blog file with frontmatter
               │    └─ existing → diff body → overwrite body, preserve frontmatter
               └─ git commit in xaras (one commit, summarizing changes)
```

## Frontmatter Template

```yaml
---
title: <prompted, default = humanized filename>
date: <today, YYYY-MM-DD>
draft: false
slug: <filename without .md>
tags: [<prompted, comma-separated>]
description: <prompted>
---
```

## Error Handling

- **No TTY for prompts on a new post** → skip the file with a notice; do not fail. User can re-run `sync-posts.sh` manually from a terminal.
- **`BLOG_DIR` missing** → exit non-zero with clear message. (Indicates the xaras checkout is gone/moved — user must intervene.)
- **Git commit fails in xaras** (e.g., dirty working tree on unrelated files) → print warning, leave the new/updated files in place (not committed), exit 0 from the hook's perspective.
- **Notes file is empty** → treat as no body; for a new post, still prompt and write the file with just frontmatter. The user controls what's in notes/posts.
- **Notes file accidentally contains its own frontmatter block** → out of scope. The script treats notes content as opaque body; a notes file with frontmatter will produce a blog file with two frontmatter blocks. User's responsibility to keep notes body-only.

## Testing

- **Manual smoke test:** add a new file to `notes/posts/`, run `./scripts/sync-posts.sh` directly, confirm prompts work, file lands in blog/, commit created.
- **Identical-body skip:** run the script twice in a row with no changes; second run produces no commit.
- **Body update:** edit a previously synced post's body in notes, re-run; confirm blog frontmatter unchanged and body updated.
- **No-TTY skip:** run via `</dev/null ./scripts/sync-posts.sh` simulating the hook from a GUI; confirm new files skipped without error.
- **Hook end-to-end:** install the hook, commit a new post in notes, confirm xaras commit appears.

No automated tests — this is a one-off personal workflow script.

## Open Questions

None. Decisions captured during brainstorming:
- All files in `notes/posts/` are eligible (no draft flag at source).
- Interactive frontmatter prompt for missing frontmatter.
- Pre-existing posts: sync body, preserve frontmatter.
- Trigger: post-commit hook on the notes repo.
