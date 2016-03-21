Heapster enables Container Cluster Monitoring and Performance Analysis.

Heapster currently supports Kubernetes and CoreOS natively. Heapster is compatible with kubernetes versions starting from v1.0.6 only

It can be extended to support other cluster management solutions easily.

Heapster collects and interprets various signals like compute resource usage, lifecycle events, etc, and exports cluster metrics via REST endpoints. Note: Some of the endpoints are only valid in Kubernetes clusters

Use Kubedash to visualize data exported by Heapster.

```
kubectl create -f https://github.com/kubernetes/kubedash/raw/master/deploy/kube-config.yaml
```

https://github.com/kubernetes/heapster