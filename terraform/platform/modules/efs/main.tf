resource "aws_efs_file_system" "this" {
  creation_token = "${var.name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.name}-efs"
  }
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "NFS access from the cluster nodes"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "nfs_from_nodes" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  description                  = "NFS from the EKS nodes"
}

resource "aws_efs_mount_target" "this" {
  count = var.subnet_count

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}
