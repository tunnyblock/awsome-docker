#!/bin/bash

for img in `ls`; 
do
  if [ -d $img ]; then
    docker build -t $DOCKER_USERNAME/$img $img
    docker push $DOCKER_USERNAME/$img
  fi
done
