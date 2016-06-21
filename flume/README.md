# 使用kubernetes部署单节点flume
注意：该项目主要是通过使用kubernetes部署单节点flume，向kubernetes部署的kafka集群发送测试数据
kafka集群部署请参考：https://github.com/zhengbo0/kafka
如果仅作单节点测试，请把如下flume-example.conf中如下内容删除掉
```
docker.sinks.kafkaSink.type = org.apache.flume.sink.kafka.KafkaSink
docker.sinks.kafkaSink.topic = test1
docker.sinks.kafkaSink.brokerList = 10.0.0.132:9092
docker.sinks.kafkaSink.requiredAcks = 1
docker.sinks.kafkaSink.batchSize = 20
docker.sinks.kafkaSink.channel = inMemoryChannel
```
并把`docker.sinks = logSink kafkaSink`修改为`docker.sinks = logSink`
###flume镜像步骤如下：
* 准备制作flume镜像的Dockerfile
* 生成本地镜像,在Dockerfile目录下执行： `docker build -t flume .`
* 将本地镜像上传到daocloud，没有上传到dockerhub的主要原因是网络不给力  
```
docker tag flume daocloud.io/zhengbo0/flume  
docker push daocloud.io/zhengbo0/flume
```

###在kubernetes上运行flume
* 修改flume-example.conf文件，将docker.sinks.kafkaSink.brokerList替换为kafka service cluster ip，部署单节点flume无需修改flume-example.conf
```
kafka         10.0.0.132   <none>        9092/TCP,7203/TCP            5d
kafka-1       10.0.0.28    <none>        9092/TCP,7203/TCP            5d
kafka-2       10.0.0.173   <none>        9092/TCP,7203/TCP            5d
kafka-3       10.0.0.209   <none>        9092/TCP,7203/TCP            5d
```
* 通过kubectl发布flume   
```
kubectl create -f kube/flume-1-service.yaml    
kubectl create -f flume-1-controller.yaml
```
* 查询是否运行成功    
```
kubectl get svc    
kubectl get rc    
kubectl get pod 
```
* 如果中间出现失败信息，可以通过kubectl logs pod名 查看详细日志信息

### 测试flume功能是否可以正常使用
* 进入flume 容器
通过docker ps | grep flume 查看容器ID,然后通过docker exec -it 容器ID /bin/bash进入容器
* 通过netcat向44444端口发送测试数据   
`echo foo2 bar2 baz2 | nc localhost 44444`
* 另起一个终端，通过kubectl logs pod名，查看是否有日志输出到终端
