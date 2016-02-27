#!/bin/bash
mkdir -p /tmp/go
export GOPATH=/tmp/go
export PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tmp/go/bin

curl -sL https://storage.googleapis.com/golang/go1.5.1.linux-amd64.tar.gz | tar -C /usr/local -zxf -
go get github.com/tools/godep

mkdir -p $GOPATH/src/k8s.io
git clone https://github.com/hyperhq/hypernetes.git $GOPATH/src/k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
hack/build-go.sh cmd/hyperkube
cp _output/local/bin/linux/amd64/hyperkube /hyperkube
chmod a+rx /hyperkube

rm -rf $GOPATH
