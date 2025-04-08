# -------------------------------
# 📦 ECS 集群定义（容器的运行环境集合）
# -------------------------------
resource "aws_ecs_cluster" "taskoverflow" {
  name = "taskoverflow"  # 集群名称，所有容器服务会运行在这个集群中
}

# -------------------------------
# 📄 Task Definition（任务定义）
# 描述一个容器该怎么运行：镜像、端口、环境变量、资源需求等
# -------------------------------
resource "aws_ecs_task_definition" "taskoverflow" {
  family                   = "taskoverflow"         # 任务定义的名称
  network_mode             = "awsvpc"               # 每个容器使用自己的私有 IP
  requires_compatibilities = ["FARGATE"]            # 指定运行在 AWS Fargate（免管理 VM）
  cpu                      = 1024                   # 分配给容器的 CPU 单位（1024 = 1 vCPU）
  memory                   = 2048                   # 分配内存（单位 MB）
  execution_role_arn       = data.aws_iam_role.lab.arn  # 执行容器所需的权限角色

  # 容器配置（用 JSON 写法）
  container_definitions = <<DEFINITION
[
  {
    "image": "${local.image}",
    "cpu": 1024,
    "memory": 2048,
    "name": "taskoverflow",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 6400,
        "hostPort": 6400
      }
    ],
    "environment": [
      {
        "name": "SQLALCHEMY_DATABASE_URI",
        "value": "postgresql://${local.database_username}:${local.database_password}@${aws_db_instance.taskoverflow_database.address}:${aws_db_instance.taskoverflow_database.port}/${aws_db_instance.taskoverflow_database.db_name}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/taskoverflow/db",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs",
        "awslogs-create-group": "true"
      }
    }
  }
]
DEFINITION
}

# -------------------------------
# 🚀 ECS 服务（实际运行容器的地方）
# 启动任务定义，并绑定网络和负载均衡器
# -------------------------------
resource "aws_ecs_service" "taskoverflow" {
  name            = "taskoverflow"                               # 服务名称
  cluster         = aws_ecs_cluster.taskoverflow.id             # 所在集群
  task_definition = aws_ecs_task_definition.taskoverflow.arn   # 使用的任务定义
  desired_count   = 1                                           # 启动的容器副本数（初始为 1）
  launch_type     = "FARGATE"                                   # 使用 Fargate 模式运行

  network_configuration {
    subnets             = data.aws_subnets.private.ids          # 容器运行在哪些子网中
    security_groups     = [aws_security_group.taskoverflow.id]  # 绑定容器用的安全组
    assign_public_ip    = true                                  # 是否分配公网 IP（这里设为 true）
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.taskoverflow.arn     # 绑定目标组（LB 转发用）
    container_name   = "taskoverflow"                           # 容器名称
    container_port   = 6400                                     # 对应的容器端口
  }
}

# -------------------------------
# 🔐 容器服务的安全组（Security Group）
# 控制哪些端口可以访问容器
# -------------------------------
resource "aws_security_group" "taskoverflow" {
  name        = "taskoverflow"
  description = "TaskOverflow Security Group"

  ingress {
    from_port   = 6400                   # 开放端口 6400（Flask 应用）
    to_port     = 6400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]          # 允许所有外部访问（仅适用于测试环境）
  }

  ingress {
    from_port   = 22                     # 开放 SSH（课程实验用）
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]          # 所有人都能连（实验方便用，生产环境慎用）
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]          # 所有出站请求都允许
  }

  tags = {
    Name = "taskoverflow_security_group"
  }
}