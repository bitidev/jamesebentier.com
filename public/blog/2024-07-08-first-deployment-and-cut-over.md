---
slug: 2024-07-08-first-deployment-and-cut-over
title: The First Deployment and Cut-Over
description: The process and challenges of deploying a Ruby on Rails application to Heroku and transitioning a domain with zero downtime, using Terraform for infrastructure automation.
published_at: 2024-07-08
image: /blog/images/first-deployment-and-cut-over.webp
keywords: ruby on rails, web development, full stack application, project planning, deployment, terraform
tags:
- web-development
- ruby-on-rails
- terraform
- deployment
---

So, we've successfully gotten the application fully converted over from the SPA to the Rails application, but
just doing that isn't enough. We've now got to deploy the application and cut over the domain to the new
source. Before doing anything, we first need to understand what the goal of the deployment is, then identify
what is necessary in order to achieve that goal, and finally executing and making sure to be vigilant along the
way to ensure the full goal is realized.

## What was the goal?

Well, this is actually pretty easy to understand given the premise of the project. The goal is to make sure
that the new application stack is fully deployed and accessible to the public, and that we incur as little
downtime as possible to ensure that the user experience, and SEO rankings, are not negatively impacted.

So if I were to numerate the goals in priority order, it would look something like this:

1. Ensure that the new application is fully deployed and accessible to the public
2. Ensure that the domain is cut over to the new application with as little downtime as possible
3. Celebrate the victory of a successful deployment

## What is necessary to achieve a Zero Downtime cut over?

Deploying to a new environment is one thing, but cutting over a domain from one endpoint to another is a completely
different story. Throw on top that we don't want any downtime, and now we've got a real challenge on our hands. This
means that we want to utilize as much automation as possible to ensure that the cut over follows a predictable path.

So how on earth do we even start to understand the stack necessary for routing a domain to a Rails application? Well,
when we discussed the stack to use, we said we would be using Heroku to host/run the Rails application, along with
AWS Route 53 and Cloudfront for the DNS and CDN respectively.

![High-Level VPC Networking Diagram](/blog/images/vpc-network-diagram.webp)

With this diagram, we can see that the first thing we need to accomplish for the cut over is to ensure that the
application is fully deployed to Heroku. Once that is done, and we can confirm that we're able to access the application
at the temporary Heroku app URL (e.g. `https://my-app.herokuapp.com`), we can then move on to the next step, which is
the cut over of the domain.

## Automating a Heroku Deployment

I am not someone who likes to do things manually if I can avoid it, mostly because there is always a chance that I
will need to repeat a task, or remember what I did in another project. So I already have many cookie-cutter examples
of how to configure a Rails deployment to Heroku. But for this project, I wasted to ensure I had as little cost as possible,
and I don't need a full blown database, so I opted to use the free teri of SchemaToGo instead of the paid tier of Heroku Postgres.

All of this setup can be done using [Terraform](https://www.terraform.io/), which is a tool that allows you to define
your infrastructure as code.

![Terraform Configuration of Heroku Deployment](/blog/images/heroku-terraform-configuration.webp)

This Terraform configuration will create a new Heroku application, set the buildpacks, and configure the environment.
The only thing it doesn't do, and which still need to be done manually, is to set the Github integration so that
the application will automatically deploy when changes are pushed to the `main` branch.

You can read more on how to do this in the Heroku documentation [here](https://devcenter.heroku.com/articles/github-integration).

## Cutting over the Domain

Now that we have the application deployed to Heroku, and we can confirm that it is accessible at the Heroku app URL,
we can now move on to the next step, which is cutting over the domain. This is where things get a bit more complicated,
as we need to ensure that the cut over is done with as little downtime as possible.

What makes this extra complicated is something that I didn't realize until I was in the middle of the cut over, and
that is that Cloudfront distributions take time to tear down, _AND_ they have a global restriction on duplicate domains.
This means that I have to tear down the old Cloudfront distribution _before_ I can create the new one, and that the
tear down process can take up to 40 minutes to complete.

![My Reaction to the Cloudfront Tear Down](https://media1.tenor.com/m/ZFc20z8DItkAAAAC/facepalm-really.gif)

OOPS! We'll I guess I learned something new today.

This can all still be automated using Terraform, but it requires a bit more finesse than creating the new Heroku
application did. The Terraform configuration for the Cloudfront distribution can be found in [the repository for this
project](https://github.com/bitidev/jamesebentier.com/blob/main/terraform/cloudfront.tf) if you're interested.

So to summarize, the steps to cut over the domain are as follows:

1. Tear down the old Cloudfront distribution
2. Create the new Cloudfront distribution
3. Update the Route 53 record to point to the new Cloudfront distribution

Once these steps are completed, the domain should be fully cut over to the new application, and the user experience

## Conclusion

So that's it! The first deployment and cut over of the domain are complete. The application is now fully deployed
and accessible to the public, and the domain is now pointing to the new application. The only thing left to do is
to celebrate the victory of a successful deployment.

And what better way to celebrate than to write a blog post about it, and go over what I learned. I hope you enjoyed
this post, and I hope you learned something new. If you have any questions, or if you would like to discuss anything
further, please feel free to reach out to me on [Twitter](https://twitter.com/jebentier).

Until next time, happy coding!
