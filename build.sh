#!/bin/bash

for img in fluentd-elasticsearch elasticsearch_logging_discovery kibana
do
  echo "########    Building Image $img    #########"
  docker build -t "$DOCKER_USERNAME/$img" $img
  docker push "$DOCKER_USERNAME/$img"
done
