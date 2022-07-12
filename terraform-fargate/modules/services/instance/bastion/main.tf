###################################################################################
# IAM Role :: Bastion Host
###################################################################################
# ec2 assume role policy document
data "aws_iam_policy_document" "bastion" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

# IAM Role
resource "aws_iam_role" "bastion" {
    name = format("%s-%s", var.svr_name, "bastion")
    assume_role_policy = data.aws_iam_policy_document.bastion.json
}

# IAM Role에 Policy를 추가
resource "aws_iam_role_policy_attachment" "bastion_AmazonEC2RoleforSSM" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    role = aws_iam_role.bastion.name
}

# IAM Role에 Policy를 추가
resource "aws_iam_role_policy_attachment" "bastion_AmazonSSMManagedInstanceCore" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    role = aws_iam_role.bastion.name
}

# IAM profile
resource "aws_iam_instance_profile" "bastion" {
    name = format("%s-%s", var.svr_name, "bastion")
    role = aws_iam_role.bastion.name
}

###################################################################################
# Bastion Host
###################################################################################
resource "aws_instance" "bastion" {
    ami = var.ami
    instance_type = var.instance_type
    iam_instance_profile = aws_iam_instance_profile.bastion.name

    count = length(var.public_subnet_ids)
    subnet_id = element(var.public_subnet_ids, count.index)
    key_name = aws_key_pair.bastion.key_name
    vpc_security_group_ids = [var.bastion_security_group_id]

    tags = {
        Name = format("%s-%s", var.svr_name, "bastion${count.index+1}")
        Environments = var.environments
    }

    # SSM::System Management 설치
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = tls_private_key.bastion.private_key_pem
        timeout = "2m"
    }

    provisioner "remote-exec" {
        inline = [
            "cd /tmp",
            "sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm",
            "sudo systemctl enable amazon-ssm-agent",
            "sudo systemctl start amazon-ssm-agent",
            "sudo amazon-linux-extras install -y postgresql11"
        ]
    }
}

###################################################################################
# TLS Private key
###################################################################################
resource "tls_private_key" "bastion" {
    algorithm = "RSA"
    rsa_bits = 4096
}

###################################################################################
# AWS KEY PAIR
###################################################################################
resource "aws_key_pair" "bastion" {
    key_name = "bastion_ssh_key"
    public_key = tls_private_key.bastion.public_key_openssh
}

# local key file
resource "local_file" "bastion" {
    depends_on = [tls_private_key.bastion]
    content = tls_private_key.bastion.private_key_pem
    filename = "../../../webapps.pem"
}