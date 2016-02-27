hyperkube
-----------

Dockerfile to build hyperkube image for hypernetes

Usage:

```
docker pull feisky/hyperkube
```

Check `docker-compose.yml` to start a hypernetes controller node. You can
interact with it with `kubectl`:

```sh
$ kubectl -s=http://localhost:8081 get services
NAME         CLUSTER_IP   EXTERNAL_IP   PORT(S)   SELECTOR   AGE
kubernetes   10.254.0.1   <none>        443/TCP   <none>     1m
```
