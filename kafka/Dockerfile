FROM java:7

MAINTAINER "zhengbo" <bo.zheng@baifendian.com>

RUN apt-get update && apt-get  install -y vim

RUN mkdir /opt/kafka
RUN mkdir /opt/kafka/data
RUN chmod 755 /opt/kafka/data

RUN   wget -qO- \
   http://apache.fayea.com/kafka/0.10.0.0/kafka_2.11-0.10.0.0.tgz \
   | tar zx -C /opt/kafka --strip 1

ENV PATH /opt/kafka/bin:$PATH

RUN apt-get install -y net-tools

EXPOSE 9092
EXPOSE 7203

COPY config/server.properties /opt/kafka/config/server.properties
COPY ./start.sh /opt/kafka

RUN chmod a+x /opt/kafka/start.sh
CMD ["/opt/kafka/start.sh"]
