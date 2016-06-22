# TensorFlow部署测试

```
由于不了解深度学习概念,之前也没有接触过TensorFlow,本文对TensorFlow的使用和理解难免会有所片面或不足.
```

目前的网络资源涉及如下三个内容:

* 单机TensorFlow
* 用TensorFlow Serving和k8s给模型提供服务(未测试)
* TensorFlow k8s集群

##单机TensorFlow

官方提供有[镜像](https://hub.docker.com/r/tensorflow/tensorflow/),免去了搭建的麻烦.

运行CPU版本镜像

```
docker run -it -p 8888:8888 tensorflow/tensorflow
```

在本机浏览器访问http://localhost:8888/或者从外部访问,如http://172.24.3.171:8888/ .可看到jupyter界面,里面提供:

* 网页版编辑器
* 网页版terminal(远程连接运行TensorFlow节点)
* 管理可编辑的执行文件(.ipynb,类似Mathematicas)

docker exec -it <TensorFlow所在的container id> bash进入container,或者在jupyter界面,"New"->"Terminal"新建terminal,在里面使用TensorFlow,例如下面的官方示例:

```python
$ python

>>> import tensorflow as tf
>>> hello = tf.constant('Hello, TensorFlow!')
>>> sess = tf.Session()
>>> sess.run(hello)
Hello, TensorFlow!
>>> a = tf.constant(10)
>>> b = tf.constant(32)
>>> sess.run(a+b)
42
>>>
```

##用TensorFlow Serving和Kubernetes给模型提供服务(未测试)

官方给出的是Inception模型示例,代码在[这里](https://github.com/tensorflow/serving/tree/master/tensorflow_serving/example),[原文](blog.kubernetes.io/2016/03/scaling-neural-network-image-classification-using-Kubernetes-with-TensorFlow-Serving.html)因为网络的原因访问不了,可见[国内文章](https://segmentfault.com/a/1190000004829764)

个人理解,大概是每个pod持有模型,利用k8s的Load Balance负载均衡.

##TensorFlow在kubernetes的并行

###测试环境

实际k8s集群,[官方文档](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/dist_test)

###部署TensorFlow k8s

进入k8s集群中的任意一台机器(集群外节点也行,因为后面测试要制作镜像,这里简单处理),从github下载TensorFlow代码

```
git clone https://github.com/tensorflow/tensorflow.git
```

进入tensorflow/tools/dist_test目录,执行如下命令生成本库的tf-k8s-with-lb.yaml文件

```
scripts/k8s_tensorflow.py \
    --num_workers 2 \
    --num_parameter_servers 2 \
    --grpc_port 2222 \
    --request_load_balancer true \
    --docker_image "tensorflow/tf_grpc_server" \
    > tf-k8s-with-lb.yaml
```

生成后,执行部署

```
kubectl create -f tf-k8s-with-lb.yaml
```

检查运行是否成功,可见生成两个param server的rc和两个worker的rc,以及它们相关的svc和pod.

```
$ kubectl get svc,rc,pods
NAME                            CLUSTER-IP   EXTERNAL-IP   PORT(S)                                                 AGE
tf-ps0                          10.0.0.3     <none>        2222/TCP                                                6h
tf-ps1                          10.0.0.147   <none>        2222/TCP                                                6h
tf-worker0                      10.0.0.57                  2222/TCP                                                6h
tf-worker1                      10.0.0.243                 2222/TCP                                                6h
NAME                            DESIRED      CURRENT       AGE
tf-ps0                          1            1             6h
tf-ps1                          1            1             6h
tf-worker0                      1            1             6h
tf-worker1                      1            1             6h
NAME                            READY        STATUS        RESTARTS   AGE
tf-ps0-w9jib                    1/1          Running       0          6h
tf-ps1-briuu                    1/1          Running       0          6h
tf-worker0-cz1nq                1/1          Running       0          6h
tf-worker1-ll2dn                1/1          Running       0          6h
```

查看endpoints

```
$ kubectl get ep
NAME                    ENDPOINTS                       AGE
tf-ps0                  10.1.16.11:2222                 6h
tf-ps1                  10.1.16.10:2222                 6h
tf-worker0              10.1.16.9:2222                  6h
tf-worker1              10.1.16.8:2222                  6h
```

###测试

执行,其中,remote_test.sh会生成带TensorFlow环境的测试镜像

```
$ export TF_DIST_GRPC_SERVER_URL="grpc://<tf-worker0或tf-worker1的ENDPOINTS>"
$ ./remote_test.sh
...　// 镜像打包输出
NUM_WORKERS = 2
NUM_PARAMETER_SERVERS = 2
SETUP_CLUSTER_ONLY = 0
GRPC_SERVER_URLS: 
SYNC_REPLICAS: 0
GRPC port to be used when creating the k8s TensorFlow cluster: 2222
Path to gcloud binary: /var/gcloud/google-cloud-sdk/bin/gcloud　
gcloud service account key file cannot be found at: /var/gcloud/secrets/tensorflow-testing.json // 这里并不重要
FAILED to determine GRPC server URLs of all workers　//　错误提示,并且上面GRPC_SERVER_URLS:也为空 
```

根据错误提示,直接启动镜像,执行remote_test.sh里要执行的脚本/var/tf-dist-test/scripts/dist_test.sh(在此之前设置其缺失的GRPC server URLs相关环境变量)

```
$　docker run -it tensorflow/tf-dist-test-client　//　此为刚才remote_test.sh生成的镜像,docker hub上并没有
// 以下为container内的操作和显示
$　export TF_DIST_GRPC_SERVER_URLS="grpc://<tf-worker0的ENDPOINTS> grpc://<tf-worker1的ENDPOINTS>"
$ cd /var/tf-dist-test/scripts
NUM_WORKERS = 2
NUM_PARAMETER_SERVERS = 2
SETUP_CLUSTER_ONLY = 0
GRPC_SERVER_URLS: grpc://10.1.16.8:2222 grpc://10.1.16.9:2222
SYNC_REPLICAS: 0
The preset GRPC_SERVER_URLS appears to be valid: grpc://10.1.16.8:2222 grpc://10.1.16.9:2222
Will bypass the TensorFlow k8s cluster setup and teardown process

Performing distributed MNIST training through grpc sessions @ grpc://10.1.16.8:2222 grpc://10.1.16.9:2222...
N_WORKERS = 2
N_PS = 2
SYNC_REPLICAS = 0
SYNC_REPLICAS_FLAG = 
Successfully downloaded train-images-idx3-ubyte.gz 9912422 bytes.
Extracting /tmp/mnist-data/train-images-idx3-ubyte.gz
Successfully downloaded train-labels-idx1-ubyte.gz 28881 bytes.
Extracting /tmp/mnist-data/train-labels-idx1-ubyte.gz
Successfully downloaded t10k-images-idx3-ubyte.gz 1648877 bytes.
Extracting /tmp/mnist-data/t10k-images-idx3-ubyte.gz
Successfully downloaded t10k-labels-idx1-ubyte.gz 4542 bytes.
Extracting /tmp/mnist-data/t10k-labels-idx1-ubyte.gz
2 worker process(es) running in parallel...
... // 一堆log
Training ends @ 1466587682.591102
Training elapsed time: 3.068380 s
After 200 training step(s), validation cross entropy = 1644.21
===================================================

Final validation cross entropy from worker0: 1644.21
MNIST-replica test PASSED
SUCCESS: Test of distributed TensorFlow runtime PASSED
```

同目录下的dist_mnist_test.sh与dist_test.sh都是mnist的,不知道有什么区别,可如下命令运行

```
./dist_mnist_test.sh "grpc://<tf-worker0的ENDPOINTS> grpc://<tf-worker1的ENDPOINTS>" --num-workers 2 --num-parameter-servers 2
```

