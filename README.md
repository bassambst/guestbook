# guestbook
### Requirements:
- Minikube
- Kubectl
- Enable Ingress addon in Minikube with: 
```sh
$ minikube addons enable ingress
```

### Running staic front end applicaiton as v1:
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
