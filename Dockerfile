FROM centos:6
MAINTAINER Huamin Chen, hchen@redhat.com 

ADD install.sh /usr/local/bin/
RUN /usr/local/bin/install.sh 
ADD init.sh /usr/local/bin/

EXPOSE 6789/tcp

ENTRYPOINT ["/usr/local/bin/init.sh"]
