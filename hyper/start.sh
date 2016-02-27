#!/bin/sh
STORAGE_DRIVER=${STORAGE_DRIVER:-overlay}
echo "StorageDriver=$STORAGE_DRIVER" >> /etc/hyper/config
/usr/local/bin/hyperd --nondaemon --logtostderr -v=3
