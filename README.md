# fargater
Run batch/migration jobs in your VPC using Fargate

## Motivation
Many a times we need to run some kind of a remote job in our VPC, e.g. a batch job or a database migration script. 
The problem is your CI/CD pipeline is perhaps executed in another cloud or AWS account and you don't want to bother with exposing your RDS instance to the public or run CI workers in your VPC (Bitbucket Pipelines does not even have this option).
There are 2 ways how you can achieve this:
* AWS Lambda
* AWS ECS (Fargate)

If you are not keen on writing any Python code, perhaps you're a bash super hero, then why bother with AWS Lambda, right? AWS ECS to the rescue!

## Usage
```bash
# 1. Edit the Dockerfile according to your needs
# 2. Terraform init/plan/apply

$ ./publish-docker-image.sh
$ ./run-ecs-task.sh
```

Terraform will create the necessary infrastructure: VPC, Subnets, Internet and NAT GWs, ECR repo, Fargate cluster, IAM roles/policies, etc. And the following files:
1. ``overrides.json`` (here you can override the command Docker will execute when the container is started)
1. ``publish-docker-image.sh`` (builds and publishes your Docker image to ECR)
3. ``run-ecs-task.sh`` (runs the ecs task on Fargate and displays the output)

```bash
$ ./run-ecs-task.sh
Wed Mar 31 10:50:37 UTC 2021 	 ##################################
Wed Mar 31 10:50:37 UTC 2021 	 # Run task on Fargate
Wed Mar 31 10:50:37 UTC 2021 	 ##################################
Wed Mar 31 10:50:38 UTC 2021 	 Task Arn: arn:aws:ecs:eu-central-1:xxxxxxxxxxxx:task/fargater-dev/1ca9bb1eb12a4bfda0080dd4ab9bbf4e
Wed Mar 31 10:50:38 UTC 2021 	 Task id: 1ca9bb1eb12a4bfda0080dd4ab9bbf4e
Wed Mar 31 10:50:38 UTC 2021 	 Waiting until the task is complete...
Wed Mar 31 10:51:54 UTC 2021 	 ##################################
Wed Mar 31 10:51:54 UTC 2021 	 # Display container logs
Wed Mar 31 10:51:54 UTC 2021 	 ##################################
total 68
drwxr-xr-x    1 root     root          4096 Mar 31 10:51 .
drwxr-xr-x    1 root     root          4096 Mar 31 10:51 ..
drwxr-xr-x    2 root     root          4096 Mar 30 10:51 app
drwxr-xr-x    1 root     root          4096 Mar 30 10:51 bin
drwxr-xr-x    5 root     root           340 Mar 31 10:51 dev
drwxr-xr-x    1 root     root          4096 Mar 31 10:51 etc
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 home
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 lib
drwxr-xr-x    5 root     root          4096 Mar 25 16:57 media
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 mnt
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 opt
dr-xr-xr-x  106 root     root             0 Mar 31 10:51 proc
drwx------    2 root     root          4096 Mar 25 16:57 root
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 run
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 sbin
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 srv
dr-xr-xr-x   13 root     root             0 Mar 31 10:51 sys
drwxrwxrwt    2 root     root          4096 Mar 25 16:57 tmp
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 usr
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 var
```
