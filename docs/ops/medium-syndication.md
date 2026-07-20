# Medium Syndication Runbook

This site follows a [POSSE](https://indieweb.org/POSSE) model: content is published here first and optionally syndicated to Medium. The `medium_url` column on `Post` stores the Medium URL when a syndicated copy exists; the show page renders an "Also on Medium" link automatically.

---

## Forward POSSE: Publish here → Medium

1. Publish the post on this site (add a markdown file under `public/blog/`, seed it, deploy).
2. On Medium, use **Import a story** (`medium.com/p/import`): paste the canonical post URL (`https://jamesebentier.com/blog/<slug>`).
3. Medium imports the content and sets `rel=canonical` back to the site URL — SEO accrues here.
4. Copy the resulting Medium story URL (e.g. `https://medium.com/@jebentier/some-slug-abc123`).
5. Set `medium_url` on the post (see [How to set medium_url](#how-to-set-medium_url) below).
6. Deploy; confirm the "Also on Medium" link appears on the show page.

---

## Reverse: Medium-only articles → This site

Use this when an article already lives on Medium and you want to bring it home as the canonical source.

1. **Copy content** — paste the Medium article body into a new file `public/blog/YYYY-MM-DD-Title-Slug.md`.
2. **Add front matter** following existing conventions (see any file in `public/blog/` for the template). Include `medium_url` with the original Medium story URL.

   ```yaml
   ---
   slug: yyyy-mm-dd-short-title
   title: Full Article Title
   description: One-sentence description for cards and meta tags.
   published_at: YYYY-MM-DD
   keywords: comma, separated, keywords
   image: /logo.png
   tags:
   - tag-one
   - tag-two
   kind: deep_dive
   medium_url: https://medium.com/@jebentier/original-story-slug-abc123
   ---
   ```

3. **Seed** — the seeds script (`db/seeds.rb`) reads all `public/blog/*.md` files and upserts `Post` rows from their front matter. Run:

   ```bash
   bundle exec rails db:seed
   ```

4. **Verify** — visit `/blog/<slug>` and confirm:
   - The article renders correctly.
   - The "Also on Medium" link appears in the metadata row and points to the original URL.

5. **Optional follow-up (later)** — once the site is established as canonical, edit the Medium story to update its canonical URL to the site's URL (`https://jamesebentier.com/blog/<slug>`). This transfers SEO credit to the site. This step is not required immediately and is safe to defer.

---

## How to set `medium_url`

### Via front matter (preferred for markdown-driven posts)

Add `medium_url` to the YAML front matter in the `public/blog/*.md` file and re-seed:

```yaml
medium_url: https://medium.com/@jebentier/some-article-abc123
```

```bash
bundle exec rails db:seed
```

### Via Rails console (for one-off updates)

```ruby
post = Post.find_by!(slug: "yyyy-mm-dd-the-slug")
post.update!(medium_url: "https://medium.com/@jebentier/some-article-abc123")
```

### Clearing the link

Set `medium_url` to `nil` (or remove it from front matter and re-seed):

```ruby
post.update!(medium_url: nil)
```

A blank/nil `medium_url` suppresses the "Also on Medium" link with no other side effects.
