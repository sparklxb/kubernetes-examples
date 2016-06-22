# docker-elasticsearch-kubernetes
Kubernetes官方Elasticsearch示例[Elasticsearch for Kubernetes](https://github.com/kubernetes/kubernetes/tree/release-1.2/examples/elasticsearch) 使用Elasticsearch v1.7.1的镜像。该镜像[docker-elasticsearch-kubernetes](https://github.com/pires/docker-elasticsearch-kubernetes)维护者也提供新版本的Elasticsearch。这些镜像工作原理与[Kubernetes Cloud Plugin for Elasticsearch](https://github.com/fabric8io/elasticsearch-cloud-kubernetes) 相同。后者基于[Elasticsearch官方镜像](https://github.com/docker-library/elasticsearch)，使用其插件自动pod发现，没有提供dockerfile文件。我也采用以上方法，编写dockerfile制作镜像。

##所需环境

* Kubernetes集群（或Kubernetes单节点）
* kubectl

##文件说明
* service-account.yaml 生成elasticsearch账号
* elasticsearch.yml 使用dockerfile打包镜像时，用于替换Elasticsearch官方镜像中的elasticsearch.yml，以配置Elasticsearch
* kubernetes.yml 用以生成两个service和三个replication controller的yaml文件，使用方法见后

##镜像构建（可选项）

```
docker build -t <name>/es .
```


##测试

###部署

```
kubectl create -f service-account.yaml
kubectl create -f kubernetes.yml
```

data默认采用emptyDir volume存储，如果希望在pod销毁后，数据仍然存在，采用hostPath volume。emptyDir与hostPath区别，详见[Kubernetes - Volumes
](http://kubernetes.io/docs/user-guide/volumes/)。运行前，kubernetes.yml中volumes项做如下修改。

```
        volumes:
          - name: "elasticsearch-data"
            hostPath:
              path: <要挂载的主机文件路径>
```

运行create后部署三个pod，分别作为
* Master nodes - intended for clustering management only, no data, no HTTP API
* Client nodes - intended for client usage, no data, with HTTP API
* Data nodes - intended for storing and indexing your data, no HTTP API

检查运行是否成功

```
$ kubectl get svc,rc,pods
NAME                            CLUSTER-IP   EXTERNAL-IP   PORT(S)                                                 AGE
elasticsearch                   10.0.0.21                  9200/TCP                                                15s
elasticsearch-masters           None         <none>        9300/TCP                                                15s
NAME                            DESIRED      CURRENT       AGE
elasticsearch-client            1            1             15s
elasticsearch-data              1            1             15s
elasticsearch-master            1            1             15s
NAME                            READY        STATUS        RESTARTS   AGE
elasticsearch-client-sdyqe      1/1          Running       0          15s
elasticsearch-data-spru1        1/1          Running       0          15s
elasticsearch-master-gep0w      1/1          Running       0          15s
```

查看master node log

```
$ kubectl logs elasticsearch-master-gep0w
[2016-06-14 07:55:32,916][INFO ][node                     ] [Zodiak] version[2.3.3], pid[1], build[218bdf1/2016-05-17T15:40:04Z]
[2016-06-14 07:55:32,918][INFO ][node                     ] [Zodiak] initializing ...
[2016-06-14 07:55:33,879][INFO ][plugins                  ] [Zodiak] modules [reindex, lang-expression, lang-groovy], plugins [cloud-kubernetes], sites []
[2016-06-14 07:55:33,995][INFO ][env                      ] [Zodiak] using [1] data paths, mounts [[/usr/share/elasticsearch/data (/dev/vda1)]], net usable_space [359.1mb], net total_space [49.9gb], spins? [possibly], types [xfs]
[2016-06-14 07:55:33,995][INFO ][env                      ] [Zodiak] heap size [990.7mb], compressed ordinary object pointers [true]
[2016-06-14 07:55:36,767][INFO ][node                     ] [Zodiak] initialized
[2016-06-14 07:55:36,767][INFO ][node                     ] [Zodiak] starting ...
[2016-06-14 07:55:36,916][INFO ][transport                ] [Zodiak] publish_address {10.1.16.4:9300}, bound_addresses {[::]:9300}
[2016-06-14 07:55:36,924][INFO ][discovery                ] [Zodiak] elasticsearch/ZpEHqRlFRz6KmF8_VqTS0w
[2016-06-14 07:55:41,235][INFO ][cluster.service          ] [Zodiak] new_master {Zodiak}{ZpEHqRlFRz6KmF8_VqTS0w}{10.1.16.4}{10.1.16.4:9300}{data=false, master=true}, reason: zen-disco-join(elected_as_master, [0] joins received)
[2016-06-14 07:55:41,256][INFO ][http                     ] [Zodiak] publish_address {10.1.16.4:9200}, bound_addresses {[::]:9200}
[2016-06-14 07:55:41,257][INFO ][node                     ] [Zodiak] started
[2016-06-14 07:55:41,300][INFO ][gateway                  ] [Zodiak] recovered [0] indices into cluster_state
[2016-06-14 07:55:42,226][INFO ][cluster.service          ] [Zodiak] added {{Powderkeg}{5i3wVastQuqi3FBOvcM5Hg}{10.1.99.6}{10.1.99.6:9300}{master=false},}, reason: zen-disco-join(join from node[{Powderkeg}{5i3wVastQuqi3FBOvcM5Hg}{10.1.99.6}{10.1.99.6:9300}{master=false}])
[2016-06-14 07:55:42,332][INFO ][gateway                  ] [Zodiak] auto importing dangled indices [yzm_index/OPEN] from [{Powderkeg}{5i3wVastQuqi3FBOvcM5Hg}{10.1.99.6}{10.1.99.6:9300}{master=false}]
[2016-06-14 07:55:43,019][INFO ][cluster.service          ] [Zodiak] added {{Ghost Rider}{2ycT0O7ESPa9J1Gu5_8g1w}{10.1.99.7}{10.1.99.7:9300}{data=false, master=false},}, reason: zen-disco-join(join from node[{Ghost Rider}{2ycT0O7ESPa9J1Gu5_8g1w}{10.1.99.7}{10.1.99.7:9300}{data=false, master=false}])

```

###扩展

```
kubectl scale --replicas 2 rc/elasticsearch-master
kubectl scale --replicas 2 rc/elasticsearch-client
kubectl scale --replicas 3 rc/elasticsearch-data
```

运行后，Master node, Client node, Data node个数分别增加到2, 2, 3。

检查运行是否成功

```
NAME                            CLUSTER-IP   EXTERNAL-IP   PORT(S)                                                 AGE
elasticsearch                   10.0.0.21                  9200/TCP                                                1h
elasticsearch-masters           None         <none>        9300/TCP                                                1h
NAME                            DESIRED      CURRENT       AGE
elasticsearch-client            2            2             1h
elasticsearch-data              3            3             1h
elasticsearch-master            2            2             1h
NAME                            READY        STATUS        RESTARTS   AGE
elasticsearch-client-sdyqe      1/1          Running       0          1h
elasticsearch-client-uqc18      1/1          Running       0          34s
elasticsearch-data-iqjan        1/1          Running       0          17s
elasticsearch-data-s090d        1/1          Running       0          17s
elasticsearch-data-spru1        1/1          Running       0          1h
elasticsearch-master-g3mqu      1/1          Running       0          41s
elasticsearch-master-gep0w      1/1          Running       0          1h
```

###访问服务
Kubernetes中的service默认只能从container中访问。需要以NodePort或LoadBalancer方式，对外暴露service访问。

通过如下命令获得CLUSTER-IP

```
$ kubectl get svc elasticsearch
NAME            CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
elasticsearch   10.0.0.21                  9200/TCP   1h
```

可在集群内任意一台运行kube-proxy的机器运行

```
curl http://10.0.0.21:9200
```

或者

```
$ kubectl describe svc elasticsearch
Name:			elasticsearch
Namespace:		default
Labels:			component=elasticsearch,provider=fabric8
Selector:		component=elasticsearch,provider=fabric8,type=client
Type:			LoadBalancer
IP:			10.0.0.21
Port:			<unset>	9200/TCP
NodePort:		<unset>	32707/TCP
Endpoints:		10.1.16.5:9200,10.1.99.7:9200
Session Affinity:	None
No events.
```

获得Endpoints和NodePort（此测试集群采用NodePort）

在集群内任意节点运行

```
curl http://10.1.16.5:9200
或
curl http://110.1.99.7:9200
```

或在集群外的节点，以任意可访问的集群节点IP，加NodePort运行

```
curl http://172.24.3.164:32707
```

以上任意命令将得到如下类似信息

```
{
  "name" : "Hit-Maker",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "2.3.3",
    "build_hash" : "218bdf10790eef486ff2c41a3df5cfa32dadcfde",
    "build_timestamp" : "2016-05-17T15:40:04Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.0"
  },
  "tagline" : "You Know, for Search"
}
```


检查集群状态

```
curl http://10.1.99.7:9200/_cluster/health?pretty
```

获得如下类似信息

```
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 7,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 5,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

##参考及致谢

原镜像的github，[pires/kubernetes-elasticsearch-cluster](https://github.com/pires/kubernetes-elasticsearch-cluster)

插件github及运行方法，[Kubernetes Cloud Plugin for Elasticsearch](https://github.com/fabric8io/elasticsearch-cloud-kubernetes)
