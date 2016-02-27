# Lab 10 : Setting up an ELK stack

> **Difficulty**: Easy

> **Time**: 15 minutes

> **Tasks**:
>
* [Introduction](#introduction)
* [Task 1: Allocate storage space for logs](#task-1-allocate-space)
* [Task 2: Compose containers](#task-2-compose-containers)
* [Task 3: Connect and browse logs](#task-3-browse-logs)

## Introduction

One of the more popular logging stacks ELK. It is composed of Elasticsearch, Logstash and Kibana  (ELK). This lab will show you how to setup a simple deployment that can be used for logging.

## Task 1: Allocate storage space for logs

We are all about containers, so our logging solution will be containerized!

1. Lets create volume where we can store some log data

		$ docker volume create --name orca-elasticsearch-data

2. Check that the volume created successfully

		$ docker volume ls
		DRIVER              VOLUME NAME
		local               orca-elasticsearch-data
	
	Other volumes may appear in the list above.

## Task 2: Compose containers

1. Run the following three containers - elastisearch, logstash, and kibana:

   	    $ docker run -d --name elasticsearch -v orca-elasticsearch-data:/usr/share/elasticsearch/data elasticsearch elasticsearch -Des.network.host=0.0.0.0

   	    $ docker run -d -p 514:514 --name logstash --link elasticsearch:es logstash sh -c "logstash -e 'input { syslog { } } output { stdout { } elasticsearch { hosts => [ \"es\" ] } } filter { json { source => \"message\" } }'"

   	    $ docker run -d --name kibana --link elasticsearch:elasticsearch -p 5601:5601 kibana

2. Verify all three containers are running.

		docker ps
		CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
		922b7b4fb477        kibana              "/docker-entrypoint.s"   42 seconds ago       Up 42 seconds       0.0.0.0:5601->5601/tcp   kibana
		04fd46e25ab1        logstash            "/docker-entrypoint.s"   About a minute ago   Up About a minute   0.0.0.0:514->514/tcp     logstash
		5a561ce45cce        elasticsearch       "/docker-entrypoint.s"   3 minutes ago        Up 3 minutes        9200/tcp, 9300/tcp       elasticsearch


## Task 3: Connect and browse logs

Now that the three containers are up and running, you can view logs.



1. Point your web browser to your node on port 5601

	Example: `http://ec2-52-90-128-138.compute-1.amazonaws.com:5601/`
	
	From here you can browse and search log/event entries. 

	>**Note:** When deploying in production environments, you should secure kibana (not described in this doc).

2. Perform some example searches

	- Show all the modifications on the system

		`type:"api" AND (tags:"post" OR tags:"put" OR tags:"delete")`

	- Show all access from a given user

		`username:"admin"`

	- Show all authentication failures on the system

		`type:"auth fail" `


Now that we have a logging solution setup, we can later instruct DUCP to use our logging solution to aggregate logging.

## Conclusion

At this point you have successfully set up a simple ELK stack and ran common log queries.


## Clean up

If you plan to do another lab, you need to cleanup your AWS EC2 instances. Cleanup removes any environment variables, configuration changes, Docker images, and running containers. To do a clean up, log into each EC2 instance and run the following:


	$ source /home/ubuntu/cleanup.sh


## Related information
