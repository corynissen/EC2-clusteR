
# this script will manage the starting / stopping of worker nodes.
install.packages("RJSONIO", repos="http://cran.mtu.edu/")
library(RJSONIO)

# if local file exists, source it, otherwise source the default one.
config_file <- ifelse((file.exists("config/config_local.R")),
                      "config/config_local.R", "config/config_default.R")
source(config_file)
source("helper.R")

# this is the function that will be processing items from the queue
# it must be able to read from the queue to get a task, do the task,
# and write back to the queue indicating the task is done

run <- function(queue, max.nodes, ami.id, ec2.instance.type, aws.availability.zone, path.to.ec2.shell.scripts, allowable.time, aws.account, user.data.file){
  # start machines
  # change to apply-ish function after working
  ec2.machine.id.vec <- NULL
  for(i in 1:max.nodes){
    print(paste("starting machine number", i, "of", max.nodes))
    ec2.machine.id.vec <- c(ec2.machine.id.vec,
                            start.ec2.machine(ami.id=ami.id,
                                 ec2.instance.type=ec2.instance.type,
                                 aws.availability.zone=aws.availability.zone,
                                 path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                 user.data.file=user.data.file, key=ec2.key,
                                 group=ec2.security.group))
  }

  ### monitoring
  # read the time of the most recently completed task for each machine
  # if the time difference from current time has been greater than
  # allowable.time, then kill the machine and if there are still items
  # left in the queue, start another machine
  while(length(ec2.machine.id.vec) > 0){
    for(machine in ec2.machine.id.vec){
      read.message.log.json <- read.message.log.from.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                    table.name=log.table.name, instance.id=machine)
      # amazon may return single quotes instead of required double quotes
      log.list <- fromJSON(gsub("'", '"', read.message.log.json$Count))
      log.count <- log.list$Count
      if(log.count>0){
        last.message.time <- log.list$Items[[1]]$datetime
        if(unclass(Sys.time()) - last.message.time > allowable.time){
          stop.ec2.machine(instance.id=machine, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)
          # remove stopped machine from list
          ec2.machine.id.vec <- ec2.machine.id.vec[ec2.machine.id.vec != machine]
          # start new machine if there are still items left in queue
          queue.length <- get.queue.length(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                         aws.account=aws.account, queue=queue)
          if(as.numeric(queue.length) > 10){
            ec2.machine.id.vec <- c(ec2.machine.id.vec,
                                  start.ec2.machine(ami.id=ami.id,
                                  ec2.instance.type=ec2.instance.type,
                                  aws.availability.zone=aws.availability.zone,
                                  path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                  key=ec2.key))
          }
        }
      }
    }
  }
  # Shouldn't need this as they should all be stopped already...
  # stop machines
  for(machine in ec2.machine.id.vec){
    stop.ec2.machine(instance.id=machine, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)
    ec2.machine.id.vec <- NULL
  }
}

#run(queue=queue, max.nodes=max.nodes, ami.id=ami.id,
#    ec2.instance.type=ec2.instance.type,
#    aws.availability.zone=aws.availability.zone,
#    path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
#    allowable.time=allowable.time, aws.account=aws.account,
#    user.data.file=user.data.file)
