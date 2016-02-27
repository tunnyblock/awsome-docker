# DockerCon EU 2015 Hands-On Labs (HOL)

![dceu](http://europe-2015.dockercon.com/assets/Docker_Euro_Largelogo-1c4ec95d91a66c91f44c831a65d2147d.png)

Welcome to DockerCon! This repo contains a series of hands-on labs to help you gain experience in various Docker features, products, and solutions. Depending on your experience, each lab requires between 15-30 minutes to complete. They range in difficulty from easy to advanced.

If you are at DockerCon EU 2015, you must register before beginning the labs. When you register, Docker Labs provisions the Amazon EC2 instances with the software you need for each lab. You'll receive an email with connection information. Begin by following this procedure here:

**[Set up your system for the labs](0-setup.md)**

Then, go onto to complete the labs.

## Contribute Your Own Labs

If you have an awesome tutorial/lab and would like to add it here. Please open a PR. We would love to add more exciting tutorials to the list!


## Lab 01. [Introduction to Docker](01-docker-introduction.md)
**Difficulty**: Easy

A basic introduction to Docker operations. You learn about Docker Engine image search, pulling and pushing images, creating new images from Dockerfiles, and running and troubleshooting containers.


## Lab 02. [Docker Orchestration Tools](02-orchestration.md)
**Difficulty**: Intermediate

You'll explore Docker Orchestration Tools ( mainly Swarm and Compose). You'll learn how to set up a Swarm cluster using the token discovery option, how Compose works ( including Compose files best practices), and how to deploy and troubleshoot multi-service, multi-container application across the Swarm cluster.

## Lab 03. [Docker Trusted Registry](03-dtr.md)
**Difficulty**: Easy

In this lab, we will examine Docker Trusted Registry (DTR). You'll go through DTR installation, authentication setup, storage backend configuration, monitoring, security, and other various enterprise-level supported features.


## Lab 04. [Tutum: Provision, Deploy, Manage](04-tutum-basics.md)
**Difficulty**: Intermediate

The goal of this lab is help you gain an understanding of Docker’s SaaS-based management platform, Tutum. By the end of the lab you should:

* understand what Tutum is, and the basic capabilities it provides
* know how to create a Docker host in AWS using Tutum
* instantiate and scale Docker containers using
* be able to deploy a multi-container application with Tutum


## Lab 05. [Docker Content Trust](05-content-trust.md)
**Difficulty**: Magic

In this lab, you'll examine how Docker Notary feature works. You'll be creating signed images, distributing them through Docker Hub, and ensuring that only trusted images can be distributed in your environment.



## Lab 06. [Docker Networking](06-networking.md)
**Difficulty**: Advanced

In this lab, you'll examine how the new Docker multi-host networking works. You'll create networks that spread across multiple Docker engines. You'll also learn how to create key/value stores to distribute network data across the hosts, and how to allow multi-host containers to communicate without host port binding.


## Lab 07. [Understanding Docker Volumes](07-volumes.md)
**Difficulty**: Intermediate

In this lab, you'll learn the fundamentals of using Docker data volumes. You'll look at the various methods for attaching data volumes, and how they are represented in the host file system. You'll also look at how to use host-based data volumes to hot mount content into a container, and how to use host-only data containers to allow for sharing of common data between multiple containers.


## Lab 08. [Automated Builds with Docker Hub and GitHub](08-Automated-builds.md)
**Difficulty**: Intermediate

In this lab, you'll examine how to use GitHub and Docker hub to create a basic continuous delivery workflow. You'll learn how to integrate the two systems together such that when a change is pushed the GitHub repository, an image is automatically built, and pushed to Docker Hub.


## Lab 09. [Continuous Integrationn and Continious Delivery(CICD) with Docker, GitHub, and Jenkins](09-cicd-with-docker.md)
**Difficulty**: Advanced

In this lab, you will build and deploy The Awesome Voting App using a CI pipeline consisting of Docker, GitHub, Jenkins, and Docker Trusted Registry (DTR). The pipeline will be kicked off by a commit to a GitHub repository. The commit will cause Jenkins to run (3) build+push to DTR jobs on a Jenkins slave, and upon successful completion of these jobs, pull new images from DTR and deploy the app on Swarm using docker-compose

## Lab 10. [Logging and Monitoring with ELK](10-logging-and-monitoring.md)
**Difficulty**: Easy

In this lab, you will set up a simple Elasticsearch, Logstash and Kibana stack and perform basic queries.

## Lab 11. [Infrastructure as code - Dockerfile best practices](11-infrastructure-as-code.md)

In this lab, you will optimize building Docker images. 

## Lab 12. [Docker Universal Control Plane](12-ducp.md)

In this lab, you will learn the basics of working with Docker Universal Control Plane


**Modified from https://github.com/docker/dceu_tutorials**.

