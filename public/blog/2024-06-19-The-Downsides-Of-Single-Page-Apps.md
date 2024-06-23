---
slug: 2024-06-19-The-Downsides-Of-Single-Page-Apps
title: The Downsides of Single Page Apps
description: Learn with me why single page apps are not always the best choice for your web application.
published_at: 2024-06-19
keywords: blog, jamesebentier.com, jamesebentier.com/blog, solo development best practices, single page apps, server side rendering, seo best practices, social sharing meta tags
image: /logo.png
tags:
- solo-development
- personal-sites
- cheap-hosting
---

Single Page Applications (SPAs) have become increasingly popular in recent years and this site itself is hosted
using a Single Page Application for a combined ease of development and [cheapness of delivery](https://jamesebentier.com/blog/2024-06-06-Hosting-A-Personal-Site-On-The-Cheap).
But there are some downsides to this strategy that I'm starting to learn about, which I feel is important to pass
along. So here is what I've learned so far.

## Organizational Complexity

Probably the least important, but still worth mentioning, is the organizational complexity of a Single Page Application.
When you're building an SPA, it typically starts out rather simple, you have an `index.html` file, and a small set of
`jsx` or `tsx` files providing dynamic content to the page.

But as the desires for the site grow, you start adding more components, you want to start having different pages so you
add a router with multiple dynamic pages, sometimes you want to even have dynamic routes so now we have state management
based on the URL itself, and all this while also adding more static content, RSS feeds if you're hosting a blog, the
list of addons just keeps growing.

The moment state got involved around my blog, and the desire to build an RSS feed of my blog content should have been
the first red flag that I was going down a path that was going to be more complex than SPAs are meant to handle.

## Performance

The main purpose of SPAs is to be as lightweight and performant as possible. Why force a round trip to the server when
I can just render the content dynamically directly in the browser? This is a great idea in theory, and like most things
in engineering, there is a time and place for this level of optimization.

But like my point about organization complexity, as the complexity of the site grows, the performance does the opposite.
The more pages you have the larger the bundle size gets, the more dynamic content you have and the more state management
you need, the slower the rendering will become, making the user experience flickers and jitters. This is not a good
look if you're trying to impress potential employers or clients.

So when the performance of the site starts to degrade, or the bundle of the site starts to get large, it's time to
rethink the delivery strategy of the site.

## Search Engine Optimization (SEO)

Now we're getting into the real crux of the issue with SPAs. When you're building a site, you want people to find it.
And the main way of ensuring that is by leveraging Search Engine Optimization (SEO) to make sure that your site is
discoverable on search engines like Google, Bing, and DuckDuckGo.

The problem with SPAs is that not all search engines will render the JavaScript on the page when indexing the content.
When this happens, it's just the content of the lonely `index.html` file that becomes discoverable, because the search
engine sees the site as multiple URLs all rendering the same, blank content. Not great for SEO.

Luckily the main search engine, Google, has gotten better at rendering JavaScript content, but it's still not perfect
and will often drop pages that are not rendered correctly, or are too slow to render. This is a big problem if you're
trying to build a site that people will find naturally.

## Social Media Sharing and Open Graph Meta Tags

Okay, so this is the one that got me the most, and is the reason I'm writing this blog post. When you're building a
site, especially a blog, you want people to share your content on social media. And when it's shared, you want the proper
[OpenGraph](https://ogp.me/), [Twitter](https://developer.x.com/en/docs/twitter-for-websites/cards/overview/markup), etc.
meta tags to be rendered so that the content is displayed nicely across various social platforms.

![Example of Server side rendered OpenGraph meta tags](/blog/images/ssr-social-meta-tag.webp)

In brief for those who don't know, OpenGraph meta tags are a set of tags in the HTML of a page that tell social media
platforms what to display when a link is shared. This can include anything from the title of the page, a short description,
to even the url source for the video to embed.

![Example of Broken Single Page Application OpenGraph meta tags](/blog/images/spa-social-meta-tag.webp)

Having this working properly is crucial for a blog, and when I realized that my SPA was not rendering these tags properly,
due to the fact that most social media platforms don't render JavaScript when scraping a page, I knew I had to make a
change. Without these tags, the content in the pre-rendered link looks identical, so there's no visual way to distinguish
between the different pages of the site on different social media posts.

## Conclusion

If you're looking to host a site on the cheap, and it's going to fulfill a single purpose, and you don't care about
SEO or social media sharing, then a Single Page Application is a great way to go. But if you're looking to build a
site that people will find, enjoy, and share, then you might want to consider a more traditional approach to web
development by developing a multi-page application using available frameworks like Rails, Next.js, or Wordpress.

All this said, I'll be converting this site over from an SPA to a multi-page application in the coming weeks. Stay
tuned for more blog posts where I'll go over the implementation details and walk you through just how I went about
doing this.
