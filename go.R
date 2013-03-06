
library(RCurl)
library(XML)

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

# some way to identify and read/write from the queue
queue <- "put URL for queue here"

aws.access.key <- "aws access key here"
aws.secret.key <- "aws secret key here"
ami <- "ami id here"
aws.zone <- "aws availability zone here"

max.nodes <- "maximum number of nodes to use"
allowable.time <- "max allowable time between tasks for a machine"

# these have private info, will strip out and move to main area soon
path.to.ec2.shell.scripts <- "~/cn/personal/030413_amazon_controller/Joe_SQS_scripts"

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

read.task.from.queue <- function(){
  task.http <- system(paste0("bash ", path.to.ec2.shell.scripts, "/SQSget.sh "),
                      intern=T)
  response <- getURL(task.http)
  response.list <- xmlToList(xmlParse(response))
  message.body <- response.list$ReceiveMessageResult$Message$Body
  return(message.body)
}

task.json <- '{messageID:3,message:"test from R"}'
write.task.to.queue <- function(task.json){
  task.http <- system(paste0("bash ", path.to.ec2.shell.scripts, "/SQSput.sh ",
                             task.json), intern=T)
  response <- getURL(task.http)
  messageid <- xmlToDataFrame(response)$MessageId[1]
  return(messageid)
}

write.task.complete.to.queue <- function(queue, taskid){
  return("success?")
}

write.task.log.to.dynamo <- function(aws.access.key=aws.access.key, aws.secret.key,
                             machine.id=machine.id, sys.time, taskid){
  # every time a task is successfully completed, log it in dynamodb with the
  # machineid as the hash, the sys.time as the range, and taskid as data
}

read.task.log.from.dynamo <- function(aws.access.key=aws.access.key, aws.secret.key,
                             machine.id=machine.id){
  # read the time of the most recently completed task for a given machineid
}

get.queue.length <- function(queue){
  # get the queue length and return it
  return(queue.length)
}

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

