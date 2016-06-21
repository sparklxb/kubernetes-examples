# kubernetes部署zookeeper集群
#### 制作zookeeper镜像
* 准备好制作zookeeper镜像的Dockerfile
* 制作本地镜像，在Dockerfile文件所在目录执行
`docker build -t zookeeper .`
* 将本地镜像上传到daocloud    
`docker tag zookeeper daocloud.io/zhengbo0/zookeeper`    
`docker push daocloud.io/zhengbo0/zookeeper `

#### 使用kubernetes发布zookeeper
* 创建service
```
kubectl create -f kube/zookeeper-service.yaml
kubectl create -f kube/zookeeper-1-service.yaml
kubectl create -f kube/zookeeper-2-service.yaml
kubectl create -f kube/zookeeper-3-service.yaml
```
* 查看service cluster ip执行
```
#kubectl get svc
zookeeper     10.0.0.17    <none>        2181/TCP                     6d
zookeeper-1   10.0.0.179   <none>        2181/TCP,2888/TCP,3888/TCP   6d
zookeeper-2   10.0.0.221   <none>        2181/TCP,2888/TCP,3888/TCP   6d
zookeeper-3   10.0.0.186   <none>        2181/TCP,2888/TCP,3888/TCP   6d
```
* 修改run.sh，分别zookeeper-1，zookeeper-2,zookeeper-3,替换为对应的service cluster ip
```
sed -i "s/zookeeper-1/10.0.0.179/g" /opt/zookeeper/data/zoo_dynamic.cfg
sed -i "s/zookeeper-2/10.0.0.221/g" /opt/zookeeper/data/zoo_dynamic.cfg
sed -i "s/zookeeper-3/10.0.0.186/g" /opt/zookeeper/data/zoo_dynamic.cfg
```
* 创建replicationcontroller和pod
```
kubectl create -f kube/zookeeper-1-controller.yaml
kubectl create -f kube/zookeeper-2-controller.yaml
kubectl create -f kube/zookeeper-3-controller.yaml
```
* 查看是否运行成功
```
kubectl get svc    
kubectl get rc    
kubectl get pod
```
* 如果中间出现失败信息，可以通过kubectl logs pod名 查看详细日志信息

####验证zookeeper集群是否能正常工作
* 进入zookeeper 容器 通过docker ps | grep zookeeper 查看容器ID,然后通过docker exec -it 容器ID /bin/bash进入容器
* 通过zk client创建测试数据
```
[root@zookeeper-1-w3u4g zookeeper]# bin/zkCli.sh
[zk: localhost:2181(CONNECTED) 1] create /foo bar
Created /foo
[zk: localhost:2181(CONNECTED) 2] get /foo
bar
```
* 重新连接到另外一个docker容器
```
# kubectl exec -ti zookeeper-3-vcl94 /bin/bash
[root@zookeeper-3-vcl94 zookeeper]# bin/zkCli.sh
[zk: localhost:2181(CONNECTED) 0] get /foo
bar
```
说明集群成功运行了
