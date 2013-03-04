EC2-clusteR
===========

This creates a cluster of EC2 instances. Each instances reads from a queue, does a task, logs the task, and goes on to the next one until the queue is empty.