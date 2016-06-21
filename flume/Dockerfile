FROM java:7

MAINTAINER "zhengbo" <bo.zheng@baifendian.com>

RUN apt-get update && \
 apt-get  install -y vim

RUN mkdir /opt/flume

RUN wget -qO- \
  http://apache.fayea.com/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz \
  | tar zx -C /opt/flume --strip 1

ADD flume-example.conf /opt/flume/conf/flume-example.conf

ENV PATH /opt/flume/bin:$PATH

RUN apt-get install -y net-tools

RUN apt-get -y install netcat-traditional

ENTRYPOINT [ "flume-ng", "agent","-c", "/opt/flume/conf", "-f", "/opt/flume/conf/flume-example.conf", "-n", "docker","-Dflume.root.logger=INFO,console" ]
