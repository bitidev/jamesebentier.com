---
slug: 2024-07-11-how-automated-scans-saved-me-from-disaster
title: How Automated Scans Saved Me From Disaster
description: Learn how automated scans saved me from an SEO disaster after converting my site to a new platform. I'll walk you through the process of how I found the issues, what they were, and how I resolved them.
published_at: 2024-07-11
image: /blog/images/how-automated-scans-saved-me-from-disaster-email.webp
keywords: ruby on rails, web development, full stack application, project planning, deployment, terraform
tags:
- web-development
- ruby-on-rails
- automation
- deployment
---

So one of the tools I use on a regular basis for all my projects, is [Ahrefs](https://ahrefs.com). Ahrefs is a tool that
helps me understand how my site is performing in terms of SEO, backlinks, and other metrics. It's a great tool to have
in your arsenal when you're trying to improve your site's performance. As their H1 states, they are "everything you
need to rank higher & get more traffic."

Great product, especially powerful with just the free version, and one of the ways it does all this is by running
periodic scans of your domain content to understand how it's performing and giving a health score, which obviously
you want to be as close to 100 as possible. Little did I know, these periodic scans were about to save me from an SEO disaster.

## The Email

It was the morning after my site had been converted to a new platform. I was out on my morning walk, enjoying the
sunshine and successful weekend, when I received an email from Ahrefs. The subject line read "(Jamesebentier) Multiple title tags [New]: 8 URLs"
and I was immediately curious, because with the conversion, all stats should be identical. I opened the email and saw
the following:

![Ahrefs Email](/blog/images/how-automated-scans-saved-me-from-disaster-email.webp)

A quick glance at the email, and I immediately knew I messed something up. The email was telling me that my health
score plummeted 26 points, incurred 9 new errors, 7 warnings, and 7 notices.

Not good.

## What does this mean?

Long story shot, I messed up the conversion of the meta tags for the site. I was duplicating title tags, making it
difficult for search engines to understand what the content was about, I had broken blog links due to a slightly new
linking structure, and because of the broken links I was returning more 404 errors that I should have been.

## Did I panic?

Of course not, this was a great success. I had just converted the site, and I was able to catch these issues before
they became a major problem, all because of hidden value in the Ahrefs automation.

What I did do though, is finish my morning walk, collect my thoughts about what might be the culprit
(options were limited so that was calming), and when I got back home I sat down and got to wwork.

## So now we iterate and resolve the issues

First things first, the issue with the title tags. I had forgotten in my implementation and usage of the `meta-tags`
gem, that it adds it's own `<title>` tag to the page. Which means if I left the default title tag in the layout file,
I would have two title tags on the page. This was an easy fix, I just had to remove the default title tag from the
layout.

Resolved that one in a manner of seconds.

Second was the broken links. This was also straight forward due to knowing I had some hardcoded links in the blog
content that was moved to the new framework. This means I just need to make sure the links were updated to the new
structure.

This one took minutes, instead of seconds, but I was able to get a commit made with both fixes in under 30 minutes of
sitting down to work.

Now I just have to push the code changes, let automation run to deploy the new code, and trigger a new site scan on
Ahrefs to verify the results. And what do you know, the health score was back to the high 90's, and all the errors and warnings
were gone. Just like magic!

![Ahrefs Dashboard](/blog/images/how-automated-scans-saved-me-from-disaster-email-fixed.webp)

## My main takeaways

1. **Automation will always save us from making mistakes if set up properly** - I can't stress this enough. If you
   have the ability to automate something, do it. It will save you time, money, and headaches in the long run.
2. **Mistakes will happen, don't panic, just iterate** - Mistakes are a part of life, and they will happen. The key is
   to not panic, but to iterate and resolve the issue as quickly as possible. The longer you wait, the worse it will get.
3. **The conversion as a whole was still a success, content served, improvements made, and automation proved useful** -
    Even with the mistakes, the conversion was still a success. The content was served, improvements were made, and the
    automation proved useful in catching the mistakes before they became a major problem.

I hope you've enjoyed this little story of how automated scans saved me from disaster. If you have any similar stories,
I'd love to hear them! Feel free to share with me on Twitter [@jebentier](https://twitter.com/jebentier).

Until next time, happy coding!
