# Guesbook - Run with Kubectl

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

# Guesbook - Run with Docker Run

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
