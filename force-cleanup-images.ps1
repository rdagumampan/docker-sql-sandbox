#this would delete all your docker images
docker rmi $(docker images -a -q)
docker images