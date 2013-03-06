
# Dependencies
# aws package by Tim Kay... https://github.com/timkay/aws
# aws package uses perl
# boto (python package) needed for dynamodb communication
# aws keys stored in /etc/boto.cfg for boto package
# aws keys stored in ~/.awssecret for aws package
# aws account number stored in ~/.awsaccount so I don't have to put it in code

##### this is the script that runs everything

# this is the function that will be processing items from the queue
# it must be able to read from the queue to get a task, do the task,
# and write back to the queue indicating the task is done
some.function <- function(x){
  # read task from queue
  taskid <- read.task.from.queue(queue)
  # do something with it
  # write output somewhere...
  # if success, write to queue
  write.task.complete.to.queue(queue, taskid)
  # if success, write time to dynamo
  write.task.log.to.dynamo(aws.access.key=aws.access.key, aws.secret.key,
                           machine.id=machine.id, sys.time=Sys.time(), taskid)
}  

# this is my test queue
queue <- "Q1"
# aws account number stored in separate file
aws.account <- as.character(scan("~/.awsaccount", quiet=T))
ami <- "ami id here"
aws.zone <- "aws availability zone here"

max.nodes <- "maximum number of nodes to use"
allowable.time <- "max allowable time between tasks for a machine"

# these have private info, will strip out and move to main area soon
path.to.ec2.shell.scripts <- "~/cn/personal/030413_amazon_controller/EC2-clusteR/AWS_scripts"

start.ec2.machine <- function(aws.access.key=aws.access.key, aws.secret.key,
                              ami=ami, aws.zone=aws.zone){
  #start machine
  return("id of machine")
}

stop.ec2.machine <- function(aws.access.key=aws.access.key, aws.secret.key,
                             machine.id=machine.id){
  #stop machine
  return("success or not")
}

read.task.from.queue <- function(path.to.ec2.shell.scritps,
                                 aws.account=aws.account, queue=queue){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws receive-message /", aws.account, "/", queue,
                             " --simple"), intern=T)
  response.list <- strsplit(response, "\t")[[1]]
  receipt.handle <- response.list[1]
  message.body <- response.list[2]
  messageid <- response.list[3]
  ret.val <- list(message.body=message.body, receipt.handle=receipt.handle, messageid=messageid)
  return(ret.val)
}

task.json <- '{messageID:3,message:"test from R"}'
write.task.to.queue <- function(task.json, path.to.ec2.shell.scritps,
                                aws.account=aws.account, queue=queue){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws send-message /", aws.account, "/", queue,
                             " --simple -message ",task.json), intern=T)
  messageid <- substring(response, regexpr("\t", response)[1]+1, nchar(response))
  return(messageid)
}

read.task.list <- read.task.from.queue(path.to.ec2.shell.scritps=path.to.ec2.shell.scritps,aws.account=aws.account, queue=queue)
receipt.handle <- read.task.list$receipt.handle
delete.message.from.queue <- function(receipt.handle){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws delete-message /", aws.account, "/", queue,
                             " --simple --handle ",receipt.handle), intern=T)
  ret.val <- ifelse(sum(grepl("ReceiptHandleIsInvalid", response)) > 0, "ReceiptHandleIsInvalid", "success")
  return(ret.val)
}

get.queue.length <- function(path.to.ec2.shell.scritps,
                             aws.account=aws.account, queue=queue){
  # get the queue length and return it  
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws get-queue-attributes /", aws.account, "/", queue,
                             " --simple -attribute All"), intern=T)
  if(sum(grepl("ApproximateNumberOfMessages\t", response)) == 0){
    ret.val <- "error in getting queue length"
  }else{
    queue.length <- response[grepl("ApproximateNumberOfMessages\t", response)]
    queue.length <- substring(queue.length, regexpr("\t", queue.length)[1]+1, nchar(queue.length))
    ret.val <- queue.length
  }
  return(ret.val)
}

write.task.log.to.dynamo <- function(path.to.ec2.shell.scripts, table.name, machine.id=machine.id, taskid){
  # every time a task is successfully completed, log it in dynamodb with the
  # machineid as the hash, the sys.time as the range, and taskid as data
  time.pretty <- Sys.time()
  time.int <- round(unclass(time.pretty))
  ret.val <- system(paste0("python ", path.to.ec2.shell.scripts,
                           "/write_to_dynamo.py \'", table.name, "\' \'", taskid,
                           "\' \'", machine.id, "\' \'", time.pretty, "\' ", time.int),
                    intern=T)
  return(ret.val)
} # write.task.log.to.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,table.name="cory_test", machine.id="machineid2", taskid="taskid1")

read.task.log.from.dynamo <- function(path.to.ec2.shell.scripts, table.name, machine.id=machine.id){
  # read the most recent message for a given machine.id
  ret.val <- system(paste0("python ", path.to.ec2.shell.scripts,
                           "/read_from_dynamo.py \'", table.name,
                           "\' \'", machine.id, "\'"),
                    intern=T)
  return(ret.val)
} # read.task.log.from.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,table.name="cory_test", machine.id="machineid2")

run <- function(queue=queue, func=some.function, aws.access.key=aws.access.key,
                aws.secret.key=aws.secret.key, ami=ami, aws.zone=aws.zone,
                max.nodes=max.nodes){
  # start machines
  # change to apply-ish function after working
  ec2.machine.id.vec <- NULL
  for(i in 1:max.nodes){
    print(paste("starting machine number", i, "of", max.nodes))
    ec2.machine.id.vec <- c(ec2.machine.id.vec,
                            start.ec2.machine(aws.access.key, aws.secret.key,
                                              ami, aws.zone))
  }

  ### monitoring
  # read the time of the most recently completed task for each machine
  # if the time difference from current time has been greater than
  # allowable.time, then kill the machine and if there are still items
  # left in the queue, start another machine
  while(length(ec2.machine.id.vec) > 0){
    for(machine in ec2.machine.id.vec){
      last.task.time <- read.task.log.from.dynamo(machine)
      if(Sys.time() - last.task.time > allowable.time){
        stop.ec2.machine(aws.access.key=aws.access.key, aws.secret.key,
                         machine.id=machine.id)
        # remove stopped machine from list
        ec2.machine.id.vec <- ec2.machine.id.vec[ec2.machine.id.vec != machine]
        # start new machine if there are still items left in queue
        if(get.queue.length(queue) > 0){
          ec2.machine.id.vec <- c(ec2.machine.id.vec,
                                  start.ec2.machine(aws.access.key, aws.secret.key,
                                                    ami, aws.zone))
        }
      }
    }
  }
  # Shouldn't need this as they should all be stopped already...
  # stop machines
#  for(machine in ec2.machine.id.vec){
#    stop.ec2.machine(aws.access.key=aws.access.key, aws.secret.key,
#                     machine.id=machine.id)
#  }
}

