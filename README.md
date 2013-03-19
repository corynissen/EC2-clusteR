EC2-clusteR
===========

This is a framework that creates a cluster of EC2 instances. Each instance reads a message from a queue, does a task, logs the task in a dynamo table, writes the output from the task in a dynamo table (or anywhere, it's up to you) and goes on to the next one until the queue is empty. The controller monitors the workers and shuts them off if they haven't completed a task in a certain configurable amount of time. Once the queue is empty, the workers will stop logging completed tasks and the controller will shut them down, usually within a minute (configurable) of the queue becoming empty.

Dependencies  
aws package by Tim Kay... https://github.com/timkay/aws  
aws package uses perl  
boto (python package) needed for dynamodb communication  
aws keys stored in /etc/boto.cfg for boto package  
aws keys stored in ~/.awssecret for aws package  
aws account number stored in ~/.awsaccount    

Notes  

I have created "local" and "default" versions of files that contain sensitive information. On my machine, I have both versions. Default is the one that I keep dummy information in so that you all don't have access to it and local is the version that I keep my personal info in. You can modify "default" or create a copy, call it "local" and use that instead. Both are read in, with "local" overriding "default".

For the worker nodes, I put the config_local.R script directly in the user_data_file_default(local).sh so that you don't have to scp over a "local" version of your sensitive account info to the worker machine. It will have it at boot time via the boot script.  

It's probably best to have the controller node on AWS so that it's closer to the worker nodes for communication and whatnot. It's not a requirement though. Controller will run fine on a local machine so long as the dependencies listed above have been satisfied.

worker.R should be customized to do the task that you would like. Right now, it reads tweets from a queue and stores the number of smileys in dynamo. With that said, if you do change worker.R, you will have to change the python dynamo script(s) to match the schema of your output from the worker node.
  