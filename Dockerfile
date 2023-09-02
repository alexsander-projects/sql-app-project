#This is the official jenkins docker image; it runs on centos7
FROM jenkins/jenkins:lts-centos7-jdk11
USER root

RUN yum update -y --disablerepo=\* --enablerepo=base,updates
RUN yum update -y && \
    yum upgrade -y \
    #yum search dotnet && \
    yum install git-all -y && \
    yum install -y yum-utils && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm && \
    yum install -y dotnet-sdk-7.0 && \
    yum install zip -y && \
    yum install -y wget

USER jenkins