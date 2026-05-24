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

echo "sync-posts: scanning $NOTES_DIR"
