#Terraform main.tf
/*===AWS Provider is included and credentials are fed from another file.===*/
provider "aws" {

  region     = var.region
  access_key = jsondecode(data.local_file.credentials.content)["access_key"]
  secret_key = jsondecode(data.local_file.credentials.content)["secret_key"]
}

/*===AWS Credentials are stored in an local_file datasource ===*/
data "local_file" "credentials" {
  filename = "/var/.aws/credentials.json"
}

/*===TLS keypairs are created ===*/
resource "tls_private_key" "tls_key_creator" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
/*===Imported public key to aws and saved private key localy using a provisioner===*/
resource "aws_key_pair" "import_key_pair" {
  key_name_prefix = "${var.project}-${var.environment}-"
  public_key      = tls_private_key.tls_key_creator.public_key_openssh
  provisioner "local-exec" {

    command = "echo \"${tls_private_key.tls_key_creator.private_key_pem}\" > ./mykeypair.pem ; chmod 400 ./mykeypair.pem"
  }
}
/*===Security group is created with allow all access ===*/
resource "aws_security_group" "allow_all" {
  name_prefix = "${var.project}-${var.environment}-"
  description = "Allow  inbound traffic"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
/*===Code to fetch the AMI ID from the manifest.auto.tfvars.json ===*/
resource "null_resource" "ami_id" {
  triggers = {
    ami_value = split(":", element(var.builds, 0).artifact_id)[1]
  }
}

/*===Creation of EC2 Instance using fetched AMI ID ===*/
resource "aws_instance" "webserver" {
  
  ami                    = resource.null_resource.ami_id.triggers.ami_value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  key_name               = aws_key_pair.import_key_pair.key_name

  provisioner "local-exec" {

    command = "echo 'ssh -i ${path.cwd}/mykeypair.pem ec2-user@${aws_instance.webserver.public_ip}'"
  }

  tags = {
    Name = "${var.project}-${var.environment}-webserver"
  }

}

