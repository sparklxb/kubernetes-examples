# 使用kubernetes部署kafka集群
#### kafka镜像步骤如下:
* 准备制作kafka镜像的Dockerfile
* 生成本地镜像,在Dockerfile目录下执行： docker build -t kafka .
* 将本地镜像上传到daocloud，没有上传到dockerhub的主要原因是网络不给力
```
docker tag kafka daocloud.io/zhengbo0/kafka
docker push daocloud.io/zhengbo0/kafka
```

#### 使用kubernetes发布kafka
* 创建service
```
 kubectl create -f kube/kafka-service.yaml
 kubectl create -f kube/kafka-1-service.yaml
 kubectl create -f kube/kafka-2-service.yaml
 kubectl create -f kube/kafka-3-service.yaml
 ```
* 查看已发布的service ,kubernetes部署zookeeper集群的操作步骤可以参考：https://github.com/zhengbo0/zookeeper
```
 #kubectl get svc
kafka         10.0.0.132   <none>        9092/TCP,7203/TCP            4d
kafka-1       10.0.0.28    <none>        9092/TCP,7203/TCP            4d
kafka-2       10.0.0.173   <none>        9092/TCP,7203/TCP            4d
kafka-3       10.0.0.209   <none>        9092/TCP,7203/TCP            4d
zookeeper     10.0.0.17    <none>        2181/TCP                     6d
zookeeper-1   10.0.0.179   <none>        2181/TCP,2888/TCP,3888/TCP   6d
zookeeper-2   10.0.0.221   <none>        2181/TCP,2888/TCP,3888/TCP   6d
zookeeper-3   10.0.0.186   <none>        2181/TCP,2888/TCP,3888/TCP   6d
```
* 修改kafka-1-controller.yaml，kafka-2-controller.yaml，kafka-3-controller.yaml 中` - name: ZOOKEEPER_CONNECT`的值为` value: "10.0.0.17:2181"	`
* 发布Replication Controllers 和pod
```
kubectl create -f kube/kafka-1-controller.yaml
kubectl create -f kube/kafka-2-controller.yaml
kubectl create -f kube/kafka-3-controller.yaml
```
* 查看是否运行成功
```
kubectl get svc    
kubectl get rc    
kubectl get pod
```
* 如果中间出现失败信息，可以通过kubectl logs pod名 查看详细日志信息
#### 验证zookeeper集群是否能正常工作
* 查看kafka集群endpoint
```
kubectl get ep
kafka         10.1.92.6:7203,10.1.92.7:7203,10.1.92.8:7203 + 3 more...   4d
kafka-1       10.1.92.6:7203,10.1.92.6:9092                              4d
kafka-2       10.1.92.8:7203,10.1.92.8:9092                              4d
kafka-3       10.1.92.7:7203,10.1.92.7:9092                              4d
```
* 进入kafka 容器   
通过docker ps | grep kafka 查看容器ID,然后通过docker exec -it 容器ID /bin/bash进入容器
* 创建topic,并导入测试数据
```
bin/kafka-topics.sh --create --zookeeper 10.0.0.17:2181 --replication-factor 3 --partitions 3 --topic test1
bin/kafka-topics.sh --list --zookeeper 10.0.0.17:2181
bin/kafka-console-producer.sh --broker-list 10.1.59.6:9092 10.1.59.7:9092 10.1.59.8:9092 --topic test1
This is a message
other This is another message
echo a test message
luck dog
^C
bin/kafka-console-consumer.sh --zookeeper 10.0.0.17:2181 --topic test1 --from-beginning
```
* 在另外一台kafka容器上执行
```
bin/kafka-console-consumer.sh --zookeeper 10.0.0.17:2181 --topic test1 --from-beginning
```
如果能正确输出测试数据，说明kafka集群成功部署
