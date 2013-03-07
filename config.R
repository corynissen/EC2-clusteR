
# this file contains the aws configuration parameters

# this is my test queue
queue <- "Q1"
# aws account number stored in separate file
aws.account <- as.character(scan("~/.awsaccount", quiet=T))
ami <- "ami id here"
aws.zone <- "aws availability zone here"

max.nodes <- "maximum number of nodes to use"
allowable.time <- "max allowable time between tasks for a machine"

# these have private info, will strip out and move to main area soon
path.to.ec2.shell.scripts <- "AWS_scripts"
