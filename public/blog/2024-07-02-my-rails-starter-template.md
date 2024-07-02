---
slug: 2024-07-02-my-rails-starter-template
title: My Rails Starter Template
description: The first step of any Rails project is getting the started template up and running. This is what my template looks like.
published_at: 2024-07-02
image: /blog/images/my-rails-starter-template.webp
keywords: ruby on rails, starter template, web development, full stack application, project planning
tags:
- web-development
- ruby-on-rails
- project-planning
- starter-template
---

In [my last post](/blog/2024-06-28-how-to-decide-what-is-necessary), I shared the process of deciding what the priorities were for converting my site as well as what stack to use. In this post, I'll share the base template I use for all my Rails applications. This is not an in-depth setup guide, but rather an overview of the tools I use to get started quickly.

## Rails New Options

The first thing that needs to be done with any rails application, is the initialization through `rails new`. Here are the options I use and why:

1. `--name ...`: I always set the name, because I don't alway have the luxury of a directory that matches the name of the application
2. `--database=postgresql`: I decided that a PostgreSQL database was the best option
3. `--skip-test`: I prefer RSpec over Minitest for it's readability and usability, so I will install the test framework later
4. `--javascript=webpack`: I would like to use DaisyUI with Tailwind, which requires a more asset compilation flexibility than the new default `importmap`
5. `--css=tailwind`: My new css love is Tailwind for it's simplicity, so we're obviously going with that

This is what the command looks like:

```bash
rails new jamesebentier.com-rails \
  --name=james_ebentier \
  --database=postgresql \
  --skip-test \
  --javascript=webpack \
  --css=tailwind
```

And with that, we have a new Rails application ready to go.

## Testing Framework

The next thing to make sure is fully set up is the testing framework. I use RSpec for it's readability and flexibility. But it is also important to have
sound fixture support through `factory_bot_rails` and `faker`, database
management with `database_cleaner`, request testing with `rspec-rails`,
and linter support through `rubocop-rspec`.

Add coverage reporting and a couple other gems on top and the additions to the `Gemfile` look like this:

```ruby
group :development, :test do
  gem 'rubocop',             require: false
  gem "rubocop-factory_bot", require: false
  gem 'rubocop-rspec',       require: false
end

group :test do
  gem "database_cleaner-active_record"
  gem "factory_bot-awesome_linter"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end
```

## DaisyUI with Tailwind

Next we need to make sure my new favorite component library is set up and ready to go. DaisyUI is a Tailwind CSS component library that makes it easy to build beautiful and responsive designs. It is a plugin for Tailwind CSS that adds a set of components, which are designed to be used in a wide variety of applications.

To do this we run:

```bash
yarn add daisyui
```

And add the following to our `tailwind.config.js`:

```javascript
module.exports = {
  // ...
  plugins: [
    require('daisyui'),
  ],
  daisyui: {
    themes: ["light", "dark"],
  },
}
```

Now we have the ability to quickly build out beautiful components in both a
light and dark theme.

## Declare Schema

So, the next part is a bit controversial, but I like to declare the schema of my models in the model file itself. This is because I like to have a single source of truth for the shape of the data that is being stored. This is done through the `declare_schema` gem.

```ruby
gem 'declare_schema'
```

This allows me to add a `declare_schema` block to my models like so:

```ruby
class Post < ApplicationRecord
  declare_schema do
    string :title, null: false
    text :content, null: false
    timestamps
  end
end
```

And generate the necessary migration file with:

```bash
rails generate declare_schema:migration
```

## SEO and Social Sharing Setup

Whenever I'm building a new Rails application, and SEO is important (so always)
I make sure to use the `meta-tags` and `sitemap_generator` gems. This allows me to easily generate a site map based on the routes and models, and control the
meta tags for each page.

```ruby
gem 'meta-tags'
gem 'sitemap_generator'
```

There are some best practices I've learned over the years that I'll share in a future post, but for now, this is the basic setup.

## Prose Support

And last but not least, most every site needs a blog, or some form of prose to
assist with SEO. What I've found works really well for this is combining markdown
with Tailwind's typography library. This allows me to write blog posts in pure
markdown and have them styled beautifully. To set this up, I need to add the following

```ruby
gem 'redcarpet'
```

```bash
yarn add @tailwindcss/typography
```

With these two added and properly configured, I can now write blog posts like this one in markdown and have them styled by tailwind.

## Conclusion

This is the base template I use for all my Rails applications. It is a good starting point for any new project, and has all the tools I need to get started quickly. In future posts, I'll go into more detail on how I use these tools, and how I customize them for each project. But for now, this is a good starting point for anyone looking to get started with Rails.
