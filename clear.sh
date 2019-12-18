docker rm $(docker ps -aq)
docker rmi $(docker images dev-* -q)
docker rmi $(docker images net-* -q)
docker rmi $(docker images dev-peer* -q)
