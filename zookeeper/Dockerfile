FROM java:7

MAINTAINER "zhengbo" <bo.zheng@baifendian.com>

RUN apt-get update && \

apt-get  install -y vim 

RUN mkdir /opt/zookeeper

RUN mkdir /opt/zookeeper/data

RUN chmod 755 /opt/zookeeper/data

RUN wget -qO- \

  http://apache.fayea.com/zookeeper/zookeeper-3.5.0-alpha/zookeeper-3.5.0-alpha.tar.gz \

  | tar zx -C /opt/zookeeper --strip 1

ENV PATH /opt/zookeeper/bin:$PATH

RUN apt-get install -y net-tools

EXPOSE 2181 2888 3888

COPY zoo.cfg /opt/zookeeper/conf/zoo.cfg

COPY run.sh /opt/zookeeper/run.sh
RUN chmod a+x /opt/zookeeper/run.sh

CMD ["/opt/zookeeper/run.sh"]
