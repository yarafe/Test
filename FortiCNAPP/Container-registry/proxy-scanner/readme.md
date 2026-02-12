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