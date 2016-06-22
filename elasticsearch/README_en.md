docker-elasticsearch-kubernetes
=========================================

[Elasticsearch for Kubernetes](https://github.com/kubernetes/kubernetes/tree/release-1.2/examples/elasticsearch) uses Elasticsearch v1.7.1, but the maintainer of [docker-elasticsearch-kubernetes](https://github.com/pires/docker-elasticsearch-kubernetes) provides newer Elasticsearch version images. To perform automatic pod discovery, [docker-elasticsearch-kubernetes](https://github.com/pires/docker-elasticsearch-kubernetes) needs [Kubernetes Cloud Plugin for Elasticsearch](https://github.com/fabric8io/elasticsearch-cloud-kubernetes) which is based on [offical Elasticsearch image](https://github.com/docker-library/elasticsearch) but don't provide a dockerfile.


Build
============
```
docker build -t <name>/es .
```


Run
============
```
kubectl create -f kubernetes.yml
```


Scale
============
```
kubectl scale --replicas 3 rc/elasticsearch-master
kubectl scale --replicas 2 rc/elasticsearch-client
kubectl scale --replicas 2 rc/elasticsearch-data
```

See [pires/kubernetes-elasticsearch-cluster](https://github.com/pires/kubernetes-elasticsearch-cluster) for instructions on how to use Elasticsearch on Kubernetes.

See [Kubernetes Cloud Plugin for Elasticsearch](https://github.com/fabric8io/elasticsearch-cloud-kubernetes) for instructions on how to make this plugin work.
