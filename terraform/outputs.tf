output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "ecr_repository_url" {
  description = "URL of the Spark ECR repository"
  value       = aws_ecr_repository.spark.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}