variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

// EC2 인스턴스에 사용할 AMI ID 변수
variable "ami_id" {
  description = "The ID of the AMI to use for the instances"
  type        = string
  default     = "ami-0fd0765afb77bcca7" // 기본 AMI ID 설정
}

// EC2 인스턴스 타입 변수
variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t2.micro" // 기본 인스턴스 타입 설정
}

// RDS 인스턴스의 사용자 이름 변수
variable "db_username" {
  description = "The username for the RDS instance"
  type        = string
  default     = "admin" // 기본 사용자 이름 설정
}

// RDS 인스턴스의 비밀번호 변수
variable "db_password" {
  description = "The password for the RDS instance"
  type        = string
  default     = "password" // 기본 비밀번호 설정
}