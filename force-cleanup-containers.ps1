#this would stop and delete all your containers
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker ps