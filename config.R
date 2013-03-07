
# this file contains the aws configuration parameters

# this is my test queue
queue <- "Q1"
# aws account number stored in separate file
aws.account <- as.character(scan("~/.awsaccount", quiet=T))
# bioconductor ami http://bioconductor.org/help/bioconductor-cloud-ami/#ami_ids
ami.id <- "ami-910c83f8"
aws.availability.zone <- "us-east-1a"
ec2.instance.type <- "t1.micro"  # "m1.small"
# startup script for an EC2 instance
user.data.file <- ""
# maximum number of worker nodes to use
max.nodes <- 3
# allowable time in seconds between tasks for a machine before intervention
# by the controller machine
allowable.time <- 180

# these have private info, will strip out and move to main area soon
path.to.ec2.shell.scripts <- "AWS_scripts"
