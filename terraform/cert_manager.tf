resource "aws_acm_certificate" "jamesebentier-com" {
  domain_name               = "jamesebentier.com"
  subject_alternative_names = ["*.jamesebentier.com"]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "jamesebentier-com" {
  certificate_arn         = aws_acm_certificate.jamesebentier-com.arn
  validation_record_fqdns = [for record in aws_route53_record.jamesebentier-com_cert_verification : record.fqdn]
}
