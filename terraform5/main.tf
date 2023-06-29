data "aws_ecr_repository" "my_first_ecr_repo" {
  name = "angulartest"
}

data "aws_ecs_cluster" "my_cluster" {
  cluster_name = "PayrollCluster" # Naming the cluster
}

data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = ["VPC - vpc"]
  }
}

data "aws_security_group" "service_security_group" {
 name = "cluster-payroll-ContainerSecurityGroup-1KG5G77LBR3JC"
}

resource "aws_lb_target_group" "target_group" {
  name        = "tg-appTest"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      =  data.aws_vpc.selected.id #"${aws_default_vpc.default_vpc.id}" # Referencing the default VPC
  health_check {
      healthy_threshold   = var.health_check["healthy_threshold"]
      interval            = var.health_check["interval"]
      unhealthy_threshold = var.health_check["unhealthy_threshold"]
      timeout             = var.health_check["timeout"]
      path                = var.health_check["path"]
      port                = var.health_check["port"]
  }
}

resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "${data.aws_ecr_repository.my_first_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "arn:aws:iam::746662389335:role/ecsTaskExecutionRole"
}


resource "aws_ecs_service" "my_first_service" {
  name            = "AppTest-service"                             # Naming our first service
  cluster         = "${data.aws_ecs_cluster.my_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.my_first_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Setting the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.my_first_task.family}"
    container_port   = 80 # Specifying the container port
  }

  network_configuration {
    subnets          =  ["subnet-083a90b145f64470e", "subnet-0b413521f153c850f"] #["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${data.aws_security_group.service_security_group.id}"] # Setting the security group
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:us-east-1:746662389335:listener/app/lb-payroll/7ef3339f2371e69c/b59b3f15713cb75f"
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }

  condition {
    path_pattern {
      values = ["/test/*"]
    }
  }
}



