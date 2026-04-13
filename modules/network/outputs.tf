output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_db_subnet_ids" {
  value = values(aws_subnet.private_db)[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}

output "app_target_group_arn" {
  value = aws_lb_target_group.app.arn
}
