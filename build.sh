#!/bin/bash

for img in fluentd-elasticsearch hyper elasticsearch_logging_discovery kibana shadowsocks
do
  echo "########    Building Image $img    #########"
  docker build -t "$DOCKER_USERNAME/$img" $img
  docker push "$DOCKER_USERNAME/$img"
done
