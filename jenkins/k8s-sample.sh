#!/bin/bash
set -e
set -x

export GOPATH=$WORKSPACE
export PATH=$PATH:$GOPATH/bin

go get github.com/tools/godep

mkdir -p $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes.git $GOPATH/src/k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
./hack/install-etcd.sh
./hack/build-go.sh


