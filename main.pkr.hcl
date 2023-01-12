source "amazon-ebs" "region1" {

  region     = var.regions.region1
  access_key = var.access_key
  secret_key = var.secret_key
  ami_name      = local.image-name
  source_ami    = var.source_ami.ap-south-1
  instance_type = "t2.micro"
  ssh_username  = "ec2-user"

  tags = {

    Name        = local.image-name
    project     = var.project
    environment = var.environment

  }
}

source "amazon-ebs" "region2" {

  region     = var.regions.region2
  access_key = var.access_key
  secret_key = var.secret_key

  ami_name      = local.image-name
  source_ami    = var.source_ami.us-east-1
  instance_type = "t2.micro"
  ssh_username  = "ec2-user"

  tags = {

    Name        = local.image-name
    project     = var.project
    environment = var.environment

  }
}

build {
 /*==Source configuration to create the  AMI ==*/  
  sources = ["source.amazon-ebs.region1"]
   /*==Setup Script for the AMI==*/ 
   provisioner "shell" {
    script          = "./setup.sh"
    execute_command = "sudo {{.Path}}"

  }
 
  /*==Recreation of manifest file containing AMI ID==*/  
  post-processor "shell-local" { 
      inline = [ "rm -rf manifest.auto.tfvars.json" ]
    }
 
  post-processor "manifest" {
    output     = "manifest.auto.tfvars.json"
    strip_path = true
  }
}


