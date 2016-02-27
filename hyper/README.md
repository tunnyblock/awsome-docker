Docker images for hyper

```sh
cid=$(docker run --net=host --privileged -itd feisky/hyper)
docker exec $cid hyper run nginx
```

Issues:

* exec hijack error: inappropriate ioctl for device
* Need privileged and host net

NOTE: Just a playground, do not use this in production.
