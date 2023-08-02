resource "aws_iam_user" "this" {
  for_each = var.bastion_users
  name     = each.value.email
  tags     = var.tags
}

// Attaches SSM policy needed for the instance to be able to use SSM.
resource "aws_iam_user_policy_attachment" "bastion" {
  for_each   = var.bastion_users
  user       = aws_iam_user.this[each.key].name
  policy_arn = aws_iam_policy.this.arn
}


// The policy for all the bastion users, it allow to access only the  bastion instance on eu-west-2.
resource "aws_iam_policy" "this" {
  name        = "${var.id}-bastion-users"
  path        = "/"
  description = "${var.id}-bastion-users"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:StartSession",
          "ssm:TerminateSession",
        ],
        "Resource" : [
          "arn:aws:ssm:::document/SSM-SessionManagerRunShell",
          "arn:aws:ec2:*:*:instance/${var.bastion_host_id}",
        ]
      }
    ]
  })
  tags = var.tags
}


resource "aws_sns_topic_subscription" "this" {
  for_each  = var.bastion_users
  topic_arn = var.topic_arn
  protocol  = "email"
  endpoint  = each.value.email
}