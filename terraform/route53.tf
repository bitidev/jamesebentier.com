resource "aws_route53_zone" "jamesebentier-com" {
  name    = "jamesebentier.com"
  comment = "Hosted zone for the jamesebentier.com domain"
}

resource "aws_route53_record" "jamesebentier-com_cert_verification" {
  for_each = {
    for dvo in aws_acm_certificate.jamesebentier-com.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.jamesebentier-com.zone_id
}
