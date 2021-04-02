# =fargater=
🚀 Run batch/migration jobs in your VPC using Fargate

## Motivation
Many a times we need to run some kind of a remote job in our VPC, e.g. a batch job or a database migration script. 
The problem is your CI/CD pipeline is perhaps executed in another cloud or AWS account and you don't want to bother with exposing your RDS instance to the public or run CI workers inside your VPC (Bitbucket Pipelines does not even have this option).

There are 2 ways how you can achieve this:
* AWS Lambda
* AWS ECS (Fargate)

If you are not keen on writing any Python code, perhaps you're a bash superhero, then why bother with AWS Lambda, right? AWS ECS to the rescue!

## Usage
Prerequisites: edit ``docker/run.sh`` according to your needs:
```bash
$ cat docker/run.sh
#!/bin/bash

env
pwd
ls -la
```

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
AWS_EXECUTION_ENV=AWS_ECS_FARGATE
AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=/v2/credentials/9db34f47-2a1b-4ce0-bcb5-91b765b65139
HOSTNAME=22dbe105954f4e2b88815630bc71e275-71576537
AWS_DEFAULT_REGION=eu-central-1
AWS_REGION=eu-central-1
PWD=/app
ECS_CONTAINER_METADATA_URI_V4=http://169.254.170.2/v4/22dbe105954f4e2b88815630bc71e275-71576537
FOO=BAR
HOME=/root
ECS_CONTAINER_METADATA_URI=http://169.254.170.2/v3/22dbe105954f4e2b88815630bc71e275-71576537
SHLVL=1
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
_=/usr/bin/env
/app
total 12
drwxr-xr-x    1 root     root          4096 Apr  1 09:49 .
drwxr-xr-x    1 root     root          4096 Apr  1 09:49 ..
-rwxr-xr-x    1 root     root            27 Apr  1 09:46 run.sh
Wed Mar 31 10:57:36 UTC 2021
Wed Mar 31 10:57:36 UTC 2021 	 OK
```
