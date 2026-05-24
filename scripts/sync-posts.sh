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

echo "sync-posts: scanning $NOTES_DIR"
