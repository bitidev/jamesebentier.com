--
slug: 2024-06-28-how-to-decide-what-is-necessary
title: How to Decide What is Necessary
description: One of the hardest parts of a project, is deciding what not to do. Learn with me as I navigate this process while converting my site from a Single Page Application to a full stack application.
published_at: 2024-06-28
image: /how-to-decide-what-is-necessary.webp
tags:
- web-hosting
- decision-making
- planning
---

Recently I made the decision that I needed to convert my site from a Single Page Application (SPA) to a Full Stack Application (FSA)
due to some [limitations I was running into around SEO and Social sharing](/blog/2024-06-19-the-downsides-of-single-page-apps). It
was a tough decision to make, but ultimately if I wanted to hit the numbers I wanted, I needed to make a change. So once that decision
was made, the next began to loom over me: what do I need to do to make this happen?

After nearly a decade of working in the tech industry, something that's engrained in me is the Agile methodology, and
one of the most important books I've ever read on the process of planning and executing quickly and effectively is
[Shape Up](https://basecamp.com/shapeup) by Ryan Singer from Basecamp. In it, Ryan talks about the process of taking an
idea and breaking it down into smaller pieces, and then deciding what is necessary to make the project successful. As he
puts it, and I love this phrasing, how to make the right bets.

So as I began to think about what I needed to do to convert my site, I started to think about what I already had in the form
of the SPA, what I needed to improve with it, and what I also wanted to be able to do in the future with this site. Taking
a look forward was important to make sure I wasn't shortchanging myself in the future, like I already had done with the
previous decision to make a Single Page Application.

## Ideation Process

Whenever I'm starting to take a look through a project, it starts with brainstorming, because the earliest input received
is always the most vague, but also the most valuable. Sometimes is the directive to introduce a new product or feature,
in this case it was to convert my site to a more flexible and SEO friendly framework. So I started to think about what I
needed from my personal site, what it's purpose was, what I expected from it, and what features/functionality it needed
in order to achieve this.

This process can go on for a long time, so I typically time box it to 30 minutes to an hour, but in that time, no idea
is rejected. This is something that I'll always take away from my time working with Kevin O'Connor at FindTheBest,
where he would enforce the "No bad ideas in brainstorming" rule to ensure all ideas where on the table before any decisions
were made.

So I got to writing in my notebook all the things I wanted to fix, be able to do, and you'll noticed in my scribblings,
there are no details. This is a list of ideas, not a list of requirements, or implementation details. Implementation planning
comes later, but for now, I just need to know what I want to do.

![Ideation Process](/blog/images/site-conversion-ideation-notes.webp)

So with these notes, I've successfully transitioned from the abstract directive to "convert my site to a Full Stack Application"
to a list of bugs and features that I want to address. Now it's time to start making some decisions.

## What Stack Am I Going To Use?

The first decision I needed to make was what stack I was going to use, and now that I had spent some time taking the abstract
directive to a concrete list of features, I had a better idea of where I wanted to go, and could better evaluate the options.

**Let's use something I'm familiar with**

The first concept is simple when picking a stack. We move faster when we're familiar with the tools we're using, so I wanted
to use something that I was already familiar with. For me, that immediately brought the list of frameworks down to two:

1) Ruby on Rails
2) Next.js

And even then, Next.js was not as tried and true for me, as Rails was, so I was able to quickly make the decision to use Ruby on Rails.

**Do I need a database?**

The original design of the site was static, so there was no database required, and there is a simplicity that comes with that.
A rather nice simplicity, because databases can be a pain to manage, but what they mainly mean is additional costs. So I took
a look at where I wanted to go with my site, what functionality and features I wanted to provide, and I realized that I would
need a database in order to achieve the goals I had set for myself around a "Learn with Me" feed where I can post all the
books, blogs, videos, and other resources that I've been consuming.

So, a yes to the database.

**How can we keep deployment simple?**

Now this is important, because the more automation and streamlined the deployment process, the less headaches around
maintenance and the more time I can spend on building features and content. So that ruled out self hosting using Linode
or AWS EC2 only, not to mention databases on those two systems are rather expensive.

So again, I decided to go with my tried and true, Heroku dyno with a free Postgres database through SchemaToGo, and a
Cloudfront distribution sitting in front for caching and rate limiting. Part of this is the original decision used with the
Single Page Application too, so I was able to leverage some of the existing infrastructure if I wanted.

**Final Stack List**

* Ruby on Rails
* TailwindCSS
* Postgres Database
* Heroku Dyno
* Cloudfront Distribution
* AWS Route53 for DNS

So now I know the what and the how, and I can start to prioritize the work.

## What Are The Top Priorities?

Now that I new the stack that I was going to use, and because it was something I was already familiar with, I could start
prioritizing the combination of tasks. I started this by grouping the tasks into three distinct categories:

1) **Feature Parity**: The list of items that were necessary to have a 1 to 1 replica of my personal site running on the new stack.
2) **Bug Fixes**: The list of items that were necessary to fix in order to have a stable and reliable site as well as any
deficiencies in the current site that forced the conversion to be necessary
3) **Enhancements**: The list of items that were nice to have, but not necessary to consider the conversion a success.

While doing this categorization, take a moment to see if any of the larger items can be broken down into smaller, deliverable
chunks of work. This allows us to better prioritize, and ultimately trim the scope of the project to something that is manageable
or even more importantly, something that can be done in a weekend. So you'll see that in the spreadsheet below, I don't just have
7 line items, I have 14, almost double the list from the brainstorm. This brings more clarity to the task as hand.

![Prioritization Spreadsheet](/blog/images/site-conversion-prioritized-spreadsheet.webp)

Now that I know what my priorities are, I can start to build, but first, there's one more thing to do, and that's to
trim the fat from the list. That is, to decide what is necessary, what is a stretch goal, and what is a push goal.

## What Does Done Look Like?

Now, you can probably already see that with these three categories, there is an intuitive order, but with prioritization, there also
comes the decision of the definition of done. That is, where do we draw the line in the prioritization list to consider the
current initiative complete, so that my focus can be placed somewhere else.

One of the corner stones of the Agile methodology is the concept of a Sprint, a time-boxed period of work where the team focuses
on a set of priorities, and at the end of the sprint, the team has a deliverable. This is a concept that I've found to be incredibly
useful to force the conversation of what is necessary, what is a stretch goal, and what is a push goal.

For this conversion, I wanted to complete the whole process within a weekend, so I set my sprint time-box to be 2 days and took
another look at the spreadsheet to see what I could realistically accomplish in that time frame. What I came away with was
the following:

![Definition of Done Spreadsheet](/blog/images/conversion-definition-of-done-spreadsheet.webp)

Green were the items that were 100% necessary to consider the conversion a success, yellow were the items that were nice to have,
and orange were the push goals to work on in future iterations of the site. And with that, I now have an ordered and prioritized
list of work to do, and I know when I've reached success. The only thing left to do is to build and iterate.

## Build and Iterate

So with the stack chosen, the priorities set, and the definition of done in place, I can start building. But as I build, I'll
be constantly iterating on the priorities, because as I build, I'll learn more about the stack, the limitations, and the
possibilities, and I'll need to adjust my priorities and possibly even the definition of done accordingly.

It doesn't matter how detailed your planning, how experienced you are, or how familiar you are with the stack, there will always
be surprises, and it's important to be able to adjust to them, to be agile. One example of such a surprise hit me right as I was
launching the new site, and I'll be discussing that in a future article, so make sure to check back for that.

## Conclusion

So that's the process I use when I'm trying to decide what is necessary for a project, and it's a process that I've found
to be incredibly effective in my career. It's a process that I've used to build multiple products, features, and even blog series,
and it's a process that I'll continue to use. I hope you found this helpful, and if you have any questions, feel free to reach out,
and make sure to check back for the next entry in this installment where I'll be discussing the Ruby on Rails starter template
I used to get this project off the ground quickly and effectively.
