---
slug: 2024-07-05-converting-a-site-from-react-to-rails-and-tailwind-quickly-and-efficiently
title: Converting a Site from React to Rails + Tailwind Quickly and Efficiently
description: After getting a Rails base template configured and ready to go, the next step is to convert all the existing functionality of the application from the old React app to the new Rails app. This is the process I used to do that quickly and efficiently, as well as some of the lessons I learned along the way.
published_at: 2024-07-05
image: /blog/images/resume-conversion-comparison.webp
keywords: ruby on rails, web development, full stack application, project planning
tags:
- web-development
- ruby-on-rails
- project-planning
---

An hour into the conversion effort, I have my [base framework configured](/blog/2024-07-02-my-rails-starter-template), and now the real work begins. I have to convert all the existing functionality of the application from the old React app to the new Rails app. This is the process I used to do that quickly and efficiently, as well as some of the lessons I learned along the way.

## Process Overview

The conversion process is straightforward. One page at a time, converting complete sections of the site, and making sure to do the most complex work first. By shifting the complex conversions forward, it's more likely I'll find patterns that will help me later on, and even build out a more efficient process as I go. So laid out, the process looks like this:

1. Pick a page.
2. Copy the React TSX into the necessary Rails view.
3. Convert React-specific syntax into Rails equivalents.
4. Test the pages side-by-side.
5. Repeat.

## Where to Start?

The initial question comes into play: what page should I actually start with? Which page of my personal site has the most complexity in terms of this conversion effort? The answer was simple but unexpected: the resume page. The resume page contains a lot of dynamic content, as well as a lot of different React components that needed to be converted to equivalent Rails partials, helpers, or ERB loops.

![Comparison of TSX and Rails partial for resume rendering of work experience](/blog/images/resume-conversion-comparison.webp)

Above is an example side-by-side of the same section of the resume page. The left side is the React version, and the right side is the Rails version. The conversion process was rather simple, but there were a few key takeaways that I learned.

## Find and Replace Was a Saving Grace

Like the title of the section says, using find/replace was a huge time saver. The two largest patterns were:

1. Replacing `className` with `class`, which was a very simple find and replace.
2. Replacing `style={{ ... }}` with `style="..."`, which was a bit more complex and required a basic regex pattern but was still relatively simple.
3. Replacing `{ variable.map(() => ...) }` with `<% variable.each do |v| %>` and `<% end %>`, which was the most complicated but was completely doable.

These three patterns that I was forced to learn to speed up the Resume page quickly made the remaining pages a breeze to convert. All in all, these three patterns saved me hours of work manually typing out loops and converting words and syntax over to ERB.

## Tailwind Made Styling a Breeze

The other lesson I learned was really a reinforcement of a lesson I learned a few years ago: Tailwind is an amazing CSS framework, and I love using it. Because I didn't have to convert many `style={{ ... }}` attributes from TSX to standard HTML, all I had to do was make sure all the proper classes were available and applied. I didn't need to copy CSS or SCSS files over, didn't need to worry about the cascade, just had to copy the code, find/replace `className` to `class`, and watch the page come to life.

## Conclusion

All in all, the conversion of the existing pages took about 6 hours of work to make sure everything was converted over, and the functionality, SEO, and performance were all still intact. This left me the full next day to handle my next topic, which is setting up the initial deployment automation and getting DNS routing to the new Rails app.

If you find these blog posts interesting, give me a follow on Twitter [@jebentier](https://twitter.com/jebentier) and/or subscribe to my [blog RSS feed](/blog.rss) to keep up with my progress.
