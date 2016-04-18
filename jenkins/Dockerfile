FROM jenkins
MAINTAINER feisky<feiskyer@gmail.com>

USER root
RUN apt-get update && apt-get install -y gcc git make wget autoconf automake libdevmapper-dev libsqlite3-dev libvirt-dev curl unzip rsync -qq

USER jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

