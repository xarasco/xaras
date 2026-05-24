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

````bash
cat > /Users/steve/notes/.git/hooks/post-commit <<'EOF'
#!/bin/sh
/Users/steve/projects/personal/xaras/scripts/sync-posts.sh || true
EOF
chmod +x /Users/steve/notes/.git/hooks/post-commit
````

**Environment overrides:**
- `NOTES_DIR` (default `/Users/steve/notes/posts`)
- `BLOG_DIR` (default `/Users/steve/projects/personal/xaras/src/content/blog`)
- `XARAS_REPO` (default `/Users/steve/projects/personal/xaras`)

**Design doc:** `docs/superpowers/specs/2026-05-24-sync-posts-design.md`
