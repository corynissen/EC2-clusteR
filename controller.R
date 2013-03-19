
# this script will manage the starting / stopping of worker nodes.
a <- try(library(RJSONIO), silent=T)
if(class(a)=="try-error"){
  install.packages("RJSONIO", repos="http://cran.mtu.edu/")
}

# load the default file, then the local if it exists. The local one
# will override some / all of the default parameters
if(file.exists("config/config_default.R")){source("config_default.R")}
if(file.exists("config/config_local.R")){source("config_local.R")}
source("helper.R")

# this is the function that will be processing items from the queue
# it must be able to read from the queue to get a task, do the task,
# and write back to the queue indicating the task is done

run <- function(queue, max.nodes, ami.id, ec2.instance.type, aws.availability.zone, path.to.ec2.shell.scripts, allowable.time, aws.account, user.data.file, ec2.key, ec2.security.group, log.table.name){
  # start machines
  # change to apply-ish function after working
  start.time <- unclass(Sys.time())
  instance.log <- data.frame(instance.id=c(), start.time=c(), stringsAsFactors=F)
  for(i in 1:max.nodes){
    print(paste("starting machine number", i, "of", max.nodes))
    new.instance.id <- start.ec2.machine(ami.id=ami.id,
                                 ec2.instance.type=ec2.instance.type,
                                 aws.availability.zone=aws.availability.zone,
                                 path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                 user.data.file=user.data.file, key=ec2.key,
                                 group=ec2.security.group)
    new.row <- data.frame(instance.id=new.instance.id,
                        start.time=unclass(Sys.time()), stringsAsFactors=F)
    instance.log <- rbind(instance.log, new.row)    
  }  
  
  # wait for a log to appear from the first machine...
  print("waiting 90 seconds for machines to boot and download packages...")
  Sys.sleep(90)
  print("looking for a log entry from first machine to appear in log...")
  wait.for.log <- TRUE
  while(wait.for.log){
    machine <- instance.log$instance.id[1]
    read.message.log.json <- read.message.log.from.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                    table.name=log.table.name, instance.id=machine)
    # amazon may return single quotes instead of required double quotes
    log.list <- fromJSON(gsub("'", '"', read.message.log.json))
    log.count <- log.list$Count
    if(log.count!=0){
      print("first machine is online!")
      boot.time <- round(unclass(Sys.time()) - start.time)
      print(paste0("it took ", boot.time, " seconds to boot the first machine"))
      wait.for.log <- FALSE
    }else{
      print("no log found, waiting another 10 seconds... ")
      Sys.sleep(10)
    }
  }

  ### monitoring
  # read the time of the most recently completed task for each machine
  # if the time difference from current time has been greater than
  # allowable.time, then kill the machine and if there are still items
  # left in the queue, start another machine
  while(nrow(instance.log) > 0){
    for(machine in instance.log$instance.id){
      read.message.log.json <- read.message.log.from.dynamo(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                    table.name=log.table.name, instance.id=machine)
      # amazon may return single quotes instead of required double quotes
      log.list <- fromJSON(gsub("'", '"', read.message.log.json))
      log.count <- log.list$Count
      if(log.count>0){
        last.message.time <- log.list$Items[[1]]$datetime
        over.time <- unclass(Sys.time()) - last.message.time > allowable.time
        if(over.time){
          print("a machine has not submitted a log in the allowable time, it's being shut down")
          stop.ec2.machine(instance.id=machine, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)
          # remove stopped machine from list
          instance.log <- instance.log[instance.log$instance.id!=machine,]
          # start new machine if there are still items left in queue
          queue.length <- get.queue.length(path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                         aws.account=aws.account, queue=queue)
          if(as.numeric(queue.length) > 10){
            print("a replacement machine is being booted")
            new.instance.id <- start.ec2.machine(ami.id=ami.id,
                                 ec2.instance.type=ec2.instance.type,
                                 aws.availability.zone=aws.availability.zone,
                                 path.to.ec2.shell.scripts=path.to.ec2.shell.scripts,
                                 user.data.file=user.data.file, key=ec2.key,
                                 group=ec2.security.group)
            new.row <- data.frame(instance.id=new.instance.id,
                                  start.time=unclass(Sys.time()), stringsAsFactors=F)
            instance.log <- rbind(instance.log, new.row)    
          }
        }
      }
    }
  }
  # Shouldn't need this as they should all be stopped already...
  # stop machines
  for(machine in instance.log$instance.id){
    stop.ec2.machine(instance.id=machine, path.to.ec2.shell.scripts=path.to.ec2.shell.scripts)
    ec2.machine.id.vec <- NULL
  }
}

run(queue=my.queue, max.nodes=my.max.nodes, ami.id=my.ami.id,
    ec2.instance.type=my.ec2.instance.type,
    aws.availability.zone=my.aws.availability.zone,
    path.to.ec2.shell.scripts=my.path.to.ec2.shell.scripts,
    allowable.time=my.allowable.time, aws.account=my.aws.account,
    user.data.file=my.user.data.file, ec2.key=my.ec2.key,
    ec2.security.group=my.ec2.security.group, log.table.name=my.log.table.name)
