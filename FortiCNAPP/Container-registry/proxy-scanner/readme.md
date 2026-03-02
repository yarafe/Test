# Platform Scanner Integration with Amazon Elastic Container Registry (ECR) Using an IAM Role

## Introduction

linux nexus repository
-install docker on linux machine
sudo snap install docker

- run nexus 
sudo docker run -d \
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
add other connector https 5001

activate https on nexus:

Generating Self Signed Server TLS Certificates

- docker exec -it nexus bash
- cd /nexus-data/etc/ssl
- Generate public private key pair using keytool:
keytool -genkeypair -keystore keystore.jks -storepass password -alias example.com \
     -keyalg RSA -keysize 2048 -validity 5000 -keypass password \
     -dname 'CN=*.example.com, OU=Sonatype, O=Sonatype, L=Unspecified, ST=Unspecified, C=US' \
     -ext 'SAN=DNS:nexus.example.com,DNS:clm.example.com,DNS:repo.example.com,DNS:www.example.com'

Output: keystore.jks
- Generate PEM encoded public certificate file using keytool:
keytool -exportcert -keystore keystore.jks -alias example.com -rfc > example.cert
Output: example.cert

- Convert our Java specific keystore binary".jks" file to a widely compatible PKCS12 keystore ".p12" file:
keytool -importkeystore -srckeystore keystore.jks -destkeystore example.p12 -deststoretype PKCS12

-  add to nexus.properties file :
  application-port-ssl=8443
  ssl.etc=${karaf.data}/etc/ssl
  nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-requestlog.xml

  
FILE=/nexus-data/etc/nexus.properties
echo 'application-port-ssl=8443' >> $FILE
echo 'ssl.etc=${karaf.data}/etc/ssl' >> $FILE
sed -i 's|^# *nexus-args=.*|nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-requestlog.xml|' $FILE

- run root inside container
 sudo docker exec -it -u 0 <container_id> bash
cd /opt/sonatype/nexus/etc/jetty/jetty-https.xml


docker stop nexus
docker rm nexus


docker run -d \
  --name nexus \
  -p 8081:8081 \
  -p 8443:8443 \
  -p 5001:5001 \
  -v nexus-data:/nexus-data \
  sonatype/nexus3


- DNS local
echo "172.23.240.7 nexus.example.com" | sudo tee -a /etc/hosts

- sudo sh -c 'docker cp nexus:/nexus-data/etc/ssl/example.cert - | tar -xO > /tmp/example.cert'

sudo cp /tmp/example.cert /usr/local/share/ca-certificates/nexus-example-ca.crt
sudo update-ca-certificates
sudo snap restart docker.dockerd


- sudo mkdir -p /etc/docker/certs.d/nexus.example.com:5001
sudo cp ~/nexus.crt /etc/docker/certs.d/nexus.example.com:5001/ca.crt
sudo snap restart docker


sudo docker login nexus.example.com:5001
sudo docker tag busybox:latest nexus.example.com:5001/repository/ya-nexus-repo-test:latest
sudo docker push nexus.example.com:5001/repository/ya-nexus-repo-test:latest



sudo snap logs docker -n 200

Deploy the Proxy Scanner


- echo "172.23.240.7 nexus.example.com" | sudo tee -a /etc/hosts

Before you deploy the proxy scanner, ensure that you set up a host machine with Docker installed.

- Pull the latest Lacework FortiCNAPP proxy scanner image:

    docker pull lacework/lacework-proxy-scanner:latest

    verify :
    docker images | grep lacework-proxy-scanner



    Create a persistent storage location for the Lacework FortiCNAPP proxy scanner cache and change the ownership:

    sudo mkdir cache
    sudo chown -R 1000:65533 cache

    create config.yml

    scan_public_registries: false
static_cache_location: /opt/lacework/cache
default_registry:
lacework:
  account_name: lwintseemea-eu
  integration_access_token: _96782e3331e8af01ede8ac312beed368
registries:
  - domain: nexus.example.com:5001
    name: my-nexus-integration
    ssl: true
    is_public: false
    auto_poll: true
    credentials:
      user_name: "admin"
      password: "Fortigate4yaser"
    notification_type: nexus
    disable_non_os_package_scanning: false
    go_binary_scanning:
      enable: true


  - copy certificate from nexus machine:
scp yarafe@172.23.240.7:/usr/local/share/ca-certificates/nexus-example-ca.crt \
  /tmp/nexus-example-ca.crt




    Start the Lacework FortiCNAPP proxy scanner:

     docker run -d --mount type=bind,source="$(pwd)"/cache,target=/opt/lacework/cache -v "$(pwd)"/config.yml:/opt/lacework/config/config.yml -p 8080:8080 -p 5001:5001 -p 8443:8443 lacework/lacework-proxy-scanner

    For debugging purposes, add -e LOG_LEVEL=debug:

    docker run -e LOG_LEVEL=debug -d --mount ...

    Available LOG_LEVEL options = error|warn|debug
