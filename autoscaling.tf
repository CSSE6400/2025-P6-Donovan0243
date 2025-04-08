# -------------------------------
# 📈 自动扩容目标设置（Auto Scaling Target）
# 告诉 AWS 这个 ECS 服务是可以自动扩容的
# -------------------------------
resource "aws_appautoscaling_target" "taskoverflow" {
  max_capacity       = 4                                   # 最多运行 4 个副本（任务数量）
  min_capacity       = 1                                   # 最少保持 1 个副本
  resource_id        = "service/taskoverflow/taskoverflow" # 固定格式：service/集群名/服务名
  scalable_dimension = "ecs:service:DesiredCount"          # 可扩容目标是：服务副本数量
  service_namespace  = "ecs"                               # 告诉 AWS 这是 ECS 服务

  depends_on = [ aws_ecs_service.taskoverflow ]            # 确保先创建 ECS 服务
}

# -------------------------------
# ⚙️ 自动扩容策略设置（Scaling Policy）
# 设置扩缩容规则（例如 CPU 超过 20% 就扩容）
# -------------------------------
resource "aws_appautoscaling_policy" "taskoverflow-cpu" {
  name               = "taskoverflow-cpu"                          # 策略名称
  policy_type        = "TargetTrackingScaling"                    # 使用目标追踪型策略
  resource_id        = aws_appautoscaling_target.taskoverflow.resource_id
  scalable_dimension = aws_appautoscaling_target.taskoverflow.scalable_dimension
  service_namespace  = aws_appautoscaling_target.taskoverflow.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"  # 使用 ECS 服务平均 CPU 作为指标
    }
    target_value = 20     # 目标 CPU 利用率为 20%
                          # >20% 就扩容，<20% 就缩容
  }
}