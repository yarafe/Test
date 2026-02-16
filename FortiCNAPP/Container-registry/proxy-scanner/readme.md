# Platform Scanner Integration with Amazon Elastic Container Registry (ECR) Using an IAM Role

## Introduction


docker run -d \
  -p 8081:8081 \
  --name nexus \
  -v nexus-data:/nexus-data \
  sonatype/nexus3

check if it is running
docker ps

yarafe@linux-server1:~$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATU                                                                                                                                                             S          PORTS                                       NAMES
25a47f21f4d1   sonatype/nexus3   "/opt/sonatype/nexus…"   14 minutes ago   Up 14                                                                                                                                                              minutes   0.0.0.0:8081->8081/tcp, :::8081->8081/tcp   nexus

get password
docker exec -it nexus cat /nexus-data/admin.password

access: http://<your-server-ip>:8081
with credentil admin/<password>

change password

create repository
Settings → Repositories → Create repository

Create a new hosted Docker repository 



Deploy the Proxy Scanner

Before you deploy the proxy scanner, ensure that you set up a host machine with Docker installed.

- Pull the latest Lacework FortiCNAPP proxy scanner image:

    docker pull lacework/lacework-proxy-scanner:latest

    verify :
    docker images | grep lacework-proxy-scanner



    Create a persistent storage location for the Lacework FortiCNAPP proxy scanner cache and change the ownership:

    mkdir cache
    chown -R 1000:65533 cache

    Start the Lacework FortiCNAPP proxy scanner:

     docker run -d --mount type=bind,source="$(pwd)"/cache,target=/opt/lacework/cache -v "$(pwd)"/config.yml:/opt/lacework/config/config.yml -p 8080:8080 lacework/lacework-proxy-scanner

    For debugging purposes, add -e LOG_LEVEL=debug:

    docker run -e LOG_LEVEL=debug -d --mount ...

    Available LOG_LEVEL options = error|warn|debug
