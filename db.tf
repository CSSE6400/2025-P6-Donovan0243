# -------------------------------
# 📦 RDS 实例（PostgreSQL 数据库）
# -------------------------------
resource "aws_db_instance" "taskoverflow_database" {
  allocated_storage      = 20                      # 初始存储空间（单位 GB）
  max_allocated_storage  = 1000                    # 最大可扩展存储空间
  engine                 = "postgres"              # 数据库类型
  engine_version         = "14"                    # 数据库版本
  instance_class         = "db.t4g.micro"          # 数据库实例规格（适合测试用途）
  db_name                = "taskoverflow"          # 数据库名称
  username               = local.database_username # 数据库用户名（从 local 变量读取）
  password               = local.database_password # 数据库密码（从 local 变量读取）
  parameter_group_name   = "default.postgres14"    # 使用默认参数组
  skip_final_snapshot    = true                    # 删除数据库时不保留快照（方便测试）
  vpc_security_group_ids = [aws_security_group.taskoverflow_database.id]  # 绑定的安全组
  publicly_accessible    = true                    # 数据库是否可公网访问（这里设为 true）

  tags = {
    Name = "taskoverflow_database"                 # 打个标记，方便识别
  }
}

# -------------------------------
# 🔐 数据库安全组（Security Group）
# -------------------------------
resource "aws_security_group" "taskoverflow_database" {
  name        = "taskoverflow_database"            # 安全组名称
  description = "Allow inbound Postgres traffic"   # 描述：允许 PostgreSQL 访问

  ingress {
    from_port        = 5432                        # 允许进入的端口（Postgres 默认端口）
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]               # 所有人都能访问（仅用于测试环境）
  }

  egress {
    from_port        = 0                           # 所有出站请求都允许
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "taskoverflow_db_security_group"        # 安全组打个名字标签
  }
}