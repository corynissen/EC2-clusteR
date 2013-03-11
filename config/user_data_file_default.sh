#!/bin/bash

#########################################
######## DO NOT CHECK INTO GIT ##########
#########################################

#This script executes on a classification machine upon boot.

# aws keys
aws_access_key_id=your_id_here
aws_secret_access_key=your_key_here
aws_account=your_aws_account

# install git
apt-get install git

# install pip
apt-get install python-pip python-dev build-essential
pip install --upgrade pip 
pip install --upgrade virtualenv 

# install python boto
pip install -U boto

# aws keys for aws package
echo $aws_access_key_id >> /home/ubuntu/.awssecret
echo $aws_secret_access_key >> /home/ubuntu/.awssecret
chmod 600 /home/ubuntu/.awssecret

# aws keys for boto package
echo [Credentials] >> /etc/boto.cfg
echo aws_access_key_id = $aws_access_key_id >> /etc/boto.cfg
echo aws_secret_access_key = $aws_secret_access_key >> /etc/boto.cfg
chmod 600 /etc/boto.cfg

# aws account for this package
echo $aws_account >> /home/ubuntu/.awsaccount
chmod 600 /home/ubuntu/.awsaccount

# get this package from github
mkdir /src
chmod u+rwx /src
cd /src
git clone git@github.com:corynissen/EC2-clusteR.git

# make sure executables have rights
chmod u+x EC2-clusteR/AWS_scripts/aws
chmod u+x EC2-clusteR/AWS_scripts/read_from_dynamo.py
chmod u+x EC2-clusteR/AWS_scripts/write_to_dynamo.py

# start the worker node script
Rscript EC2-cluster/worker.R

