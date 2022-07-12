- rolearn: ${rolearn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
	- system:bootstrappers
	- system:nodes
- rolearn: ${userarn}
  username: kubectl-access-user
  groups:
	- system:masters