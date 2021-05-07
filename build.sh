#!/bin/bash

DOCKER_COMPOSE_CHANGED=$(git -C /var/repos/flaskapp.git/ diff --name-only HEAD~1 HEAD | grep "docker-compose.yaml")


NGINX_GIT_CHANGED=$(git -C /var/repos/flaskapp.git/ diff --name-only HEAD~1 HEAD | grep "nginx/")
NGINX_RUNNING=$(docker ps | grep nginx)

APP_CODE_CHANGED=$(git -C /var/repos/flaskapp.git/ diff --name-only HEAD~1 HEAD | grep "app/")

if [[ $DOCKER_COMPOSE_CHANGED ]]; then
    echo "Docker compose has changed, rebuilding..."
    docker-compose down
    docker-compose up -d --build
fi

if [[ $NGINX_GIT_CHANGED ]]; then
    echo "Nginx has changed, rebuilding..."
    docker-compose down
    docker-compose up -d --build
fi

if [[ $NGINX_RUNNING == "" ]]; then
    echo "Nginx is not running. Bringing Up"
    docker-compose up -d --build
fi

FLASKSERVICE_RUNNING=$(docker ps | grep flaskservice)

if [[ $FLASKSERVICE_RUNNING == "" ]]; then
    echo "Flask app service is not running. Bringing Up"
    docker-compose up -d --build flaskservice dosservice tresservice
    docker-compose exec -d nginx nginx -s reload
fi

BACKUP_SERVER_RUNNING=$(docker ps | grep backupservice)
if [[ $BACKUP_SERVER_RUNNING == "" ]]; then
    echo "Backup service is not running. Bringing Up"
    docker-compose up -d --build backupservice
    docker-compose exec -d nginx nginx -s reload
fi

if [[ $APP_CODE_CHANGED ]]; then 
    echo "Flask service code changed, rebuilding service"
    docker-compose build flaskservice dosservice tresservice backupservice
    docker-compose stop flaskservice dosservice tresservice
    docker-compose rm -f flaskservice dosservice tresservice
    docker-compose up -d --no-deps flaskservice dosservice tresservice
    docker-compose exec -d nginx nginx -s reload
    if [[ $(docker ps | grep flaskservice) ]]; then
        echo "Flask service rebuilt and up, rebuilding backup"
        docker-compose stop backupservice
        docker-compose rm -f backupservice
        docker-compose up -d --build backupservice
        docker-compose exec -d nginx nginx -s reload
    fi
fi

sleep 5
docker-compose exec -d nginx nginx -s reload