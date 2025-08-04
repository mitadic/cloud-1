docker ps -qa | xargs docker stop
docker ps -qa | xargs docker rm
docker image ls -qa | xargs docker rmi -f
docker volume ls -q | xargs docker volume rm
docker network ls -q | xargs
docker network ls -q | xargs docker network rm 2>/dev/null