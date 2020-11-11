data "aws_subnet" "efs" {
  id = var.subnet_id
}

data "aws_region" "current" {}

resource "aws_efs_file_system" "this" {
  creation_token = var.name
}

resource "aws_security_group" "efs" {
  name        = format("efs-%s", var.name)
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "efs-self" {
  description              = "Allow EFS to communicate with itself"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.efs.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "efs-nodes" {
  description              = "Allow nodes to communicate with EFS"
  from_port                = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = var.source_security_group_id
  to_port                  = 2049
  type                     = "ingress"
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = data.aws_subnet.efs.id
  security_groups = [aws_security_group.efs.id]
}
