# Guestbook - Run with Kubectl

### Requirements:
- Minikube
- Kubectl
- Enable Ingress addon in Minikube with: 
```sh
$ minikube addons enable ingress
```

### Running staic front end applicaiton as v 1.0:
Version 1.0 is a static angular app without a backend. It is built out of bassambst/guestbook-frontend:1.0 docker image. 
```sh
$ kubectl apply -f frontend-service.yaml
$ kubectl apply -f frontend.yaml
$ kubectl apply -f ingress.yaml
```
Update hosts file with:
Get minikube ip and update hosts file:
```sh
$ minikube ip
[minikube ip] frontend.minikube.local
```
Open browser at:
```
http://frontend.minikube.local
```
### Running staic front end applicaiton as v 2.0:
Version 2.0 is a dynamic version. Assuing we run 1.0 first. It requires redeployment of guestbook-frontend pod with docker image bassambst/guestbook-frontend:2.0

```sh
$ kubectl apply -f frontend-configmap.yaml
$ kubectl apply -f frontend-service.yaml
$ kubectl apply -f frontend.yaml
$ kubectl apply -f ingress.yaml

$ kubectl apply -f backend-secret.yaml
$ kubectl apply -f backend-service.yaml
$ kubectl apply -f backend.yaml

$ kubectl apply -f mongodb-persistent-volume.yaml
$ kubectl apply -f mongodb-persistent-volume-claim.yaml
$ kubectl apply -f mongodb-service.yaml
$ kubectl apply -f mongodb.yaml
```
We are then supposed to watch 3 running pods
```sh
kubectl get pods --watch
```
Ref:
https://hub.docker.com/repository/docker/bassambst/guestbook-frontend

# Guestbook - Run with Docker Run

### Requirements:
- Docker Desktop

Clean up all containers
```
docker rm -f $(docker ps -aq)
```

Run frontend 1.0:
```sh
$ docker run \
--name gb-frontend-10 \
-p 9001:4200 \
-d bassambst/guestbook-frontend:1.0
```
Test it with:
```
chrome http://localhost:9001
```

Run MongoDB:
```sh
$ docker run \
--name gb-backend-mongodb \
-v c:/mongo/guestbook/db:/data/db \
-e MONGO_INITDB_DATABASE='guestbook' \
-e MONGO_INITDB_ROOT_USERNAME='admin' \
-e MONGO_INITDB_ROOT_PASSWORD='password' \
--restart=always \
-d mongo
```

Get MongoDB container IP address via
```sh
$ docker inspect -f='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' gb-backend-mongodb
```

Run backend API (provide MongoDB contaienr ip to the env variable MONGODB_URI):
```sh
$docker run \
--name gb-backend-20 \
-p 9002:3000 \
-e MONGODB_URI='mongodb://admin:password@172.17.0.2:27017/guestbook?authSource=admin' \
-e GUESTBOOK_NAME='MyPopRock Festival 2.0' \
--restart=always \
-d bassambst/guestbook-backend:2.0
```

Run Frontend 2.0
```sh
$docker run \
--name gb-frontend-20 \
-p 9003:4200 \
-e BACKEND_URI='http://localhost:9002/guestbook' \
-e GUESTBOOK_NAME='MyPopRock Festival 2.0' \
--restart=always \
-d bassambst/guestbook-frontend:2.0

```
Test Guestbook 2.0:
```
chrome http://localhost:9003
```

## Place the containers in the same network and use container Name to connect the Backend API to MongoDB
```sh
$ docker network create gb-backend-net
$ docker network create gb-frontend-net

docker rm -f $(docker ps -aq)

$ docker run \
--name gb-backend-mongodb \
--network gb-backend-net \
-v c:/mongo/guestbook/db:/data/db \
-e MONGO_INITDB_DATABASE='guestbook' \
-e MONGO_INITDB_ROOT_USERNAME='admin' \
-e MONGO_INITDB_ROOT_PASSWORD='password' \
--restart=always \
-d mongo

$ docker run \
--name gb-backend-20 \
--network gb-backend-net \
-p 9002:3000 \
-e MONGODB_URI='mongodb://admin:password@gb-backend-mongodb:27017/guestbook?authSource=admin' \
-e GUESTBOOK_NAME='MyPopRock Festival 2.0' \
--restart=always \
-d bassambst/guestbook-backend:2.0

$ docker run \
--name gb-frontend-20 \
--network gb-frontend-net \
-p 9003:4200 \
-e BACKEND_URI='http://localhost:9002/guestbook' \
-e GUESTBOOK_NAME='MyPopRock Festival 2.0' \
--restart=always \
-d bassambst/guestbook-frontend:2.0

```

# Guestbook - Run with Docker-Compose
Navigate to ./with-docker-compose/guestbook-v2
Run:
```sh
docker-compose up
```
Test:
```sh
chrome http://localhost:9003
```

# Guestbook - Deploy with Helm
## 1- guestbook-1.0.0: helm chart of guestbook as static web app without backend.
- go to ./with-helm/1.0.0 (empty folder)
- Initialize new helm chart named guestbook:
```
helm create guestbook
```
- Delete unnecessary files.
- Copy Kubernetes yaml files from ./with-kubectl/v1 to ./with-helm/1.0.0
- Go to ./with-helm/1.0.0
- To make sure things will run well:
```
helm install guestbook ./guestbook --dry-run --debug
```
- If all seems Good:
```
helm install guestbook ./guestbook
```
- Verify the helm release:
```
helm list
```
- Run the application and observe the title Guestbook : "Concert For Climate 1.0"
```
chrome http://frontend.minikube.local
```
- Package the chart:
```
helm package guestbook
```
- Push the chart to ChartMuseum:
```
curl --data-binary @guestbook-1.0.0.tgz http://127.0.0.1:8080/api/charts
```

## 2- guestbook-1.0.1: guestbook with updated title in frontend. Still no backend. 
Copy the raw chart from 1.0.0 into 1.0.1 folder.

Make changes to ./with-helm/1.0.1/guestbook/templates/deployment.yaml and change the containerImage to bassambst/guestbook-frontend:1.1
```
    spec:
      containers:
      - image: bassambst/guestbook-frontend:1.1
```
Run:
```
helm upgrade guestbook ./guestbook
```
Observe the release revision is 2
```
helm list
```
Verify the container image of the deployment is 1.1
```
kubectl get deployments -o wide
```
Run the application and observe the title Guestbook : "Concert For Climate 1.1"
```
chrome http://frontend.minikube.local
```
We can rollback the release to previous revision:
```
helm rollback guestbook 1
```
Delete the release and all its deployed K8s objects
```
helm delete guestbook
```
## 3- guestbook-2.0.0: umbrella chart guestbook with frontend, backend and database. Plain manifests.

Go to ./with-helm/2.0.0
```
helm install guestbook ./guestbook
```
Then
```
chrome http://frontend.minikube.local
```
## 4- guestbook-2.1.0: 
The chart here is on the path to allow the deployments of multiple releases of the same chart. Collision of Kubernetes objects names/labels is avoided by letting Helm supply them as:
```
{{ .Release.Name }}-{{ .Chart.Name }}
```
Extracted changable values to values.yaml files for frontend and backend.

Go to ./with-helm/2.1.0
```
helm install guestbook ./guestbook
```
Then
```
chrome http://frontend.minikube.local
```
PS: frontend and backend charts supports this so far. 

## 5- guestbook-2.2.0: 
- Supplied dynamic Kubernetes objects names and labels. 
- With extracted changable values to values.yaml files. 
- Solved the problem of having backend chart to dynamically refer to database chart in its secrets. Knowing that the database chart service name is now dynamic!
- Introducing sub-templates in _helpers.tpl
- The chart still cannot be deployed to multiple releases yet, since the Ingress entry points for both the frontend and the backend  are still static.

Go to ./with-helm/2.2.0
```
helm install guestbook ./guestbook
```
Then
```
chrome http://frontend.minikube.local
```

## 6- guestbook-2.5.0:
Changes:
- Allowing dev/test deployments (full multi release support - full isolation)
- Unifying Ingress at Umbrella chart level. Where host name is dynamically generated from the release name.
- Still support sub-chart Ingress level deployment in case someone opted to installing sub-chart as standalone.

Install dev release:
```
helm install dev ./guestbook/ --set frontend.config.guestbook_name=DEV
```

Install test release:
```
helm install test ./guestbook/ --set frontend.config.guestbook_name=TEST
```
Observe the printed NOTES.txt for the URLs.

## 6- guestbook-2.6.0: Helm Dependencies
We have to generate tgz files. Push them to Helm Repo (we can deploy ChartMuseum or Use GitHub).

To generate tgz helm charts, copy ./with-helm/2.5.0/charts to ./with-helm/dist. Then:
```
helm package frontend backend database
```
That will generate the tgzs.

### Using Dependencies instead of exploded subcharts.
This version leverages Helm dependencies. Where dependencies are not included as exploded charts in charts folder. But as tgz files automatically.

1- We include this in Chart.yaml
```
dependencies:
    - name: backend
      version: ^1.0.0
      repository: https://localhost:8090
    - name: frontend
      version: ^2.0.0
      repository: https://localhost:8090
    - name: database
      version: ^1.0.0
      repository: https://localhost:8090
```

To resolve the dependencies:
```
helm dependency update guestbook
```
That will generate Chart.lock. It contains specific versions not ranges. We can use it in next dependency downloads.
```
helm dependency build guestbook
```
To verify dependencies:
```
helm dependency list guestbook
```
Then we install dev and test releases:
```
helm install dev guestbook
helm install test guestbook
```
Clean up helm releases:
```
helm delete $(helm list --short)
```