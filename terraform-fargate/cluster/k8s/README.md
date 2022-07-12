### [AWS alb ingress controller]
------
1. 생성 작업
    > IAM OIDC 공급자 생성
    ```
    eksctl utils associate-iam-oidc-provider \
    --region ap-northeast-2 \
    --cluster webapps-dev-cluster \
    --approve
    ```
    > AWS 로드 밸런서 컨트롤러에 대한 IAM 정책 다운로드
    ```
    curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json
    ```
    > AWSLoadBalancerControllerIAMPolicy라는 IAM 정책 생성 (반환된 정책 ARN을 기록)
    ```
    aws iam create-policy \
    --policy-name IngressControllerIAMPolicy \
    --policy-document file://iam-policy.json
    ```
    > AWS Load Balancer 컨트롤러에 대한 IAM 역할 및 ServiceAccount를 생성하고 위 단계의 ARN을 사용
    ```
    eksctl create iamserviceaccount \
    --cluster=webapps-dev-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::160270626841:policy/IngressControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --approve
    ```
    > helm에 EKS 차트 리포지토리 추가
    ```
    helm repo add eks https://aws.github.io/eks-charts
    ```
    > helm upgrade를 통해 차트를 업그레이드하는 경우 TargetGroupBinding CRD를 설치
    ```
    kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
    ```
    > 서비스 계정에 IAM 역할을 사용하는 경우 helm 차트를 설치
    ```
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=webapps-dev-cluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
    ```
2. 제거 작업
    > AWS alb ingress controller 삭제
    ```
    helm uninstall aws-load-balancer-controller
    -n kube-system \
    --set clusterName=webapps-dev-cluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
    ```
    > TargetGroupBinding CRD 삭제
    ```
    kubectl delete -k github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master
    ```
    > helm에 EKS 차트 리포지토리 제거
    ```
    helm repo add eks https://aws.github.io/eks-charts
    ```
    > ServiceAccount 삭제
    ```
    eksctl delete iamserviceaccount \
    --cluster webapps-dev-cluster \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --wait
    ```
    > AWSLoadBalancerControllerIAMPolicy 삭제
    ```
    aws iam delete-policy --policy-arn arn:aws:iam::160270626841:policy/IngressControllerIAMPolicy
    ```