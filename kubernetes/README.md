# Run kubernetes inside docker

`docker-compose up`

# Test it out

Install kubectl for OS X:

```sh
$ wget
http://storage.googleapis.com/kubernetes-release/release/v1.1.1/bin/darwin/amd64/kubectl
$ chmod 755 kubectl
$ PATH=$PATH:`pwd`
```

Or install kubectl for Linux:

```sh
$ wget
http://storage.googleapis.com/kubernetes-release/release/v1.1.1/bin/linux/amd64/kubectl
$ chmod 755 kubectl
$ PATH=$PATH:`pwd`
```

Run get nodes command:

```sh
kubectl -s http://docker-server:8080 get nodes
NAME           LABELS                                STATUS    AGE
e5d19eb403d1   kubernetes.io/hostname=e5d19eb403d1   Ready     10m
```
