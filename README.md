EC2-clusteR
===========

This creates a cluster of EC2 instances. Each instances reads from a queue, does a task, logs the task, and goes on to the next one until the queue is empty.

Dependencies  
aws package by Tim Kay... https://github.com/timkay/aws  
aws package uses perl  
boto (python package) needed for dynamodb communication  
aws keys stored in /etc/boto.cfg for boto package  
aws keys stored in ~/.awssecret for aws package  
aws account number stored in ~/.awsaccount    
  