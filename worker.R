
# this file is the script that will run on the worker nodes

# load the default file, then the local if it exists. The local one
# will override some / all of the default parameters
if(file.exists("config/config_default.R")){source("config_default.R")}
if(file.exists("config/config_local.R")){source("config_local.R")}
source("helper.R")

count.smileys <- function(text){
  if(mode(text)!="character"){
    ret <- "need character input"
  }else{
    reg <- gregexpr(":)", text)
    count <- length(reg[reg!=-1])
    ret <- count
  }
  return(ret)
}

my.instance.id <- get.instance.id()

run <- function(queue, path.to.ec2.shell.scripts, log.table.name,
                output.table.name, instance.id, aws.account){
  while(TRUE){
    # read task from queue, includes body, receipt.handle, messageid
    message.list <- read.message.from.queue(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                            aws.account=aws.account, queue=queue)
    if(is.list(message.list)){
      message.list$message.body <- gsub("!", "", message.list$message.body)
      message.list$message.body <- gsub("'", "", message.list$message.body)
      message.list$message.body <- gsub('"', "", message.list$message.body)
      text <- message.list$message.body
    }else{
      # queue is probably empty
      stop("queue is probably empty")
    }      
    # do something with it
    smiley.count <- count.smileys(text)
    if(mode(smiley.count)=="numeric"){
      # write output somewhere...
      print("writing output to dynamo")
      write.return <- write.output.to.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                           table.name=output.table.name,
                           instance.id=instance.id,
                           message.body=message.list$message.body,
                           output=smiley.count)
      if(is.null(attr(write.return, "status"))){
        # if success (null status), delete from queue
        print("deleting message from queue")
        delete.message.from.queue(message.list$receipt.handle,
                                  path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                  aws.account=aws.account, queue=queue)
        # if success, write time to dynamo
        print("writing log to dynamo")
        write.message.log.to.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                 table.name=log.table.name,
                                 instance.id=instance.id,
                                 message.list$messageid)
      }
    }
  }
}

run(queue=my.queue, path.to.ec2.shell.scripts=my.path.to.ec2.shell.scripts,
    log.table.name=my.log.table.name, output.table.name=my.output.table.name,
    instance.id=my.instance.id, aws.account=my.aws.account)
