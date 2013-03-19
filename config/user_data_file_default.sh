#!/bin/bash

#This script executes on a classification machine upon boot.

# aws keys
aws_access_key_id=your id here
aws_secret_access_key=your secret access key here
aws_account=your account number here

# install git
apt-get install git

# install python boto
#pip install -U boto
cd /root
git clone https://github.com/boto/boto.git 
cd boto 
python setup.py install

# aws keys for aws package
echo $aws_access_key_id >> /root/.awssecret
echo $aws_secret_access_key >> /root/.awssecret
chmod 600 /root/.awssecret

# aws keys for boto package
echo [Credentials] >> /etc/boto.cfg
echo aws_access_key_id = $aws_access_key_id >> /etc/boto.cfg
echo aws_secret_access_key = $aws_secret_access_key >> /etc/boto.cfg
chmod 600 /etc/boto.cfg

# aws account for this package
echo $aws_account >> /root/.awsaccount
chmod 600 /root/.awsaccount

# get this package from github
mkdir /src
chmod u+rwx /src
cd /src
git clone git@github.com:corynissen/EC2-clusteR.git

# make sure executables have rights
chmod u+x EC2-clusteR/AWS_scripts/aws
chmod u+x EC2-clusteR/AWS_scripts/read_from_dynamo.py
chmod u+x EC2-clusteR/AWS_scripts/write_to_dynamo.py
chmod u+x EC2-clusteR/AWS_scripts/write_output_to_dynamo.py

# copy the config parameters that the worker.R script will need to the 
# remote machine so you don't have to scp it over there.
cd /src/EC2-clusteR/config
echo 'my.queue <- "queue_name"' >> config_local.R
echo 'my.log.table.name <- "table name here"' >> config_local.R
echo 'my.output.table.name <- "table name here"' >> config_local.R
echo 'my.aws.account <- "aws account number here"' >> config_local.R
echo 'my.path.to.ec2.shell.scripts <- "AWS_scripts"' >> config_local.R
chmod 600 /src/EC2-clusteR/config/config_local.R

# start the worker node script
cd /src/EC2-clusteR
Rscript worker.R >> log.txt