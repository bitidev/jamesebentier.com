# Code Patterns

Project-specific recurring patterns for jamesebentier.com. Examples are from this codebase.

---

## Pattern: declare_schema on Models

**When to use**: Defining or extending ActiveRecord models that need UUID PKs, validations, and indexes.

**Example**:
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  declare_schema id: :uuid, default: 'gen_random_uuid()' do
    string :slug, limit: 255, null: false,
           validates: { presence: true, uniqueness: { case_sensitive: false } },
           index: { unique: true }
    # ...
  end
end
```

**Rationale**: Keeps schema + validations colocated; avoids hand-drifting `schema.rb` as the mental model.

**DO**: Add fields inside the `declare_schema` block and generate migrations via the gem's workflow.

**DON'T**: Add columns only in a raw migration while leaving the model block stale.

---

## Pattern: Slug-Based Resource Lookup

**When to use**: Public show pages for posts/projects.

**Example**:
```ruby
# app/controllers/blog_controller.rb
def show
  @post = Post.find_by!(slug: params[:slug].downcase)
end
```

**Rationale**: SEO-friendly URLs; posts normalize slug case in `before_validation`.

**DO**: Downcase inbound slugs for posts; use bang finders when a missing record should 404.

**DON'T**: Mixed `find_by` / `find_by!` without intentional nil handling (projects currently use non-bang `find_by` — prefer consistency with blog).

---

## Pattern: Markdown Body on Disk

**When to use**: Storing long-form post/project narrative.

**Example**:
```ruby
# app/models/post.rb
def content
  @content ||= begin
    file_content = Rails.public_path.join('blog', file_path).read
    file_content.split("---\n", 3).last.chomp
  end
end
```

**Rationale**: Content edits are git-friendly; DB holds SEO metadata and publish time.

**DO**: Keep `file_path` as a basename under `public/blog`; strip YAML front matter before render.

**DON'T**: Interpolate raw request params into filesystem paths.

---

## Pattern: Idempotent Content Seeds

**When to use**: Bootstrapping projects and syncing posts from markdown files.

**Example**:
```ruby
# db/seeds.rb
Post.find_or_initialize_by(slug: ...).update!(file_path: File.basename(file), **data)

Dir[File.expand_path('../public/blog/*.md', __dir__)].each do |file|
  data = YAML.safe_load_file(file, symbolize_names: true, permitted_classes: [Date])
  # ...
end
```

**Rationale**: Safe to re-run `db:seed` in any environment.

**DO**: Use `find_or_initialize_by` + `update!`; permit only needed YAML classes.

**DON'T**: Destructive `delete_all` seeds for content that operators may have edited in DB.

---

## Pattern: Custom Redcarpet Renderer

**When to use**: Rendering blog/project markdown with site typography classes.

**Example**:
```ruby
# app/helpers/blog_helper.rb
def render_markdown(content)
  markdown = Redcarpet::Markdown.new(Blog::Renderer, autolink: true, tables: true)
  markdown.render(content).html_safe
end
```

**Rationale**: Keeps Tailwind class choices in `Blog::Renderer`, not scattered in markdown.

**DO**: Extend `Blog::Renderer` for new element styles.

**DON'T**: Pass untrusted user input through `.html_safe` without sanitization.

---

## Pattern: Resume YAML as Presentation Data

**When to use**: Resume page content.

**Example**:
```ruby
# app/helpers/resume_helper.rb
def resume_data
  @resume_data ||= YAML.safe_load_file(Rails.root.join("resume/resume.yml"), symbolize_names: true)
end
```

**Rationale**: Resume is structured data edited outside the DB; helper memoizes per request.

**DO**: Keep resume fields in `resume/resume.yml`; map levels to CSS via `style_for_level`.

**DON'T**: Duplicate resume content into ActiveRecord without a migration plan.

---

## Pattern: Sitemap Reflection with noindex?

**When to use**: Controlling which models/controllers appear in `sitemap.xml`.

**Example**: Controllers/models override `self.noindex?` (default `false` on `ApplicationController` / `ApplicationRecord`). `config/sitemap.rb` skips when `noindex?` is true.

**DO**: Opt out via `noindex?` rather than hardcoding skip lists in the sitemap config.

**DON'T**: Forget to set `noindex?` when adding private/admin controllers later.

---

## Pattern: Shoulda Model Specs Aligned to Schema

**When to use**: Locking declare_schema columns and validations.

**Example**: `spec/models/post_spec.rb` asserts DB column types/limits and Shoulda validations in lockstep with the model block.

**DO**: When adding a declare_schema field, add the matching Shoulda/column examples.

**DON'T**: Spec only happy-path factories while ignoring uniqueness/null constraints.
