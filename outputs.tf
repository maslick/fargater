output "region" {
  value = data.aws_region.current.id
}

output "accountId" {
  value = data.aws_caller_identity.current.account_id
}

output "cluster" {
  description = "cluster arn"
  value = aws_ecs_cluster.fargate.arn
}

output "task_definition" {
  description = "task definition arn"
  value = aws_ecs_task_definition.fargate.arn
}

output "ecr_image" {
  value = aws_ecr_repository.registry.repository_url
}

resource "local_file" "overrides" {
  filename = "overrides.json"
  file_permission = "0755"
  content = <<-EOT
{
  "containerOverrides": [{
    "name": "${var.app_name}-${var.env}-container",
    "command": ["pwd"]
  }]
}
EOT
}

resource "local_file" "publish-docker-image" {
  filename = "publish-docker-image.sh"
  file_permission = "0755"
  content = <<-EOT
#!/bin/bash

function logger() {
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e $RED$(date -u)$NC "\t" "$1"
}

logger "##################################"
logger "# Build and Publish docker image"
logger "##################################"

ECR=${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${aws_ecr_repository.registry.name}
IMAGE_NAME=${aws_ecr_repository.registry.repository_url}

logger "IMAGE: $IMAGE_NAME"

aws ecr get-login-password --region ${data.aws_region.current.id} | docker login --username AWS --password-stdin $ECR

if DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect "$IMAGE_NAME:latest" >/dev/null; then
  docker pull $IMAGE_NAME:latest
  docker build -t tempimage ./docker/ -f docker/Dockerfile --cache-from "$IMAGE_NAME"
else
  docker build -t tempimage ./docker/ -f docker/Dockerfile
fi

docker tag tempimage $IMAGE_NAME
docker push $IMAGE_NAME
EOT
}

resource "local_file" "run-ecs-task" {
  filename = "run-ecs-task.sh"
  file_permission = "0755"
  content = <<-EOT
#!/bin/bash

function logger() {
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e $RED$(date -u)$NC "\t" "$1"
}

logger "##################################"
logger "# Run task on Fargate"
logger "##################################"

TASK_ARN=$(aws ecs run-task \
  --cluster "${aws_ecs_cluster.fargate.arn}" \
  --task-definition "${aws_ecs_task_definition.fargate.arn}" \
  --launch-type FARGATE \
  --platform-version 1.4.0 \
  --overrides "file://overrides.json" \
  --network-configuration 'awsvpcConfiguration={subnets=${jsonencode(module.vpc.private_subnets)},securityGroups=[${jsonencode(aws_security_group.fargate_ecs.id)}]}' \
  --query 'tasks[0].taskArn' \
  --output text)
TASK_ID=$(basename $TASK_ARN)

logger "Task Arn: $TASK_ARN"
logger "Task id: $TASK_ID"

logger "Waiting until the task is complete..."
aws ecs wait tasks-stopped --cluster "${aws_ecs_cluster.fargate.arn}" --tasks $TASK_ARN

logger "##################################"
logger "# Display container logs"
logger "##################################"

log_group="${aws_cloudwatch_log_group.fargate.name}"
log_stream="fargate/${var.app_name}-${var.env}-container/$TASK_ID"
AWS_PAGER="" aws logs get-log-events --log-group-name "$log_group" --log-stream-name "$log_stream" --output text --query 'events[*].[message]'

EOT
}

output "VPC" {
  value = {
    vpc: module.vpc.vpc_id
    nat: module.vpc.natgw_ids[0]
    privateNetworks: module.vpc.private_subnets
    publicNetworks: module.vpc.public_subnets
  }
}