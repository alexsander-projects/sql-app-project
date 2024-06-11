#!/bin/bash
cd /
sudo yum install git-all -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo dnf install zip -y
sudo docker pull nokorinotsubasa/centosjenkins175:409
sudo docker run --name jenkins -p 8080:8080 -p 50000:50000 -d -v jenkins_home:/var/jenkins_home nokorinotsubasa/centosjenkins175:409
sudo docker start jenkins
exit 0