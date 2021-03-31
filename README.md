# =fargater=
🚀 Run batch/migration jobs in your VPC using Fargate

## Motivation
Many a times we need to run some kind of a remote job in our VPC, e.g. a batch job or a database migration script. 
The problem is your CI/CD pipeline is perhaps executed in another cloud or AWS account and you don't want to bother with exposing your RDS instance to the public or run CI workers inside your VPC (Bitbucket Pipelines does not even have this option).

There are 2 ways how you can achieve this:
* AWS Lambda
* AWS ECS (Fargate)

If you are not keen on writing any Python code, perhaps you're a bash super hero, then why bother with AWS Lambda, right? AWS ECS to the rescue!

## Usage
Prerequisites: edit ``docker/Dockerfile`` according to your needs.

```bash
$ terraform init
$ terraform apply -auto-approve

$ ./publish-docker-image.sh
$ ./run-ecs-task.sh
```

Terraform will create the necessary infrastructure: VPC, Subnets, Internet and NAT GWs, ECR repo, Fargate cluster, IAM roles/policies, etc. And the following files:
1. ``overrides.json`` (here you can override the ``command`` when your container is started)
1. ``publish-docker-image.sh`` (will build and publish your Docker image to ECR)
3. ``run-ecs-task.sh`` (will run an ECS task on Fargate and display the output)

```
$ ./run-ecs-task.sh
Wed Mar 31 10:56:36 UTC 2021 	 ##################################
Wed Mar 31 10:56:36 UTC 2021 	 # Run task on Fargate
Wed Mar 31 10:56:36 UTC 2021 	 ##################################
Wed Mar 31 10:56:38 UTC 2021 	 Task Arn: arn:aws:ecs:eu-central-1:xxxxxxxxxxxxxxxx:task/fargater-dev/92b3b653d99b451c8de7f10fe00e0f96
Wed Mar 31 10:56:38 UTC 2021 	 Task id: 92b3b653d99b451c8de7f10fe00e0f96
Wed Mar 31 10:56:38 UTC 2021 	 Waiting until the task is complete...
Wed Mar 31 10:57:36 UTC 2021 	 ##################################
Wed Mar 31 10:57:36 UTC 2021 	 # Display container logs
Wed Mar 31 10:57:36 UTC 2021 	 ##################################
total 68
drwxr-xr-x    1 root     root          4096 Mar 31 10:56 .
drwxr-xr-x    1 root     root          4096 Mar 31 10:56 ..
drwxr-xr-x    2 root     root          4096 Mar 30 10:51 app
drwxr-xr-x    1 root     root          4096 Mar 30 10:51 bin
drwxr-xr-x    5 root     root           340 Mar 31 10:56 dev
drwxr-xr-x    1 root     root          4096 Mar 31 10:56 etc
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 home
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 lib
drwxr-xr-x    5 root     root          4096 Mar 25 16:57 media
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 mnt
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 opt
dr-xr-xr-x  103 root     root             0 Mar 31 10:56 proc
drwx------    2 root     root          4096 Mar 25 16:57 root
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 run
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 sbin
drwxr-xr-x    2 root     root          4096 Mar 25 16:57 srv
dr-xr-xr-x   13 root     root             0 Mar 31 10:56 sys
drwxrwxrwt    2 root     root          4096 Mar 25 16:57 tmp
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 usr
drwxr-xr-x    1 root     root          4096 Mar 25 16:57 var
Wed Mar 31 10:57:36 UTC 2021
Wed Mar 31 10:57:36 UTC 2021 	 OK
```
