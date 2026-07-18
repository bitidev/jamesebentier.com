resource "aws_route53_zone" "jamesebentier-com" {
  name    = "jamesebentier.com"
  comment = "Hosted zone for the jamesebentier.com domain"
}

resource "aws_route53_record" "jamesebentier-com" {
  name    = ""
  type    = "A"
  ttl     = "300"
  records = ["97.107.129.135"]
  zone_id = aws_route53_zone.jamesebentier-com.zone_id
}
