# -------------------------------
# 📦 Terraform 配置模块
# 指定使用的 Provider（AWS）
# -------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"     # 使用官方 AWS Provider
      version = "~> 5.0"            # 兼容 5.x 版本
    }
  }
}

# -------------------------------
# ☁️ AWS Provider 配置
# 告诉 Terraform 如何连接 AWS 账户
# -------------------------------
provider "aws" {
  region = "us-east-1"                        # 使用的 AWS 区域（美国东部 1）
  shared_credentials_files = ["./credentials"]# 使用本地凭证文件登录 AWS

  # 为所有资源统一打上默认标签（非必须，但好处是便于管理）
  default_tags {
    tags = {
      Course       = "CSSE6400"              # 标记课程名称
      Name         = "TaskOverflow"          # 资源统一命名标识
      Automation   = "Terraform"             # 表明资源是用 Terraform 自动创建的
    }
  }
}

# -------------------------------
# 🧱 本地变量（locals）
# 这些值可以在多个地方复用
# -------------------------------
locals {
  image              = "ghcr.io/csse6400/taskoverflow:latest" # 使用的容器镜像（从 GitHub 拉取）
  database_username  = "administrator"                        # 数据库用户名
  database_password  = "VerySecurePassword123XYZ"             # 数据库密码（仅用于课程演示）
}

# -------------------------------
# 🔐 获取实验室默认的 IAM Role
# 给 ECS 服务授权访问 AWS 资源（如日志）
# -------------------------------
data "aws_iam_role" "lab" {
  name = "LabRole"  # Learner Lab 提供的预置角色，已有权限配置
}

# -------------------------------
# 🌐 获取默认的 VPC（虚拟网络）
# 所有资源将部署在这个网络下
# -------------------------------
data "aws_vpc" "default" {
  default = true    # 取默认 VPC（每个 AWS 账户区域都有一个）
}

# -------------------------------
# 🌐 获取该 VPC 中的所有子网（用于 ECS）
# 会自动获取所有 private 子网（实验室预配置好）
# -------------------------------
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"                       # 子网所属的 VPC 必须是上面定义的 default VPC
    values = [data.aws_vpc.default.id]
  }
}