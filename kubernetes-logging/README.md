Kubernetes cluster logging
==========================


```shell
kubectl create -f namespace
kubectl create -f elasticsearch-kibana
kubectl create -f fluentd
```

Visit elasticsearch at <http://k8s:8080/api/v1/proxy/namespaces/kube-system/services/elasticsearch-logging/_search?pretty=true>

Visit Kibana at <http://k8s:8080/api/v1/proxy/namespaces/kube-system/services/kibana-logging>
