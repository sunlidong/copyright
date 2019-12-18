#!/usr/bin/env bash

### 删除镜像以及容器
docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)
docker rmi $(docker images net-* -q)
docker rmi $(docker images dev-peer* -q)
docker rmi $(docker images dev-peer*bqchain -q)
sudo docker rm -f $(sudo docker ps -aq)
sudo docker network prune
sudo docker volume prune

### 删除 缓存目录
rm -rf ./channel-artifacts/*
rm -rf ./crypto-config/*
