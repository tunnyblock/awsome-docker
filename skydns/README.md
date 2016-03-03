Skydns for kubernetes
======================

The DNS server itself runs as a Kubernetes Service. This gives it a stable IP
address. When you run the SkyDNS service, you want to assign a static IP to use
for the Service. For example, if you assign the DNS Service IP as 10.0.0.10,
  
  you can configure your kubelet to pass that on to each container as a DNS
  server.

  Of course, giving services a name is just half of the problem - DNS names
  need a domain also. This implementation uses a configurable local domain,
  which can also be passed to containers by kubelet as a DNS search suffix.


If you are not using a supported cluster setup, you will have to replicate some
of this yourself. First, each kubelet needs to run with the following flags
set:

`--cluster-dns=10.254.10.254 --cluster-domain=hypernetes.local`
