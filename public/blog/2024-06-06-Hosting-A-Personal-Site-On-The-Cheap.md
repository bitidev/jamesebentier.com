---
slug: 2024-06-06-hosting-a-personal-site-on-the-cheap
title: Hosting a Personal Site on the Cheap
description: Most software engineers want to host their own personal website. A site that has their resume, social handles, something that distinguishes them from others, and possibly even a blog.  Personal websites have become quite the norm for developers these days, but where is the best place to start? This blog post series will be walking through the creation and hosting of my very own personal site (jamesebentier.com) from ideation, to management.
published_at: 2024-06-06
keywords: personal site, hosting, blog, jamesebentier.com, jamesebentier.com/blog, automation, developer life cycle, web hosting
image: /logo.png
tags:
- automation
- developer-life-cycle
- web-hosting
---

Most software engineers want to host their own personal website. A site that has their resume, social handles, something that distinguishes them from others, and possibly even a blog.  Personal websites have become quite the norm for developers these days, but where is the best place to start? This blog post series will be walking through the creation and hosting of my very own personal site ([jamesebentier.com](https://jamesebentier.com)) from ideation, to management.

## Pre-requisites
So first things first when looking to host your own personal site. You need to know a couple of things at a basic level before being able to manage and maintain a personal site yourself.

1. You need to have an understanding of how to build a webpage using HTML and CSS
2. A basic understanding of source control and automation using GitHub

With these two already under your belt, we'll move forward breaking down what the options are for hosting a personal site, their estimated costs, and eventually the implementation of my personal site as a tutorial.

## The Options
There are a lot of hosting solutions out there when it comes to building a site ranging from 100% self-hosting to using a site builder like [Webflow](https://webflow.com). What we're looking for here is a solution that will check the following boxes:

1. The site must be tied to a custom domain
2. Be easy to maintain
3. Be secure
4. Keep costs as low as possible while not sacrificing convenience
5. The configuration and setup should show off your skillset as a developer

So with this in mind let's look at three of the different options

### Webflow
If you haven't heard of Webflow yet, you probably will in the near future as it is one of the top no-code site builders out there right now. So let's get into the pros and cons of using something like Webflow.

#### Pros
* Webflow manages everything for you
* Ability to easily expand to include a blog or even an e-commerce store if you like
* Strong online community for support

#### Cons
* Site building is restricted to just HTML/CSS and plain Javascript, no ability for more advanced libraries like React for the creation of single-page applications
* Hosting using a subdomain is free but attaching a domain will cost you
* Doesn't show off much of a developers skillset

**Cost:** ~ $15/month

### Hosted WordPress
Wordpress is the oldest and most extensively used website and personal blog framework. It's written in PHP, has strong community support, lots of extensions, and many different sites that will host and secure Wordpress installations for you.

#### Pros
* Easy hosting and simple to use plugins/extensions to make management easier
* User friendly for all skill levels
* Built-in blog support

#### Cons
* Wordpress has a lot of features, and you will likely end up paying for a lot that you won't need
* Restrictions on web development technologies (No support for frontend frameworks like React or Vue.js)
* Constant issues with security keep coming up around Wordpress that could leave your personal site exposed

**Cost:** ~$10/month

### AWS S3
Amazon Web Services (AWS) has an object store product called S3 that is most commonly used as static file storage. What many don't know is that with that, also comes the ability to host a website using S3 alone.  All you need to do is build or compile your HTML/CSS and Javascript source files, and upload them to your personal S3 storage. Then using the built-in support for static web hosting, your site is hosted and away.

#### Pros
* AWS Free Tier allows usage of S3 for personal sites for free
* All management of personal site resources can be done using automation and Terraform
* Usage of this shows off not just web development skills but a full understanding of the development life cycle, and automation technologies

#### Cons
* More up-front effort to set up
* No support for dynamic user content

**Cost:** ~$1/month

## Conclusion
Because we're looking for the cheapest solution, and, even if we want to host a blog, there is no need to have dynamic user content through the form of comments on the posts, I went ahead and chose to go with hosting on AWS S3. In order to keep this solution management I used the combination of the following technologies:

* AWS S3 for content hosting
* Terraform for AWS resource management/automation
* Github.com for source code management and deployment automation
* Webpacker/React for Single Page Application development

Stay tuned for more blog posts where I'll go over the implementation details and walk you through just how this was achieved.
