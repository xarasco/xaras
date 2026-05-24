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

# humanize_filename "my-cool-post.md" -> "My Cool Post"
humanize_filename() {
  local base="${1%.md}"
  echo "$base" | tr -- '-_' '  ' | awk '{
    for (i=1; i<=NF; i++) $i = toupper(substr($i,1,1)) substr($i,2)
    print
  }'
}

# has_tty: returns 0 if stdin is a tty (so we can prompt), 1 otherwise.
has_tty() {
  [[ -t 0 ]]
}

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

echo "sync-posts: scanning $NOTES_DIR"

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
