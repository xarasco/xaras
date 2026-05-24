# Sync Notes Posts to Blog — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auto-sync finished posts from `/Users/steve/notes/posts/` into `src/content/blog/`, with interactive frontmatter prompts for new posts and body-only updates for existing ones, triggered by a post-commit hook on the notes repo.

**Architecture:** Single bash script in `scripts/sync-posts.sh` performs the full sync (scan, classify, prompt, write, commit). A two-line `post-commit` hook in `/Users/steve/notes/.git/hooks/` invokes the script after every notes commit. The script is also runnable standalone from a terminal.

**Tech Stack:** Bash (POSIX-compatible where convenient, with `[[ ]]` and arrays — `#!/bin/bash`), standard Unix tools (`awk`, `diff`, `cmp`, `git`).

**Spec:** `docs/superpowers/specs/2026-05-24-sync-posts-design.md`

---

## File Structure

- **Create:** `scripts/sync-posts.sh` — the sync script. Single file. ~150 lines.
- **Create:** `/Users/steve/notes/.git/hooks/post-commit` — two-line hook invoking the script.
- **Create:** `tests/sync-posts.bats` (optional, see Task 9) — only if we add bats tests. Plan defaults to manual smoke testing.

No source files in the Astro app are modified. The script lives at the repo root under `scripts/`, alongside future utility scripts.

---

## Task 1: Scaffold the script with arg/env defaults and dir checks

**Files:**
- Create: `scripts/sync-posts.sh`

- [ ] **Step 1: Create the script with shebang and config**

Create `scripts/sync-posts.sh` with the following content:

```bash
#!/bin/bash
# sync-posts.sh — sync finished posts from notes/posts → xaras blog.
# See docs/superpowers/specs/2026-05-24-sync-posts-design.md

set -u  # error on unset vars; intentionally NOT set -e (we handle errors ourselves)

NOTES_DIR="${NOTES_DIR:-/Users/steve/notes/posts}"
BLOG_DIR="${BLOG_DIR:-/Users/steve/projects/personal/xaras/src/content/blog}"
XARAS_REPO="${XARAS_REPO:-/Users/steve/projects/personal/xaras}"

if [[ ! -d "$NOTES_DIR" ]]; then
  echo "sync-posts: NOTES_DIR not found: $NOTES_DIR" >&2
  exit 1
fi
if [[ ! -d "$BLOG_DIR" ]]; then
  echo "sync-posts: BLOG_DIR not found: $BLOG_DIR" >&2
  exit 1
fi
if [[ ! -d "$XARAS_REPO/.git" ]]; then
  echo "sync-posts: XARAS_REPO is not a git repo: $XARAS_REPO" >&2
  exit 1
fi

echo "sync-posts: scanning $NOTES_DIR"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/sync-posts.sh
```

- [ ] **Step 3: Run it once to verify scaffold works**

Run: `./scripts/sync-posts.sh`
Expected: prints `sync-posts: scanning /Users/steve/notes/posts` and exits 0.

- [ ] **Step 4: Commit**

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): scaffold script with directory checks"
```

---

## Task 2: Add helpers — `humanize_filename` and `has_tty`

**Files:**
- Modify: `scripts/sync-posts.sh` (append helper functions)

- [ ] **Step 1: Add helpers above the `echo "sync-posts: scanning"` line**

In `scripts/sync-posts.sh`, insert before the final `echo`:

```bash
# humanize_filename "my-cool-post.md" -> "My Cool Post"
humanize_filename() {
  local base="${1%.md}"
  echo "$base" | tr '-_' '  ' | awk '{
    for (i=1; i<=NF; i++) $i = toupper(substr($i,1,1)) substr($i,2)
    print
  }'
}

# has_tty: returns 0 if stdin is a tty (so we can prompt), 1 otherwise.
has_tty() {
  [[ -t 0 ]]
}
```

- [ ] **Step 2: Smoke-test the helper inline**

Temporarily append at the end of the script:

```bash
humanize_filename "a-small-lisp.md"
has_tty && echo "tty: yes" || echo "tty: no"
```

Run: `./scripts/sync-posts.sh`
Expected: `A Small Lisp` then `tty: yes` (when run from a terminal).

Then run: `./scripts/sync-posts.sh </dev/null`
Expected: `A Small Lisp` then `tty: no`.

- [ ] **Step 3: Remove the temporary smoke-test lines**

Delete the two test lines from the end of the script.

- [ ] **Step 4: Commit**

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): add humanize_filename and has_tty helpers"
```

---

## Task 3: Add frontmatter parsing helper

**Files:**
- Modify: `scripts/sync-posts.sh`

- [ ] **Step 1: Add the parser function**

Append to `scripts/sync-posts.sh` (after `has_tty`):

```bash
# extract_blog_body <path>
# Prints the body of a blog file (everything after the closing --- of the
# YAML frontmatter). If the file has no parseable frontmatter, returns 1
# and prints nothing.
extract_blog_body() {
  local path="$1"
  awk '
    BEGIN { state = 0 }              # 0=before, 1=in fm, 2=after
    NR == 1 && /^---[[:space:]]*$/ { state = 1; next }
    state == 1 && /^---[[:space:]]*$/ { state = 2; next }
    state == 2 { print }
    END { exit (state == 2 ? 0 : 1) }
  ' "$path"
}

# extract_blog_frontmatter <path>
# Prints the frontmatter block including the opening and closing --- lines.
# Returns 1 if no frontmatter found.
extract_blog_frontmatter() {
  local path="$1"
  awk '
    BEGIN { state = 0 }
    NR == 1 && /^---[[:space:]]*$/ { print; state = 1; next }
    state == 1 { print }
    state == 1 && /^---[[:space:]]*$/ { state = 2; exit }
    END { exit (state == 2 ? 0 : 1) }
  ' "$path"
}
```

- [ ] **Step 2: Smoke-test against an existing blog file**

Temporarily append at the end of the script:

```bash
echo "--- body of a-small-lisp ---"
extract_blog_body "$BLOG_DIR/a-small-lisp.md" | head -3
echo "--- frontmatter of a-small-lisp ---"
extract_blog_frontmatter "$BLOG_DIR/a-small-lisp.md"
```

Run: `./scripts/sync-posts.sh`
Expected: prints the first 3 lines of the post body, then the full frontmatter block (starting and ending with `---`).

- [ ] **Step 3: Remove the temporary smoke-test lines**

Delete the four test lines from the end of the script.

- [ ] **Step 4: Commit**

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): add frontmatter parsing helpers"
```

---

## Task 4: Add interactive frontmatter prompt for new posts

**Files:**
- Modify: `scripts/sync-posts.sh`

- [ ] **Step 1: Add the prompt function**

Append to `scripts/sync-posts.sh`:

```bash
# prompt_frontmatter <filename>
# Prints a complete YAML frontmatter block (including --- delimiters) to stdout.
# Reads interactively from /dev/tty so it works inside hook contexts that have
# a controlling tty but redirected stdin.
prompt_frontmatter() {
  local filename="$1"
  local slug="${filename%.md}"
  local default_title
  default_title="$(humanize_filename "$filename")"

  local title description tags_raw tags_yaml today
  today="$(date +%Y-%m-%d)"

  printf "\nNew post: %s\n" "$filename" >&2
  printf "  title [%s]: " "$default_title" >&2
  IFS= read -r title </dev/tty
  [[ -z "$title" ]] && title="$default_title"

  printf "  description: " >&2
  IFS= read -r description </dev/tty
  while [[ -z "$description" ]]; do
    printf "  description (required): " >&2
    IFS= read -r description </dev/tty
  done

  printf "  tags (comma-separated, optional): " >&2
  IFS= read -r tags_raw </dev/tty

  if [[ -z "$tags_raw" ]]; then
    tags_yaml="[]"
  else
    # "foo, bar, baz" -> "[foo, bar, baz]" (no quotes — matches existing style)
    local trimmed
    trimmed="$(echo "$tags_raw" | sed 's/[[:space:]]*,[[:space:]]*/, /g; s/^[[:space:]]*//; s/[[:space:]]*$//')"
    tags_yaml="[$trimmed]"
  fi

  cat <<EOF
---
title: $title
date: $today
draft: false
slug: $slug
tags: $tags_yaml
description: $description
---
EOF
}
```

- [ ] **Step 2: Smoke-test the prompt**

Temporarily append at the end of the script:

```bash
prompt_frontmatter "test-post.md"
```

Run: `./scripts/sync-posts.sh`
Expected: prompts for title, description, tags. After entering values, prints a valid YAML frontmatter block to stdout.

Try empty description — confirm it re-prompts.
Try empty title — confirm it uses the default `Test Post`.

- [ ] **Step 3: Remove the temporary smoke-test line**

Delete the test line.

- [ ] **Step 4: Commit**

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): add interactive frontmatter prompt"
```

---

## Task 5: Implement the main sync loop (new files)

**Files:**
- Modify: `scripts/sync-posts.sh`

- [ ] **Step 1: Add the sync loop and tracking arrays**

Append to `scripts/sync-posts.sh` (replacing the trailing `echo "sync-posts: scanning $NOTES_DIR"` if it's still there — keep that echo near the top, just above the loop):

```bash
added=()
updated=()
skipped_no_tty=()
skipped_malformed=()

shopt -s nullglob
for src in "$NOTES_DIR"/*.md; do
  filename="$(basename "$src")"
  dest="$BLOG_DIR/$filename"

  if [[ ! -e "$dest" ]]; then
    # New post.
    if ! has_tty; then
      echo "[skip-new] $filename (no TTY for prompts)" >&2
      skipped_no_tty+=("$filename")
      continue
    fi
    fm="$(prompt_frontmatter "$filename")"
    {
      echo "$fm"
      cat "$src"
    } > "$dest"
    echo "[add] $filename"
    added+=("$filename")
  else
    # Existing post — sync body if different.
    if ! existing_fm="$(extract_blog_frontmatter "$dest")"; then
      echo "[skip-malformed] $filename" >&2
      skipped_malformed+=("$filename")
      continue
    fi
    existing_body="$(extract_blog_body "$dest")"
    new_body="$(cat "$src")"
    # Trim trailing whitespace for comparison.
    if [[ "$(printf '%s' "$existing_body")" == "$(printf '%s' "$new_body")" ]]; then
      continue  # identical, skip silently
    fi
    {
      echo "$existing_fm"
      echo "$new_body"
    } > "$dest"
    echo "[update] $filename"
    updated+=("$filename")
  fi
done
shopt -u nullglob
```

- [ ] **Step 2: Test against the real notes/posts directory**

Run: `./scripts/sync-posts.sh`
Expected: 4 prompts, one for each file in `/Users/steve/notes/posts/`. After entering valid frontmatter for each, the files appear in `src/content/blog/`.

Before answering prompts: open a second terminal and `ls src/content/blog/` to confirm files are absent.
After: `ls src/content/blog/` shows 4 new files.

- [ ] **Step 3: Verify a synced file looks right**

```bash
head -10 src/content/blog/about-stephen.md
```

Expected: valid YAML frontmatter with the values you entered, followed by the original notes body.

- [ ] **Step 4: Run again with no changes**

Run: `./scripts/sync-posts.sh`
Expected: no `[add]` or `[update]` lines printed; script exits silently.

- [ ] **Step 5: Test the no-TTY path**

```bash
# Delete one of the newly-synced files to make it "new" again
rm src/content/blog/about-stephen.md
./scripts/sync-posts.sh </dev/null
```

Expected: `[skip-new] about-stephen.md (no TTY for prompts)` printed; file NOT created.

- [ ] **Step 6: Test the update path**

```bash
# Edit one of the notes posts:
echo "" >> /Users/steve/notes/posts/llm-hmm-1.md
echo "EDIT: a new sentence." >> /Users/steve/notes/posts/llm-hmm-1.md
./scripts/sync-posts.sh
```

Expected: `[update] llm-hmm-1.md` printed. Inspect `src/content/blog/llm-hmm-1.md` — frontmatter unchanged, body has the new sentence.

Then revert the notes edit:

```bash
cd /Users/steve/notes && git checkout posts/llm-hmm-1.md && cd -
./scripts/sync-posts.sh   # reverts blog file body too
```

- [ ] **Step 7: Reset blog/ to a known state for the next task**

Decide whether to keep the newly-synced files or revert them. For testing purposes, keep them — they'll be committed by Task 6's commit step. If you'd rather not keep them, `rm` them now.

- [ ] **Step 8: Commit the script (not the synced blog content yet)**

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): implement core sync loop with new/update/skip cases"
```

---

## Task 6: Add the commit step at the end of the script

**Files:**
- Modify: `scripts/sync-posts.sh`

- [ ] **Step 1: Append the commit logic**

Append to `scripts/sync-posts.sh`:

```bash
# Build commit message from tracking arrays and commit in the xaras repo.
total_changes=$(( ${#added[@]} + ${#updated[@]} ))
if (( total_changes == 0 )); then
  exit 0
fi

# Comma-join helper.
join_csv() {
  local IFS=','
  echo "$*"
}

msg_lines=("blog: sync ${total_changes} post(s) from notes" "")
if (( ${#added[@]} > 0 )); then
  msg_lines+=("- add: $(join_csv "${added[@]}" | sed 's/,/, /g')")
fi
if (( ${#updated[@]} > 0 )); then
  msg_lines+=("- update: $(join_csv "${updated[@]}" | sed 's/,/, /g')")
fi
commit_msg="$(printf '%s\n' "${msg_lines[@]}")"

cd "$XARAS_REPO" || { echo "sync-posts: cannot cd to $XARAS_REPO" >&2; exit 1; }

# Only stage the blog directory — don't sweep up unrelated changes.
git add src/content/blog/

# If nothing actually staged (e.g., user already committed manually), skip.
if git diff --cached --quiet; then
  echo "sync-posts: nothing staged after add; skipping commit"
  exit 0
fi

if ! git commit -m "$commit_msg"; then
  echo "sync-posts: git commit failed; changes left staged" >&2
  exit 0   # don't fail the hook
fi

echo "sync-posts: committed $total_changes change(s)"
```

- [ ] **Step 2: Test the end-to-end flow**

Make sure the working tree in xaras is clean apart from any synced blog files from Task 5:

```bash
git status
```

If files from Task 5 are still uncommitted in `src/content/blog/`, that's fine — Task 6 will commit them.

Run: `./scripts/sync-posts.sh`
Expected: exits 0. If there were uncommitted changes from earlier, a new commit appears: `blog: sync N post(s) from notes` with `- add: ...` and/or `- update: ...` bullets.

```bash
git log -1 --stat
```

Expected: shows the new commit touching only `src/content/blog/*.md`.

- [ ] **Step 3: Test the "nothing changed" path**

Run: `./scripts/sync-posts.sh`
Expected: exits silently, no new commit.

```bash
git log -1
```

Expected: still the previous commit.

- [ ] **Step 4: Commit the script change**

If the script itself is uncommitted:

```bash
git add scripts/sync-posts.sh
git commit -m "feat(sync-posts): commit synced changes in xaras repo"
```

---

## Task 7: Install the post-commit hook in the notes repo

**Files:**
- Create: `/Users/steve/notes/.git/hooks/post-commit`

- [ ] **Step 1: Write the hook**

```bash
cat > /Users/steve/notes/.git/hooks/post-commit <<'EOF'
#!/bin/sh
# Sync finished posts to the xaras blog after every notes commit.
# Wrapping in `|| true` so a sync failure never surfaces as a notes-repo error.
/Users/steve/projects/personal/xaras/scripts/sync-posts.sh || true
EOF
chmod +x /Users/steve/notes/.git/hooks/post-commit
```

- [ ] **Step 2: Verify it's executable**

```bash
ls -l /Users/steve/notes/.git/hooks/post-commit
```

Expected: starts with `-rwxr-xr-x` (or similar — `x` bits set).

- [ ] **Step 3: End-to-end test**

In `/Users/steve/notes`:

```bash
cd /Users/steve/notes
# Create a brand new post
cat > posts/hook-test-post.md <<'EOF'
# Hook Test Post

This post exists to verify the post-commit hook fires the xaras sync.
EOF
git add posts/hook-test-post.md
git commit -m "test: hook smoke test post"
```

Expected: after the notes commit succeeds, the sync script runs. Since git's post-commit hook inherits the terminal's TTY, prompts should appear. Answer them.

After:

```bash
cd /Users/steve/projects/personal/xaras
ls src/content/blog/hook-test-post.md   # should exist
git log -1                              # should show the sync commit
```

- [ ] **Step 4: Clean up the test post**

```bash
cd /Users/steve/notes
git rm posts/hook-test-post.md
git commit -m "test: remove hook smoke test post"

cd /Users/steve/projects/personal/xaras
rm src/content/blog/hook-test-post.md
git add src/content/blog/hook-test-post.md
git commit -m "blog: remove hook smoke test post"
```

Note: removing the notes file does NOT trigger a deletion in blog/ (sync is additive only by design). The manual removal above is intentional.

- [ ] **Step 5: No commit needed for the hook itself** (it lives in `.git/hooks/` and isn't tracked)

Done.

---

## Task 8: Document the workflow in scripts/README.md

**Files:**
- Create: `scripts/README.md`

- [ ] **Step 1: Write the readme**

Create `scripts/README.md`:

````markdown
# scripts/

## sync-posts.sh

Syncs finished posts from `/Users/steve/notes/posts/` into `src/content/blog/`.

**Manual run:**

```bash
./scripts/sync-posts.sh
```

For each `.md` file in `notes/posts/`:
- **New** (not in `blog/`) → prompts for title, description, tags; writes a blog file with auto-filled frontmatter (`date`, `slug`, `draft: false`).
- **Existing, body changed** → overwrites body in `blog/`, preserves frontmatter.
- **Existing, body identical** → skips silently.

After processing, commits all changes in `src/content/blog/` as a single commit.

**Automatic run via notes post-commit hook:**

The hook at `/Users/steve/notes/.git/hooks/post-commit` invokes this script after every commit in the notes repo. Reinstall with:

```bash
cat > /Users/steve/notes/.git/hooks/post-commit <<'EOF'
#!/bin/sh
/Users/steve/projects/personal/xaras/scripts/sync-posts.sh || true
EOF
chmod +x /Users/steve/notes/.git/hooks/post-commit
```

**Environment overrides:**
- `NOTES_DIR` (default `/Users/steve/notes/posts`)
- `BLOG_DIR` (default `/Users/steve/projects/personal/xaras/src/content/blog`)
- `XARAS_REPO` (default `/Users/steve/projects/personal/xaras`)

**Design doc:** `docs/superpowers/specs/2026-05-24-sync-posts-design.md`
````

- [ ] **Step 2: Commit**

```bash
git add scripts/README.md
git commit -m "docs(scripts): document sync-posts.sh and hook installation"
```

---

## Task 9: Final end-to-end verification

**Files:** none modified.

- [ ] **Step 1: Confirm xaras tree is clean**

```bash
cd /Users/steve/projects/personal/xaras
git status
```

Expected: clean working tree.

- [ ] **Step 2: Confirm notes tree is clean**

```bash
cd /Users/steve/notes
git status
```

Expected: clean working tree.

- [ ] **Step 3: Verify all current notes posts are reflected in blog**

```bash
ls /Users/steve/notes/posts/*.md | xargs -n1 basename
ls /Users/steve/projects/personal/xaras/src/content/blog/*.md | xargs -n1 basename
```

Expected: every file in `notes/posts/` appears in `blog/`. (Blog may contain extra files — the original 6 posts — that's expected.)

- [ ] **Step 4: Verify the Astro build still passes**

```bash
cd /Users/steve/projects/personal/xaras
npm run build
```

Expected: build succeeds. If a synced post fails the content collection schema (e.g., bad tag format), fix it manually in the blog file and consider whether the prompt in `prompt_frontmatter` needs adjustment.

- [ ] **Step 5: Done.** No commit.

---

## Self-Review Notes

- **Spec coverage:** workflow (Tasks 5-7), frontmatter template (Task 4), body-preserving update (Task 5), TTY handling (Tasks 4, 5), commit message format (Task 6), hook (Task 7), error handling (Tasks 1, 5, 6), testing checklist (Tasks 5, 7, 9). All covered.
- **Names consistent across tasks:** `humanize_filename`, `has_tty`, `extract_blog_body`, `extract_blog_frontmatter`, `prompt_frontmatter`, arrays `added`/`updated`/`skipped_no_tty`/`skipped_malformed`. Used identically wherever they appear.
- **No placeholders:** every code block is complete; every command has expected output.
