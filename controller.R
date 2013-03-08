
# this script will manage the starting / stopping of worker nodes.

# if local file exists, source it, otherwise source the default one.
config_file <- ifelse((file.exists("config/config_local.R")),
                      "config/config_local.R", "config/config_default.R")
source(config_file)

# this is the function that will be processing items from the queue
# it must be able to read from the queue to get a task, do the task,
# and write back to the queue indicating the task is done

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
