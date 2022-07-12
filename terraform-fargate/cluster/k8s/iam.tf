###################################################################################
# AWS Load Balancer Controller가 사용자를 대신하여 AWS API를 호출하도록 허용하는 정책
###################################################################################
data "aws_iam_policy_document" "api_call" {
    statement {
		effect = "Allow"
		actions = [
			"iam:CreateServiceLinkedRole",
			"ec2:DescribeAccountAttributes",
			"ec2:DescribeAddresses",
			"ec2:DescribeAvailabilityZones",
			"ec2:DescribeInternetGateways",
			"ec2:DescribeVpcs",
			"ec2:DescribeSubnets",
			"ec2:DescribeSecurityGroups",
			"ec2:DescribeInstances",
			"ec2:DescribeNetworkInterfaces",
			"ec2:DescribeTags",
			"ec2:GetCoipPoolUsage",
			"ec2:DescribeCoipPools",
			"elasticloadbalancing:DescribeLoadBalancers",
			"elasticloadbalancing:DescribeLoadBalancerAttributes",
			"elasticloadbalancing:DescribeListeners",
			"elasticloadbalancing:DescribeListenerCertificates",
			"elasticloadbalancing:DescribeSSLPolicies",
			"elasticloadbalancing:DescribeRules",
			"elasticloadbalancing:DescribeTargetGroups",
			"elasticloadbalancing:DescribeTargetGroupAttributes",
			"elasticloadbalancing:DescribeTargetHealth",
			"elasticloadbalancing:DescribeTags"
		]
		resources = ["*"]
	}
	
    statement {
		effect = "Allow"
		actions = [
			"cognito-idp:DescribeUserPoolClient",
			"acm:ListCertificates",
			"acm:DescribeCertificate",
			"iam:ListServerCertificates",
			"iam:GetServerCertificate",
			"waf-regional:GetWebACL",
			"waf-regional:GetWebACLForResource",
			"waf-regional:AssociateWebACL",
			"waf-regional:DisassociateWebACL",
			"wafv2:GetWebACL",
			"wafv2:GetWebACLForResource",
			"wafv2:AssociateWebACL",
			"wafv2:DisassociateWebACL",
			"shield:GetSubscriptionState",
			"shield:DescribeProtection",
			"shield:CreateProtection",
			"shield:DeleteProtection"
		]
		resources = ["*"]
	}
    
	statement {
		effect = "Allow"
		actions = [
			"ec2:AuthorizeSecurityGroupIngress",
			"ec2:RevokeSecurityGroupIngress"
		]
		resources = ["*"]
	}
	
	statement {
		effect = "Allow"
		actions = [
			"ec2:CreateSecurityGroup"
		]
		resources = ["*"]
	}

	statement {
		effect = "Allow"
		actions = [
			"ec2:CreateTags"
		]
		resources = ["arn:aws:ec2:*:*:security-group/*"]
		
		condition {
            test     = "StringEquals"
            variable = "ec2:CreateAction"

            values = [
                "CreateSecurityGroup"
            ]
        }
		
		condition {
            test     = "Null"
            variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"ec2:CreateTags",
			"ec2:DeleteTags"
		]
		resources = ["arn:aws:ec2:*:*:security-group/*"]
		
		condition {
            test     = "Null"
            variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

            values = [
                "true"
            ]
        }
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"ec2:AuthorizeSecurityGroupIngress",
			"ec2:RevokeSecurityGroupIngress",
			"ec2:DeleteSecurityGroup"
		]
		resources = ["*"]
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:CreateLoadBalancer",
			"elasticloadbalancing:CreateTargetGroup"
		]
		resources = ["*"]
		condition {
            test     = "Null"
            variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:CreateListener",
			"elasticloadbalancing:DeleteListener",
			"elasticloadbalancing:CreateRule",
			"elasticloadbalancing:DeleteRule"
		]
		resources = ["*"]
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:AddTags",
			"elasticloadbalancing:RemoveTags"
		]
		
		resources = [
			"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
			"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
			"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
		]
		
		condition {
            test     = "Null"
            variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

            values = [
                "true"
            ]
        }
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:AddTags",
			"elasticloadbalancing:RemoveTags"
		]
		
		resources = [
			"arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
			"arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
			"arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
			"arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
		]
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:ModifyLoadBalancerAttributes",
			"elasticloadbalancing:SetIpAddressType",
			"elasticloadbalancing:SetSecurityGroups",
			"elasticloadbalancing:SetSubnets",
			"elasticloadbalancing:DeleteLoadBalancer",
			"elasticloadbalancing:ModifyTargetGroup",
			"elasticloadbalancing:ModifyTargetGroupAttributes",
			"elasticloadbalancing:DeleteTargetGroup"
		]
		resources = ["*"]
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:RegisterTargets",
			"elasticloadbalancing:DeregisterTargets"
		]
		
		resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:SetWebAcl",
			"elasticloadbalancing:ModifyListener",
			"elasticloadbalancing:AddListenerCertificates",
			"elasticloadbalancing:RemoveListenerCertificates",
			"elasticloadbalancing:ModifyRule"
		]
		resources = ["*"]
	}
}

# 해당 정책을 이용하여 Policy 생성
resource "aws_iam_policy" "api_call" {
    name = "${local.cluster_name}-api-call"
    path = "/"
    policy = data.aws_iam_policy_document.api_call.json
}

###################################################################################
# IAM 정책 추가 ::
#   AWS 로드 밸런서 컨트롤러가 Kubernetes용 ALB 수신 컨트롤러에서 생성한 리소스에
#   대한 액세스를 허용
###################################################################################
data "aws_iam_policy_document" "api_access" {
    statement {
		effect = "Allow"
		actions = [
			"ec2:CreateTags",
			"ec2:DeleteTags"
		]
		resources = ["arn:aws:ec2:*:*:security-group/*"]
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/ingress.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
	
	statement {
		effect = "Allow"
		actions = [
			"elasticloadbalancing:AddTags",
			"elasticloadbalancing:RemoveTags",
			"elasticloadbalancing:DeleteTargetGroup"
		]
		resources = [
			"arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
			"arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
			"arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
		]
		condition {
            test     = "Null"
            variable = "aws:ResourceTag/ingress.k8s.aws/cluster"

            values = [
                "false"
            ]
        }
	}
}

# 해당 정책을 이용하여 Policy 생성
resource "aws_iam_policy" "api_access" {
    name = "${local.cluster_name}-api-access"
    path = "/"
    policy = data.aws_iam_policy_document.api_access.json
}

###################################################################################
# IAM 정책 추가 :: AssumeRoleWithWebIdentity
###################################################################################
# Role
data "aws_iam_policy_document" "assume" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]

        principals {
            type        = "Federated"
            identifiers = [var.oidc_arn]
        }

        condition {
            test     = "StringEquals"
            variable = "${replace(var.cluster_oidc_issuer, "https://", "")}:sub"

            values = [
                "system:serviceaccount:kube-system:aws-load-balancer-controller",
            ]
        }

        effect = "Allow"
    }
}

###################################################################################
# AWS IAM Role 생성
###################################################################################
resource "aws_iam_role" "controller_role" {
    name = "${local.cluster_name}-controller-role"
    assume_role_policy = data.aws_iam_policy_document.assume.json

    # depends_on = [
    #     kubernetes_namespace.webapps
    # ]
}

###################################################################################
# 생성된 IAM Role에 정책 Attachment
###################################################################################
# AWS API를 호출하도록 허용하는 정책 Attachment
resource "aws_iam_role_policy_attachment" "api_call" {
    role = aws_iam_role.controller_role.name
    policy_arn = aws_iam_policy.api_call.arn

    depends_on = [
        aws_iam_role.controller_role,
        aws_iam_policy.api_call
    ]
}

# ALB 수신 컨트롤러에서 생성한 리소스에 대한 액세스를 허용 정책 Attachment
resource "aws_iam_role_policy_attachment" "api_access" {
    role = aws_iam_role.controller_role.name
    policy_arn = aws_iam_policy.api_access.arn

    depends_on = [
        aws_iam_role.controller_role,
        aws_iam_policy.api_access
    ]
}
