# guestbook
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





