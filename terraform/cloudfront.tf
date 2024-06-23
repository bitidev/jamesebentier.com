resource "aws_cloudfront_distribution" "web" {
  origin {
    domain_name = "jamesebentier-site-85eab09d3f4f.herokuapp.com"
    origin_id   = "jamesebentier-site-85eab09d3f4f.herokuapp.com"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  enabled          = true
  is_ipv6_enabled  = true
  comment          = "JamesEbentier.com heroku distribution"
  aliases          = ["jamesebentier.com"]
  retain_on_delete = true

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods = ["GET", "HEAD"]

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    target_origin_id = "jamesebentier-site-85eab09d3f4f.herokuapp.com"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      headers = [
        "Accept-Language",
        "Authorization",
        "Origin",
        "X-CSRF-TOKEN"
      ]

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
    acm_certificate_arn            = aws_acm_certificate.jamesebentier-com.arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "jameseebenter-com" {
  zone_id = aws_route53_zone.jamesebentier-com.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = true
  }
}
