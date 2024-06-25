---
slug: 2024-06-13-Hosting-Your-Personal-Site-On-AWS-S3
title: Hosting Your Personal Site On AWS S3
description: Now that we know we want to host our personal site on AWS S3, we need to set up the bucket and the website. We'll also need to set up the bucket policy to allow the website to be publicly accessible. And a couple other things to make sure the website is secure. Let's dive in!
published_at: 2024-06-13
keywords: personal site, hosting, blog, jamesebentier.com, jamesebentier.com/blog, automation, developer life cycle, web hosting
image: /logo.png
tags:
- personal-website
- aws-s3
- aws-cloudfront
- terraform
---

Alright, so in the [previous post](https://jamesebentier.com/blog/2024-06-06-hosting-a-personal-site-on-the-cheap) we were figuring out what the cheapest way to host a personal site is. In this blog post, we'll talk about how to actually host your website on AWS S3 after you've built it.

## First Things First
Before we can start talking about the setup and configuration of everything, we need to talk about the technologies we're actually going to be using from the AWS suite and beyond. The list that I'll be going over today is:

1. Domain Name Registry
2. AWS Route53
3. AWS S3
4. AWS Cloudfront

By using the combination of these services with some slight configuration we will be able to purchase our domain, host our static site on AWS S3, and connect the two with smart caching so that it's fast and full SSL certificate support so that there are no pesky "You are navigating to an insecure site," messages shown to your viewers.

### Domain Name Registry
You can choose any that you like, I use godaddy.com because they've always made things quick and easy for me and I'm a glutton for ease and familiarity.  I've been using them since my first side project domain purchase back in 2012.

### AWS Route53
Just having a domain name that you've purchased isn't enough in order to host your site. You have to be able to control where your domain name will actually route to.  This is where Route53 comes in, allowing you to set the destination for anyone attempting to view your domain.

### AWS S3
This we talked about a little in the last post. AWS S3 is a static file store. You can store and retrieve any files you wish in what's called an S3 bucket. By default everything in your bucket is protected and only someone authenticate and authorised under your AWS account can access the files.

### AWS Cloudfront
This is where a lot of the magic happens.  AWS Cloudfront is a Content Delivery Network (or CDN) that allows you to easily connect routed traffic to an S3 bucket for caching and serving your user.  The first reason to use this is that you don't want to necessarily open up access to your entire S3 bucket and allow anyone to access all the files directly (that could be risky). Second you don't necessarily want to be paying the network transfer cost of S3 every time someone loads your page (that could be costly).  So Cloudfront lets you control the caching and access to your site with some simple and easy configuration.

## Let's Get To It
Alright, the moment you've all been waiting for, it's time to hop into the UIs and get everything up and running. You have a static page that you want to host, you have your domain name purchased (sorry but I'm not actually going to walk through how to purchase a domain), and it's time to dive into the AWS side of things.

And since we're all coders here, let's use [Terraform](https://www.terraform.io/) to help us out with all of this. So in order to get started we're going to need to install the necessary tools (`terraform` and the `aws` cli):

**MacOS**
```
brew install terraform
brew install awscli
```

**Windows**
```
choco install terraform
choco install awscli
```

**Linux**
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" unzip awscliv2.zip sudo ./aws/install
```

Once this is set up you'll need to authenticate yourself with the AWS cli. There are plenty of tutorials already out there on how to set this up, like the [AWS CLI documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html), so I'm going to trust that you can figure this one out.

And finally we'll make a directory that is going to hold all the new `terraform` resources that we're going to be creating and a single file that will hold all the configuration for hosting our site. I'm calling my resource file `jamesebentier-com.tf`, but you should name yours however you like while making sure the appropriate file extension `.tf` is still present.

```
mkdir -p terraform
touch terraform/jamesebenter.tf
```

And now we're ready to make our first terraform resource.

### Setting up your S3 bucket
First things first, we need an S3 bucket that will be used to host the static site files. We're going to do this by using the `aws` module built into `terraform`.  Go ahead and open up the new file we created.

In this file we're going to add our AWS provider, and the definition for the new S3 bucket. This looks like the following:

```
provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_s3_bucket" "jamesebentier_com" {
  bucket = "jamesebentier-com"
  acl = "private"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

data "aws_iam_policy_document" "jamesebentier_com_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.jamesebentier_com.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.jamesebentier_com.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "jamesebentier_com" {
  bucket = aws_s3_bucket.jamesebentier_com.id
  policy = data.aws_iam_policy_document.jamesebentier_com_s3_policy.json
}
```

Now you are ready to save and apply this to your AWS account. So let's go ahead and do that using `terraform apply`.

#### Breakdown
In this section we've gone ahead and created four new resources (or configurations) in AWS.
1. A `provider` which is telling Terraform where we will be connecting (this is pointing at our AWS CLI configuration we just created)
2. An `aws_s3_bucket` which is going to be holding the source code for our personal site
3. An `aws_iam_policy_document` which is setting up the access rights for the S3 bucket we're creating
4. An `aws_s3_bucket_policy` which is tying together the bucket and the policy document we just created

The most important part here is that we're setting up the `aws_s3_bucket` with:
- It's `acl` set to `private` which means no one outside of our AWS account can access it
- It's `website` configuration enabled with the `index_document` and `error_document` pointing to the `index.html` page. This ensures that for a Single Page App, any deep links (links to pages that aren't your main URL) will appropriate route into the site

### Setting up your Route53 and your SSL Certificate
Create the SSL certificate
```
resource "aws_acm_certificate" "jamesebentier_com" {
  provider = aws.us_east_1
  domain_name = "jamesebentier.com"
  subject_alternative_names = ["*.jamesebentier.com"]
  validation_method = "DNS"
}
```

Create the Route53 hosted zone
```
resource "aws_route53_zone" "jamesebentier_com" {
  name = "jamesebentier.com"
  comment = "Hosted zone for JamesEbentier COM domain"
}
```

Verify the SSL Certificate
```
resource "aws_route53_record" "jamesebentier_com_cert_verification" {
  for_each = {
    for dvo in aws_acm_certificate.jamesebentier_com.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = aws_route53_zone.jamesebentier_com.zone_id
}

resource "aws_acm_certificate_validation" "jamesebentier_com" {
  provider = aws.us_east_1
  certificate_arn = aws_acm_certificate.jamesbentier_comm.arn
  validation_record_fqdns = [for record in aws_route53_record.jamesebentier_comcert_verification : record.fqdn]
}
```

Once again, it's time to update the state of our AWS configuration and we'll do that by running `terraform apply`.

#### Breakdown
Once again we adding four new resource definitions into our configuration so that we can setup Route53 to know about the domain we purchased, and set up an SSL certificate for serving our website over HTTPS. The main things to note here are:
1. We're creating the `aws_acm_certificate` with the `domain_name` that we purchased, a `subject_alternative_name` that makes sure the `www.` version of our site works with HTTPS, and using `DNS` to validate the ownership of that domain name
2. We're creating the `aws_route53_record` required to verify the ownership of our domain
3. We're kicking off the actual validation process by creating the `aws_acm_certificate_validate` resource

### Change over your Namespace Server configuration
Unfortunately this is the one part of the process that does require logging into the UI of both AWS and your domain name registry.  What you need to do is update the DSN registration to point to your NS records in your newly created hosted zone.

[Ryan Canty already has a great post on how to do this](https://jryancanty.medium.com/domain-by-godaddy-dns-by-route53-fc7acf2f5580), so just follow his lead and you're all set!

**Note: This needs to be completed in order for the DNS verification of your SSL certificate to complete.**

### Setup Cloudfront distribution
```
resource "aws_cloudfront_distribution" "jamesebentier_com" {
  origin {
    domain_name = aws_s3_bucket.jamesebentier_com.bucket_regional_domain_name
    origin_id = "custom-jamesebentier.com"

	s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.jamesebentier_com.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = true
  comment = "JamesEbentier.com main distribution"
  aliases = ["jamesebentier.com", "www.jamesebentier.com"]
  retain_on_delete = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods = ["GET", "HEAD"]
    default_ttl = 3600
	min_ttl = 0
	max_ttl = 86400
	target_origin_id = "custom-jamesebentier.com"
	viewer_protocol_policy = "redirect-to-https"

	forwarded_values {
	  query_string = true

	  cookies {
	    forward = "all"
	  }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = aws_acm_certificate.jamesebentier_com.arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method = "sni-only"
  }
}
```

Alright, once again we'll go ahead and apply these changes with `terraform apply`.

#### Breakdown
This is the largest part of the whole setup. Connecting the Cloudfront CDN to our S3 bucket and the SSL Certificate we just provisioned. In this one resource we're setting up:
1. The `origin` which is the S3 bucket we created for holding out source code
2. Any domains that will be used to serve the content of our site
3. The `viewer_certificate` to use, which is the one we created and verified in the previous steps

### Route your domain to the Cloudfront distribution
```
resource "aws_route53_record" "jamesebentier_com" {
  zone_id = aws_route53_zone.jamesebentier_com.zone_id
  name = ""
  type = "A"

  alias {
    name = aws_cloudfront_distribution.jamesebentier_com.domain_name
    zone_id = aws_cloudfront_distribution.jamesebentier_com.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_jamesebentier_com" {
  zone_id = aws_route53_zone.jamesebentier_com.zone_id
  name = "www"
  type = "A"

  alias {
    name = aws_cloudfront_distribution.jamesebentier_com.domain_name
    zone_id = aws_cloudfront_distribution.jamesebentier_com.hosted_zone_id
    evaluate_target_health = true
  }
}
```

And finally, one last time lets apply these changes so that they're reflected in our AWS configuration with `terraform apply`.

#### Breakdown
In this final step we're creating the Route53 routes for our domain to point to our Cloudfront distribution we just created.  These two resources will make sure that both `jamesebentier.com` and `www.jamesebentier.com` route to the same content.

### Done!

**There you have it!** Your site is now hosted on AWS in the cheapest possible way AND you have some nifty new Terraform code to go with your site that shows off a little more of your development life cycle know-how! All you need to do is upload your site your new S3 bucket and watch the magic happen.

---

*Coming up next week*, we'll be going over how to automate your builds on Github so that with just a simple push to your mainline branch, you can have updates to your site in seconds.
