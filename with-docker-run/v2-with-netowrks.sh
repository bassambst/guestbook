docker network create gb-frontend-net
docker network create gb-backend-net

docker rm -f $(docker ps -aq)

docker run \
--name gb-backend-mongodb \
--network gb-backend-net \
-v c:/mongo/guestbook/db:/data/db \
-e MONGO_INITDB_DATABASE='guestbook' \
-e MONGO_INITDB_ROOT_USERNAME='admin' \
-e MONGO_INITDB_ROOT_PASSWORD='password' \
--restart=always \
-d mongo

docker run \
--name gb-backend-20 \
--network gb-backend-net \
-p 9002:3000 \
-e MONGODB_URI='mongodb://admin:password@gb-backend-mongodb:27017/guestbook?authSource=admin' \
--restart=always \
-d bassambst/guestbook-backend:2.0

docker run \
--name gb-frontend-20 \
--network gb-frontend-net \
-p 9003:4200 \
-e BACKEND_URI='http://localhost:9002/guestbook' \
-e GUESTBOOK_NAME='MyPopRock Festival 2.0' \
--restart=always \
-d bassambst/guestbook-frontend:2.0
