# Anti-Patterns

Anti-patterns specific to this codebase — with correct alternatives.

---

## Anti-Pattern: Schema Drift Outside declare_schema

**Description**: Adding columns/indexes only in a migration (or editing `schema.rb` mentally) without updating the model's `declare_schema` block.

**Why it's wrong**: Validations, nullability, and indexes diverge from what developers read in the model; specs that lock columns silently rot.

**Example of anti-pattern**:
```ruby
# migration only — model still missing the field declaration
add_column :posts, :canonical_url, :string
```

**Correct approach**:
```ruby
# app/models/post.rb — declare_schema first, then generate migration
string :canonical_url, limit: 1024, null: false, default: ""
```

**Detection**: Model attributes used in app/code but absent from `declare_schema`; migrations without matching model blocks.

---

## Anti-Pattern: Untrusted html_safe Markdown

**Description**: Running arbitrary user input through `BlogHelper#render_markdown` (which marks output `html_safe`).

**Why it's wrong**: XSS — Redcarpet HTML is trusted as author content today.

**Example of anti-pattern**:
```ruby
render_markdown(params[:comment_body])  # ❌ user-controlled
```

**Correct approach**:
```ruby
render_markdown(@post.content)  # ✅ author-controlled file under public/blog
# If user content is ever needed: sanitize (e.g. Loofah/rails-html-sanitizer) before html_safe
```

**Detection**: `render_markdown` call sites that do not originate from `Post#content` / `Project#content` / static strings.

---

## Anti-Pattern: Path Traversal via file_path

**Description**: Letting request input influence which file `Post#content` reads beyond a trusted basename.

**Why it's wrong**: Could read arbitrary files under the app if `file_path` is attacker-controlled.

**Correct approach**: Store `file_path` as a controlled basename from seeds (`File.basename(file)`); never assign from raw params without validation against an allowlist.

**Detection**: Controllers/strong params permitting `:file_path` from users.

---

## Anti-Pattern: Fat Controllers / Business Logic in Views

**Description**: Embedding publish filtering, YAML parsing, or markdown transforms in ERB or bloated controller actions.

**Why it's wrong**: Harder to test; duplicates domain rules.

**Example of anti-pattern**:
```erb
<% File.read(...).split("---").last %>  # ❌ in a view
```

**Correct approach**: Use `Post#content` / helpers (`render_markdown`, `resume_data`); keep controllers to slug lookup.

---

## Anti-Pattern: Inconsistent 404 Behavior

**Description**: Blog uses `find_by!` (raises) while projects use `find_by` (nil → often template error or blank page).

**Why it's wrong**: Uneven UX and error handling.

**Correct approach**: Prefer `find_by!` (or explicit `raise ActiveRecord::RecordNotFound`) for public show actions.

---

## Anti-Pattern: Skipping Architecture Catalog Updates

**Description**: Adding files under `app/` or `lib/` without updating `docs/architecture/overview.md`.

**Why it's wrong**: Breaks Universal Rule 8; `/adlc-init verify` and reviewer orphan checks fail.

**Correct approach**: Same commit updates the catalog + ownership counts; new subsystems need a `sub-systems/<slug>.md`.

---

## Anti-Pattern: Editing ADLC Framework via /adlc Symlink

**Description**: Committing changes under the live `adlc/` symlink or forgetting `/adlc` is gitignored.

**Why it's wrong**: Framework changes belong in the ADLC repo; consumer repos should only own `adlc-customizations/` and docs.

**Correct approach**: Customize via `adlc-customizations/<agent>-customizations.md`; keep `/adlc` in `.gitignore`.
