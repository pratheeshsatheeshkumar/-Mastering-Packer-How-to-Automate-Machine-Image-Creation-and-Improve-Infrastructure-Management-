# “Mastering Packer: How to Automate Machine Image Creation and Improve Infrastructure Management”

![](https://miro.medium.com/max/1400/0*2sERwRpJbNPNnJE_.jpg)

I’m glad you’re interested in learning about Packer! Packer is a great tool for automating the creation of machine images for different platforms, such as AWS, VirtualBox, and VMware.

One of the biggest benefits of using Packer is that it allows you to create reproducible and consistent machine images. This is important because it means that you can be sure that the image you created will work the same way on any machine, regardless of where it’s deployed. This makes it much easier to manage and scale your infrastructure.

Creating an Amazon Machine Image (AMI) using Packer can be a powerful way to automate the process of building and maintaining images for use in Amazon Web Services (AWS). Packer is a tool that allows you to create machine images for multiple platforms, including AWS, in a consistent and automated way.

# **Install Packer**

Here are the general steps for installing Packer on a Windows, Linux, or macOS machine:

1.  Download the appropriate Packer binary for your operating system from the Packer website ([https://www.packer.io/downloads/](https://www.packer.io/downloads/)).
2.  Extract the contents of the downloaded archive to a directory on your system.
3.  Add the directory containing the Packer binary to your system’s PATH environment variable, so that you can run Packer from the command line.
4.  Open a command prompt or terminal and run the command `packer version` to verify that Packer was installed correctly and to see the version number.

**Here’s an example of how to install Packer on a Linux machine:**

1.  Download the Packer binary:

wget https://releases.hashicorp.com/packer/1.7.5/packer_1.7.5_linux_amd64.zip

2. Unzip the binary

unzip packer_1.7.5_linux_amd64.zip

3. Move the binary to a folder in PATH:

sudo mv packer /usr/local/bin/

4. Verify the installation
```sh
$ packer version  
Packer v1.8.5  
$ packer
```
Once you enter “packer” you will get an output as shown below.

![](https://miro.medium.com/max/1400/1*dTJaOVBLiZ8pr1ER-3VnPg.png)

# Building AWS Amazon Machine Image(VM Image) Using Packer.

![](https://miro.medium.com/max/1400/0*lJuKI6-e1xnAqvf8.png)

1.  Create a Packer template using HCL (Hashicorp Configuration Language) or JSON, and specify all necessary VM configurations within it.
2.  To construct the VM image, run Packer using the template.
3.  Authentication with AWS is done automatically, through a programmatic IAM account if executed within AWS environment.
4.  Upon successful authentication, Packer launches a temporary server instance and establishes a connection to the server through SSH.
5.  Applies the specified provisioner (e.g. Shell script, Ansible, Chef) to configure the server.
6.  The created image is then registered as an AMI.
7.  Finally, the running temporary instance is terminated.

# Packer HCL Template

Once Packer is installed and configured, you can begin creating your image by writing a Packer template.

![](https://miro.medium.com/max/1400/1*D5AwiiPjM3pOLeZMNfoWhQ.png)

A Packer template file for building an Amazon Web Services (AWS) machine image typically contains five main components:

1.  **Sources**: These specify the base image(s) from which the final image will be built. For example, the source might be an Amazon Machine Image (AMI) that serves as the starting point for the image.
```sh
source "amazon-ebs" "region1" {  
    
  region = var.regions.region1  
  access_key = var.access_key  
  secret_key = var.secret_key  
  
  ami_name = local.image-name  
  source_ami = var.source_ami.ap-south-1  
  instance_type = "t2.micro"  
  ssh_username = "ec2-user"  
  
  tags = {  
      
     Name = local.image-name  
     project = var.project  
     environment = var.environment  
  
  }   
}
```
**2. Variables**: These allow for parameterization of the template, making it more flexible and reusable. For example, variables can be used to specify the AWS region, availability zone, or instance type to be used when building the image.

  
 ```sh 
variable "project" {  
  type =string  
  default = "zomato"  
}  
variable "environment" {  
  type = string  
  default = "prod"  
}  
  
variable "regions" {  
  type = map(string)  
default = {  
  "region1" = "ap-south-1"  
  "region2" = "us-east-1"  
}  
}  
```
**3. Builders:** This component of packer template defines which infrastructure platform, such as AWS, google cloud, azure etc. and the various settings required to create an image, such as the instance type, or whether to use an existing image or launch a new instance.
```sh
build {  
 /*==Source configuration to create the  AMI ==*/    
  sources = ["source.amazon-ebs.region1"]  
 .  
 .  
}

**4. Provisioners**: These are used to automate the process of setting up and configuring the image after it is built. For example, you can use provisioners to install software, configure the operating system, or run scripts on the image.

build {  
.  
.  
.  
provisioner "shell"{  
     script ="./setup.sh"  
     execute_command = "sudo {{.Path}}"  
  
  }  
.  
.  
}  
```
#setup.sh script used to setup the server environment  
 ```sh 
#!/bin/bash  
  
  
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config  
echo "LANG=en_US.utf-8" >> /etc/environment  
echo "LC_ALL=en_US.utf-8" >> /etc/environment  
service sshd restart  
  
  
yum install httpd php -y  
  
cat <<EOF > /var/www/html/index.php  
<?php  
\$output = shell_exec('echo $HOSTNAME');  
echo "<h1><center><pre>\$output</pre></center></h1>";  
echo "<h1><center> Version2 </center></h1>"  
?>  
EOF  
  
systemctl restart httpd.service  
systemctl enable httpd.service  
```
**5. Post-processors**: These are used to perform additional actions on the created images, such as compressing the image, creating an AWS AMI, or publishing to a distribution channel.

As per [official documentation](https://developer.hashicorp.com/packer/docs/post-processors/manifest),

> The manifest post-processor writes a JSON file with a list of all of the artifacts packer produces during a run. If your Packer template includes multiple builds, this helps you keep track of which output artifacts (files, AMI IDs, Docker containers, etc.) correspond to each build.

Here, manifest.auto.tfvars.json file will be created with ID of the Packer created AMI in it. I created this file with .auto.tfvars extension to allow it to auto load the required variables to Terraform for launching instances out of the AMI built by Packer.
```sh
build {  
.  
.  
  /*==Deletion of manifest file containing old AMI ID==*/    
  post-processor "shell-local" {   
      inline = [ "rm -rf manifest.auto.tfvars.json" ]  
    }  
   
 /*==Creation of manifest file containing new AMI ID==*/  
  post-processor "manifest" {  
    output     = "manifest.auto.tfvars.json"  
    strip_path = true  
  }  
}
```
# **Steps in building the AMI creation after coding.**

1.  Create a Packer template file that defines the AMI configuration, including the source AMI, the provisioners to run, and the build tags to apply. I have given below the full code in the template files **main.pkr.hcl and variables.pkr.hcl**
```sh
  
#main.pkr.hcl full code  
/*==Source configuration consists of source AMI, AWS credentials, instance_type   
 and ssh-username==/*  
  
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
 ``` 
```sh
#variables.pkr.hcl full code  
  
variable "access_key" {  
  default      = "XXXXXX" #DevOps2   
  description = "access key of the provider"  
}  
  
variable "secret_key" {  
  default     = "YYYYYY" #DevOps2  
  description = "secret key of the provider"  
}  
  
variable "project" {  
  type =string  
  default = "zomato"  
}  
variable "environment" {  
  type = string  
  default = "prod"  
}  
  
variable "regions" {  
  type = map(string)  
default = {  
  "region1" = "ap-south-1"  
  "region2" = "us-east-1"  
}  
}  
  
variable "source_ami" {  
  
  type =map(string)  
  default = {  
    "ap-south-1" = "ami-0cca134ec43cf708f"  
    "us-east-1" =  "ami-0b5eea76982371e91"  
  }  
}  
locals {  
  image-timestamp = "${formatdate("YYYY-MM-DD-hh-mm",timestamp())}"  
  image-name = "${var.project}-${var.environment}-${local.image-timestamp}"  
}
```
2. Use the Packer command line interface to validate the template file.
```sh
$ packer validate .
```
3. Use the Packer command `build` to start the AMI creation process.
```sh
$ packer build .
```
Now, Packer will then take care of the rest, including launching an EC2 instance, provisioning it, creating an image, and store the id in the .json file.

![](https://miro.medium.com/max/1400/1*1e1kYy5y4rtKg-DisEhmuw.png)

# Creating machine images with Packer and provisioning resources with Terraform using these images.

![](https://miro.medium.com/max/1400/1*FXHYHCw07mwdxnZTmh6wMA.png)

Creating machine images with Packer and provisioning resources with Terraform are two common tasks in infrastructure automation. One way to tie these tasks together is to save the Amazon Machine Image (AMI) ID from Packer as a JSON file and then use it in Terraform to create an instance.

Here’s a step-by-step guide on how to save the AMI ID from Packer as a JSON file and then use it in Terraform to create an instance.

1.  Use the Packer template file with the necessary configuration to create an AMI as we have done above.
2.  Add an additional post-processor to the Packer template that saves the AMI ID to **_manifest.auto.tfvars.json_** file. This can be done using the “manifest” post-processor The code would look like this:
```sh
 post-processor "manifest" {  
    output     = "manifest.auto.tfvars.json"  
    strip_path = true 
```
If we check the contents of the **_manifest.auto.tfvars.json._** It would be something like this.
```sh
#manifest.auto.tfvars.json.  
{  
  "builds": [  
    {  
      "name": "region1",  
      "builder_type": "amazon-ebs",  
      "build_time": 1673527894,  
      "files": null,  
      "artifact_id": "ap-south-1:ami-0091a1b4ac059ee8f", #This is the AMI ID  
      "packer_run_uuid": "4324b08b-81eb-7db4-9196-8908df5ee8ea",  
      "custom_data": null  
    }  
  ],  
  "last_run_uuid": "4324b08b-81eb-7db4-9196-8908df5ee8ea"  
}
```
# main.tf of Terraform

**3.** Terraform **main.tf** file containing configurations to fetch AMI ID, create key pairs, import public key to AWS, store private key as a file in the local file system, fetch AMI ID from the JSON file and Launch an instance using this AMI ID.
```sh
#main.tf  
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
  ```

> variables.tf
```sh
variable "project" {  
  type    = string  
  default = "zomato"  
}  
variable "environment" {  
  type    = string  
  default = "prod"  
}  
  
variable "region" {  
  default = "ap-south-1"  
}  
  
/*=== This structure is replicating the Key structure of the JSON file to assign values from it.==*/  
variable "builds" {  
  type = list(  
    object(  
      {  
        name            = string,  
        builder_type    = string,  
        build_time      = number,  
        files           = list(object({ name = string, size = number })),  
        artifact_id     = string,  
        packer_run_uuid = string  
      }  
    )  
  )  
  description = "List of images, as generated by Packer's 'Manifest' post-processor."  
}  
variable "last_run_uuid" {  
  type = string  
}
```
**4. Terraform Init, validate and Apply**
```sh
$ terraform init  
  
Initializing the backend...  
  
Initializing provider plugins...  
- Reusing previous version of hashicorp/null from the dependency lock file  
- Reusing previous version of hashicorp/local from the dependency lock file  
- Reusing previous version of hashicorp/tls from the dependency lock file  
- Reusing previous version of hashicorp/aws from the dependency lock file  
- Using previously-installed hashicorp/aws v4.49.0  
- Using previously-installed hashicorp/null v3.2.1  
- Using previously-installed hashicorp/local v2.3.0  
- Using previously-installed hashicorp/tls v4.0.4  
  
Terraform has been successfully initialized!  
  
You may now begin working with Terraform. Try running "terraform plan" to see  
any changes that are required for your infrastructure. All Terraform commands  
should now work.  
  
If you ever set or change modules or backend configuration for Terraform,  
rerun this command to reinitialize your working directory. If you forget, other  
commands will detect it and remind you to do so if necessary.  
``` 
```sh 
  
$ terraform validate  
Success! The configuration is valid.  
```
Terraform Apply will create all the resources and do the tasks in the configuration file. It will read the variable**s** from **manifest.auto.tfvars.json** automatically while executing terraform apply command.
```sh
$ terraform apply -auto-approve  
data.local_file.credentials: Reading...  
data.local_file.credentials: Read complete after 0s [id=a1db364ec7aacf12e960c0321dde307d54cfa108]  
  
Terraform used the selected providers to generate the following execution plan. Resource  
actions are indicated with the following symbols:  
  + create  
  
Terraform will perform the following actions:  
  
  # aws_instance.webserver will be created  
  + resource "aws_instance" "webserver" {  
.  
.  
.  
aws_instance.webserver (local-exec): Executing: ["/bin/sh" "-c" "echo 'ssh -i /home/opc/PACKER/mykeypair.pem ec2-user@65.0.124.180'"]  
aws_instance.webserver (local-exec): ssh -i /home/opc/PACKER/mykeypair.pem ec2-user@65.0.124.180  
aws_instance.webserver: Creation complete after 34s [id=i-032da7da0fadfed58]  
  
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```
We can find our Instance in the AWS console.

![](https://miro.medium.com/max/1400/1*PicZVFcBVBQCVAHQYv4IjA.png)

You can finds the same AMI ID([ami-0091a1b4ac059ee8f](https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#ImageDetails:imageId=ami-0091a1b4ac059ee8f)) here.

# Conclusion

In conclusion, creating a Packer AMI and using Terraform to deploy instances can greatly simplify and automate the process of setting up and scaling infrastructure. By packaging all necessary dependencies and configurations into an AMI, you can ensure consistency and ease of management across multiple instances. And by using Terraform to provision those instances, you can version control and automate the process of creating and updating infrastructure. Overall, utilizing these tools can lead to a more efficient and effective workflow for managing your infrastructure.

Thank you for your time. In case of suggestions, feel free to contact me.

Pratheesh Satheesh Kumar

[linkedin](https://www.linkedin.com/in/pratheesh-satheesh-kumar/)
