### [EKS Cluster]]
1. cluster 생성
    ```
	eksctl create cluster
	--vpc-public-subnets subnet-00fd5b8b21f559e19,subnet-0598fc9790c5687ed
	--name webapps-stage-cluster
	--region ap-northeast-2
	--version 1.19
	--nodegroup-name webapps-stage-nodegroup
	--node-type t2.micro
	--nodes 2
	--nodes-min 2
	--nodes-max 5
    ```
2. 컨텍스트 생성/확인
    ```
	$ kubectl config get-contexts
	$ kubectl get nodes
    ```
3. EKS 클러스터 동작 확인
    ```
	$ kubectl apply -f nginx.yaml
		--------------------------------
		apiVersion: v1
		kind: Pod
		metadata:
		  name: nginx-pod
		  labels:
			app: nginx-app
		spec:
		  containers:
		  - name: nginx-container
			image: nginx
			ports:
			- containerPort: 80
		--------------------------------
	$ kubectl get pods

	$ kubectl port-forward nginx-pod 8080:80
	브라우저로 접속 확인 : http://localhost:8080
	
	확인 후, nginx 삭제
	$ kubectl delete pod nginx-pod
    ```
4. Bastion Host 설치 (Git & postgresql client)
    ```
	$ sudo yum install -y git
	$ sudo amazon-linux-extras install -y postgresql11
	> db 일반사용자 생성
	$ createuser -d -U appadmin -P -h <RDS endpoint> appuser
		Enter password for new role: <appuser의 신규 비밀번호>
		Enter it again: <appuser의 신규 비밀번호>
		Password: <appadmin의 비밀번호>
	> 데이터베이스 생성
	$ createdb -U appuser -h <RDS endpoint> -E UTF8 webappsdb
	> 데이터베이스 접속 (dbeaver 사용 - RDS SSH tunnel)
	$ psql -U appuser -h <RDS endpoint> webappsdb
	webappsdb=> ddl문 실행
	webappsdb=> insert문 실행
	webappsdb=> \q
    ```
5. 애플리케이션 빌드
	> gradle 빌드
    ```
	$ cd k8s-aws-book/backend-app
	$ sudo chmod 755 ./gradlew
	$ ./gradlew clean build
	build/lib/backend-app-1.0.0.jar 파일 생성됨
	```
	> 컨테이너 이미지 생성
    ```
	$ sudo docker build -t webapps-dev/backend-app:1.0.0 --build-arg \
	> JAR_FILE=build/libs/backend-app-1.0.0.jar .
	
	---> /usr/bin/env ‘sh r’ no such file or directory 오류가 발생하면
	$ sed -i 's/\r$//' ./gradlew
	```
	> docker image 확인
    ```
	$ docker image ls
	```
6. 컨테이너 레지스트리 (ECR)
	> ECR 로그인
    ```
	$ aws ecr get-login-password --region ap-northeast-2 | \
	pipe> docker login --username AWS --password-stdin \
	pipe> 160270626841.dkr.ecr.ap-northeast-2.amazonaws.com
	Login Succeeded
    ```
	> docker tag 명령 - 컨테이너 이미지에 태그 설정
    ```
	$ docker tag webapps-dev/backend-app:1.0.0 \
	> <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/webapps-dev-backend:1.0.0
    ```
	> 컨테이너 태그에 대해 docker push 실행
    ```
	$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/webapps-dev-backend:1.0.0
    ```
7. EKS 클러스터에 애플리케이션 배포
	> 네임스페이스 생성
    ```
	$ kubectl apply -f namespace.yaml
	--------------------------------------
	apiVersion: v1
	kind: Namespace
	metadata:
	name: webapps-dev
	--------------------------------------
    ```
	> 네임스페이스 활성화 변경
    ```
	$ kubectl config set-context webapps-dev --cluster <CLUSTER값> --user <AUTHINFO값> --namespace webapps-dev
	Context 'webapps-dev' created
	$ kubectl config use-context webapps-dev
	Switched to context "webapps-dev"
    ```
	> DB 접속용 시크릿 등록
    ```
	$ kubectl apply -f db_config.yaml
	----------------------------------------
	apiVersion: v1
	kind: Secret
	type: Opaque
	metadata:
	  name: db-config
	stringData:
	  db-url: webapps-dev-db.cfe0kcb9osrg.ap-northeast-2.rds.amazonaws.com
	  db-username: webappsdb
	  db-password: godhkekf
	----------------------------------------
    ```
	> API 애플리케이션 배포
    ```
	$ kubectl apply -f .\22_deployment_backend-app_k8s.yaml
    ```
	> 서비스 등록
    ```
	$ kubectl apply -f 23_service_backend-app_k8s.yaml
    ```
	> 서비스 확인
    ```
	$ curl -s http://<EXTERNAL-IP값>:80/health
	{"status":"OK"}
    ```
	> Front-end 배포
    ```
	$ npm install
	$ BASE_URL=http://<EXTERNAL_IP>:8080 npm run build
    ```
	> s3에 콘텐츠 업로드
    ```
	$ aws s3 syncdist s3://webapps-dev-frontend-<BucketSuffix값> \
	> --delete --include "*" --acl public-read
    ```
	> cloudfront 배포캐시 무효화
    ```
	$ aws cloudfront create-invalidation --distribution-id <DistributionID값> --paths "/*"
    ```