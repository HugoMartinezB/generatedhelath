

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_security_group" "this" {
  name        = "${var.id}-ssh"
  description = "${var.id} SSH access."
  vpc_id      = var.vpc_id
  tags        = var.tags
}


resource "aws_security_group_rule" "this" {
  for_each          = var.whitelisted_ips
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = [each.value]
  description       = "SSH access for ${each.key}."
}


module "ec2" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  name                        = var.id
  ami                         = data.aws_ami.this.image_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = var.public_subnet_ids[0]
  create_iam_instance_profile = true
  iam_role_name               = "${var.id}-ssm-bastion"
  associate_public_ip_address = true
  ignore_ami_changes          = true
  metadata_options = {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "ssm" {
  role       = module.ec2.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "this" {
  role       = module.ec2.iam_role_name
  policy_arn = aws_iam_policy.this.arn
}



resource "aws_iam_policy" "this" {
  name        = "${var.id}-ssm-bastion"
  description = "Access policy for ${var.id}-ssm-bastion to access the data bucket."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.s3_bucket_name}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
  tags = var.tags
}


