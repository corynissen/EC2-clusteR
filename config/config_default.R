
# this is the default file contains the aws configuration parameters
# create a copy of this file called config.local, if it exists, it will
# override these defaults for your specific needs... aws.account, for ex.

# this is my test queue
queue <- "queue_name_here"

# aws account number
aws.account <- scan("~/.awsaccount", quiet=T)

# pick your favorite linux (ubuntu probably would work best) with R installed
# bioconductor ami http://bioconductor.org/help/bioconductor-cloud-ami/#ami_ids
ami.id <- "ami-910c83f8"

# choose your favorite availability zone
aws.availability.zone <- "us-east-1c"

# choose an instance type, m2.xlarge, m2.2xlarge, m2.4xlarge, c1.medium,
# c1.xlarge, m1.small, m1.medium, m1.large, m1.xlarge, t1.micro,
# m3.xlarge m3.2xlarge, etc.. you ge the idea
ec2.instance.type <- "t1.micro"

# path to startup script for an EC2 instance
user.data.file <- ifelse(file.exists("config/user_data_file_local.sh"),
       "config/user_data_file_local.sh", "config/user_data_file_default.sh")

# maximum number of worker nodes to use
max.nodes <- 3

# allowable time in seconds between tasks for a machine before intervention
# by the controller machine
allowable.time <- 180

# these have private info, will strip out and move to main area soon
path.to.ec2.shell.scripts <- "AWS_scripts"
