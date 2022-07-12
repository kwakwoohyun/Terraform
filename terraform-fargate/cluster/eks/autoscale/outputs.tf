###################################################################################
# EKS Cluster Output
###################################################################################
# Cluster name
output "cluster_name" {
    value = aws_eks_cluster.cluster.name
}

# EKS cluster endpoint
output "endpoint" {
    value = aws_eks_cluster.cluster.endpoint
}

# EKS cluster에 대한 속성 block 값
output "kubeconfig-certificate-authority-data" {
    value = aws_eks_cluster.cluster.certificate_authority[0].data
}
