
# this script contains helper functions used by both the controller and
# the worker nodes / scripts

start.ec2.machine <- function(ami.id, ec2.instance.type, aws.availability.zone,
                              user.data.file="", path.to.ec2.shell.scripts){
  run.string <- paste0("./", path.to.ec2.shell.scripts,
                            "/aws run-instances --simple ", ami.id,
                            " -instance-type ", ec2.instance.type,
                            " -availability-zone ", aws.availability.zone)
  if(user.data.file != ""){
    run.string <- paste0(run.string, " -user.data.file ", user.data.file)
  }
  response <- system(run.string, intern=T)
  response.list <- strsplit(response, "\t")[[1]]
  instance.id <- response.list[1]
  return(instance.id)
} # instance.id <- start.ec2.machine(ami.id=ami.id, ec2.instance.type=ec2.instance.type, aws.availability.zone=aws.availability.zone, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)

#instance.id <- "i-e487bc9"
stop.ec2.machine <- function(instance.id, path.to.ec2.shell.scripts){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws terminate-instances --xml ", instance.id), intern=T)
  response <- paste0(response, collapse="")
  ret.val <- ifelse(sum(grepl("Error", response))>0, response, "success")
  return(ret.val)
} # stop.ec2.machine(instance.id=instance.id, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)
 
read.message.from.queue <- function(path.to.ec2.shell.scripts,
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
} # read.message.from.queue(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts, aws.account=aws.account, queue=queue)

get.instance.id <- function(){
  # this returns the instance id from within a running ec2 instance
  instance.id <- system("wget -q -O - http://169.254.169.254/latest/meta-data/instance-id",
                        intern=T)
  return(instance.id)
}

#message.json <- '{"messageID":3,"message":"test from R"}'
write.message.to.queue <- function(message.json, path.to.ec2.shell.scripts,
                                aws.account=aws.account, queue=queue){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws send-message /", aws.account, "/", queue,
                             " --simple -message ", message.json), intern=T)
  messageid <- substring(response, regexpr("\t", response)[1]+1, nchar(response))
  return(messageid)
} # write.message.to.queue(message.json, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts, aws.account=aws.account, queue=queue)

#read.message.list <- read.message.from.queue(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,aws.account=aws.account, queue=queue)
#receipt.handle <- read.message.list$receipt.handle
delete.message.from.queue <- function(receipt.handle){
  response <- system(paste0("cd ", path.to.ec2.shell.scripts,
                            " && ./aws delete-message /", aws.account, "/", queue,
                             " --simple --handle ",receipt.handle), intern=T)
  ret.val <- ifelse(sum(grepl("ReceiptHandleIsInvalid", response)) > 0, "ReceiptHandleIsInvalid", "success")
  return(ret.val)
} # delete.message.from.queue(receipt.handle)

get.queue.length <- function(path.to.ec2.shell.scripts,
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
} # get.queue.length(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,aws.account=aws.account, queue=queue)

write.message.log.to.dynamo <- function(path.to.ec2.shell.scripts, table.name, instance.id, messageid){
  # every time a message is successfully completed, log it in dynamodb with the
  # instanceid as the hash, the sys.time as the range, and messageid as data
  time.pretty <- Sys.time()
  time.int <- round(unclass(time.pretty))
  ret.val <- system(paste0("python ", path.to.ec2.shell.scripts,
                           "/write_to_dynamo.py \'", table.name, "\' \'", messageid,
                           "\' \'", instance.id, "\' \'", time.pretty, "\' ", time.int),
                    intern=T)
  return(ret.val)
} # write.message.log.to.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,table.name="cory_test", instance.id="instanceid2", messageid="messageid1")

read.message.log.from.dynamo <- function(path.to.ec2.shell.scripts, table.name, instance.id){
  # read the most recent message for a given machine.id
  ret.val <- system(paste0("python ", path.to.ec2.shell.scripts,
                           "/read_from_dynamo.py \'", table.name,
                           "\' \'", instance.id, "\'"),
                    intern=T)
  return(ret.val)
} # read.message.log.from.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,table.name="cory_test", instance.id="instanceid2")

write.output.to.dynamo <- function(path.to.ec2.shell.scripts, table.name, instance.id, message.body, output){
  # every time a message is successfully completed, log it in dynamodb with the
  # instanceid as the hash, the sys.time as the range, and messageid as data
  time.pretty <- Sys.time()
  time.int <- round(unclass(time.pretty))
  ret.val <- system(paste0("python ", path.to.ec2.shell.scripts,
                           "/write_output_to_dynamo.py \'", table.name, "\' \'",
                           message.body, "\' \'", output, "\' \'", instance.id,
                           "\' \'", time.pretty, "\' ", time.int), intern=T)
  return(ret.val)
} # write.output.to.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,table.name="cory_output_test", instance.id="instanceid2", message.body="{sample tweet here :)}", output="1")
