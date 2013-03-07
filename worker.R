
# this file is the script that will run on the worker nodes

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
