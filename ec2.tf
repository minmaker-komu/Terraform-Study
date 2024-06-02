resource "aws_instance" "example" {
  ami                    = "ami-0fd0765afb77bcca7"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.new_public_subnet_2a.id}"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name  = "terraform"
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl enable --now httpd
              echo "Hello, Terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {

  name = var.security_group_name
  vpc_id = "${aws_vpc.new_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/32"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "terraform-sg"
  }
}



output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}

output "public_dns" {
  value       = aws_instance.example.public_dns
  description = "The Public dns of the Instance"
}

output "private_ip" {
  value       = aws_instance.example.private_ip
  description = "The Private_ip of the Instance"
}


// Bastion 호스트 보안 그룹 생성
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.new_vpc.id // VPC ID 참조

  ingress {
    from_port   = 22 // SSH 포트
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // 모든 IP 주소에서의 접근 허용
  }

  egress {
    from_port   = 0 // 모든 아웃바운드 트래픽 허용
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// 프라이빗 서브넷 보안 그룹 생성
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Private subnet security group"
  vpc_id      = aws_vpc.new_vpc.id // VPC ID 참조

  ingress {
    from_port   = 22 // SSH 포트
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.new_vpc.cidr_block] // VPC 내부에서의 접근 허용
  }

  egress {
    from_port   = 0 // 모든 아웃바운드 트래픽 허용
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Bastion 호스트 인스턴스 생성
resource "aws_instance" "bastion" {
  ami           = var.ami_id // AMI ID 변수 참조
  instance_type = var.instance_type // 인스턴스 타입 변수 참조
  subnet_id     = aws_subnet.new_public_subnet_2a.id // 퍼블릭 서브넷 ID 참조
  vpc_security_group_ids = [aws_security_group.bastion_sg.id] // 보안 그룹 참조

  tags = {
    Name = "Bastion Host" // 인스턴스 이름 태그 설정
  }
}

// 프라이빗 EC2 인스턴스 생성
resource "aws_instance" "private_instance" {
  ami           = var.ami_id // AMI ID 변수 참조
  instance_type = var.instance_type // 인스턴스 타입 변수 참조
  subnet_id     = "${aws_subnet.new_public_subnet_2a.id}" // 프라이빗 서브넷 ID 참조
  vpc_security_group_ids = [aws_security_group.private_sg.id] // 보안 그룹 참조

  tags = {
    Name = "Private EC2" // 인스턴스 이름 태그 설정
  }
}

// RDS 인스턴스 생성
resource "aws_db_instance" "default" {
  allocated_storage    = 20 // 스토리지 크기 (GB)
  engine               = "mysql" // 데이터베이스 엔진
  engine_version       = "5.7" // 데이터베이스 엔진 버전
  instance_class       = "db.t2.micro" // 인스턴스 클래스
  identifier           = "mydbinstance" // RDS 인스턴스 식별자
  username             = var.db_username // 데이터베이스 사용자 이름 변수 참조
  password             = var.db_password // 데이터베이스 비밀번호 변수 참조
  parameter_group_name = "default.mysql5.7" // 파라미터 그룹 이름
  publicly_accessible  = false // 퍼블릭 접근 비활성화
  db_subnet_group_name = aws_db_subnet_group.main.name // 서브넷 그룹 참조
  skip_final_snapshot  = true // 마지막 스냅샷 생성을 건너뜀

  vpc_security_group_ids = [aws_security_group.private_sg.id] // VPC 보안 그룹 참조

  tags = {
    Name = "MyRDSInstance" // 인스턴스 이름 태그 설정
  }
}

// RDS 서브넷 그룹 생성
resource "aws_db_subnet_group" "main" {
  name       = "main" // 서브넷 그룹 이름
  subnet_ids = ["${aws_subnet.new_public_subnet_2a.id}"] // 서브넷 ID 참조

  tags = {
    Name = "Main subnet group" // 서브넷 그룹 이름 태그 설정
  }
}

// Bastion 호스트의 퍼블릭 IP 출력
output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "The public IP of the Bastion Host"
}

// Private EC2 인스턴스의 ID 출력
output "private_instance_id" {
  value       = aws_instance.private_instance.id
  description = "The ID of the Private EC2 Instance"
}

// RDS 인스턴스의 엔드포인트 출력
output "rds_endpoint" {
  value       = aws_db_instance.default.endpoint
  description = "The endpoint of the RDS Instance"
}

