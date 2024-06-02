// aws 프로바이더 연결
provider "aws" {
  region = "ap-northeast-2" // 서울
}

// s3 버킷 생성
resource "aws_s3_bucket" "min-terraform-mybucket" {
  bucket = "min-terraform-mybucket" // 리소스 네이밍

  tags = {
    environment = "devel"
  }
}

// 버킷 제한 풀어주기
resource "aws_s3_bucket_public_access_block" "public-access" {
    bucket = aws_s3_bucket.min-terraform-mybucket.id

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

// 오브젝트 만들어서 버킷에 할당하기
resource "aws_s3_object" "terraform-sample-txt" {
    bucket = aws_s3_bucket.min-terraform-mybucket.id
    key = "sample.txt"
    source = "sample.txt"
  
}

// Policy 적용
resource "aws_s3_bucket_policy" "bucket-policy" {
    bucket = aws_s3_bucket.min-terraform-mybucket.id
    depends_on = [ 
        aws_s3_bucket_public_access_block.public-access
    ]

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": ["s3:GetObject"],
        "Resource": ["arn:aws:s3:::${aws_s3_bucket.min-terraform-mybucket.id}/*"]
    }]
}
POLICY
  
}

// RDS 접근 권한을 정의하는 정책 생성
resource "aws_iam_policy" "rds_access_policy" {
  name        = "RDSAccessPolicy"
  description = "Policy to allow RDS subnet group creation and management"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:CreateDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:ModifyDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

// 사용자에게 위에서 생성한 정책을 연결
resource "aws_iam_user_policy_attachment" "attach_rds_access_policy" {
  user       = "minyeong"
  policy_arn = aws_iam_policy.rds_access_policy.arn
}


