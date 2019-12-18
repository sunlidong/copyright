docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)
docker rmi $(docker images net-* -q)
docker rmi $(docker images dev-peer* -q)
docker rmi $(docker images dev-peer*bqchain -q)
sudo docker rm -f $(sudo docker ps -aq)
sudo docker network prune
sudo docker volume prune
