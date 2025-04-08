# -------------------------------
# 🎯 Target Group（目标组）
# 定义容器服务运行在哪个端口，负载均衡器最终会把请求发给这些容器
# -------------------------------
resource "aws_lb_target_group" "taskoverflow" {
  name        = "taskoverflow"           # 目标组名称
  port        = 6400                     # ECS 容器监听的端口
  protocol    = "HTTP"                   # 通信协议
  vpc_id      = aws_security_group.taskoverflow.vpc_id  # 所在 VPC 网络（复用已有安全组绑定的 VPC）
  target_type = "ip"                     # Fargate 要用 "ip"，如果是 EC2 就用 "instance"

  # 健康检查配置（定期检查服务是否可用）
  health_check {
    path                = "/api/v1/health"    # 检查的接口路径
    port                = "6400"              # 检查的端口
    protocol            = "HTTP"
    healthy_threshold   = 2                   # 连续 2 次成功判定为“健康”
    unhealthy_threshold = 2                   # 连续 2 次失败判定为“不健康”
    timeout             = 5                   # 超过 5 秒未响应视为失败
    interval            = 10                  # 每 10 秒检查一次
  }
}

# -------------------------------
# 🌐 Load Balancer 本体
# 创建一个应用层负载均衡器（监听 HTTP 请求）
# -------------------------------
resource "aws_lb" "taskoverflow" {
  name               = "taskoverflow"            # LB 名称
  internal           = false                     # false 表示公网可访问
  load_balancer_type = "application"             # 应用层 LB（7 层，HTTP）
  subnets            = data.aws_subnets.private.ids    # 放在哪些子网中运行（和 ECS 容器一致）
  security_groups    = [aws_security_group.taskoverflow_lb.id]  # 使用的安全组（下面定义）
}

# -------------------------------
# 🔐 Load Balancer 的安全组（防火墙）
# 开放端口 80（HTTP）给公网访问
# -------------------------------
resource "aws_security_group" "taskoverflow_lb" {
  name        = "taskoverflow_lb"
  description = "TaskOverflow Load Balancer Security Group"

  ingress {
    from_port   = 80                 # 允许进入的端口范围（80）
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      # 所有人都能访问
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]      # 所有出站请求都允许（默认值）
  }

  tags = {
    Name = "taskoverflow_lb_security_group"
  }
}

# -------------------------------
# 🔊 Listener（监听器）
# 监听用户请求并转发到上面创建的目标组
# -------------------------------
resource "aws_lb_listener" "taskoverflow" {
  load_balancer_arn = aws_lb.taskoverflow.arn   # 绑定到哪个 LB 上
  port              = "80"                      # 监听端口（用户访问网站时）
  protocol          = "HTTP"

  default_action {
    type             = "forward"                # 动作类型：转发
    target_group_arn = aws_lb_target_group.taskoverflow.arn  # 转发目标：上面定义的目标组
  }
}

# -------------------------------
# 🌍 输出 Load Balancer 的 DNS 地址
# 部署完后可以通过这个地址访问你的服务
# -------------------------------
output "taskoverflow_dns_name" {
  value       = aws_lb.taskoverflow.dns_name
  description = "DNS name of the TaskOverflow load balancer."
}