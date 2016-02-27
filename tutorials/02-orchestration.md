
# Lab 02 : Docker Orchestration

> **Difficulty**: Advanced

> **Time**: 30-40 minutes

> **Tasks**:
> 
>* [Prerequisites](#prerequisites)
> * [Task 1: Deploy a Multiservice Application (`DockChat`) with Compose](#task-1-deploy-a-multiservice-application-on-a-single-engine)
> * [Task 2: Set Up a Docker Swarm cluster](#task-2-set-up-a-docker-swarm-cluster)
> * [Task 3: Re-deploy DockChat on the Swarm Cluster](#task-3-re-deploy-dockchat-on-the-swarm-cluster)
> * [Task 4: Scale DockChat with Interlock](#task-4-scale-dockchat-with-interlock)

## Prerequisites

* You will be using **node-0,node-1,and node-2**
* Ensure that no containers are running on these nodes(`$ docker rm -f $(docker ps -q)`)
* Ensure that Docker engine uses default daemon options( `DOCKER_OPTS` should be commented out in `/etc/default/docker` file)
* Ensure that DOCKER_HOST is unset ( `$ unset DOCKER_HOST`)
* Certain TCP ports are only allowed on the private AWS network. Therefore, you would need to use the private network (10.X.X.X) when you substitute the IP of the instance in certain commands/configuration files throughout this lab.
* Note: Some commands may require `sudo`. 

# Getting Started with Docker Compose and Swarm

**Background**:

Docker Compose and Docker Swarm are key elements of the Docker Ecosystem. 

**Docker Compose** is an open-source tool to orchestrate building and deploying multi-service, multi-container applications. It relies on a configuration YAML file (default name is **docker-compose.yml**) to build, create, and run containers against a single Docker Engine or Docker Swarm cluster. The YAML configuration file has standard reference commands (full list [here](https://docs.docker.com/compose/yml/)) that  define how the container is created at runtime. Some of the most common commands used are: `build`, `image`, `command`, `ports`, and `links`. 

Docker Compose should be already installed on your machine. To verify, issue the following command on all-nodes and ensure you see the currently installed version.

	$ docker-compose version

Throughout this tutorial you'll be deploying **DockChat**, the new awesome chat app. You'll be performing the following tasks:

1. Use Docker Compose to deploy DockChat on single Docker Engine
2. Create a Swarm cluster with staging and production engines 
3. Use the Swarm cluster to deploy DockChat
4. Scale the app using **Interlock**, an event-driven Docker plugin system


## Task 1: Deploy a Multiservice Application on a single Engine

In this task you will deploy the **DockChat** multiservice app to a single Docker engine.

The app is a simple Python+Mongo chat server composed of two services: **web** and **db**.

The following steps  will walk you through the process.

### Obtaining the app and verifying Docker readiness

1. Use the following command to clone the DockChat repo from GitHub to **node-0**

		node-0:$ git clone https://github.com/nicolaka/dockchat.git
		Cloning into 'dockchat'...
		remote: Counting objects: 54, done.
		remote: Total 54 (delta 0), reused 0 (delta 0), pack-reused 54
		Unpacking objects: 100% (54/54), done.
		Checking connectivity... done.

2. Change directory to `dockchat` and examine the list of files in the repo

		$ cd dockchat
		node-0:~/dockchat$ tree
		.
		├── docker-compose.yml
		├── Dockerfile
		├── README.md
		├── requirements.txt
		├── static
		│   └── style.css
		├── templates
		│   └── form_action.html
		└── webapp.py

		2 directories, 7 files

	You'll notice a Dockerfile for the '**web**' service and a **docker-compose.yml** that describes the app's service configuration. 

3. Inspect the docker-compose.yml with the following command 

		node-0:~/dockchat$ cat docker-compose.yml
		# Mongo DB
		db:
		  image: mongo
		  expose:
		    - 27017
		  command: --smallfiles
		# Python App
		web:
		  build: .
		  ports:
		    - "5000:5000"
		  links:
		   - db:db

	You can see that there are two service descriptions: '**db**' and '**web**'. Each of them define a service with certain build on runtime parameters:

> * **image:{IMAGE_NAME}** will specify the name of the image to use. This needs to be an image that has already been built and available either; locally, on Docker Trusted Registry, or Docker Hub. In this example, you will use the '**mongo**' image directly from Docker Hub.

> * **build:{DOCKERFILE_DIR}** will build an image from the Dockerfile that is in the specified directory. In this case, it's the current directory as indicated by the period `.`. 

> * **command:{CMD}** will specify the command to run in the container when it's created.

> * **ports:{HOST:CONTAINER}** will specify any network host-port mappings.

> * **links:{SERVICE:ALIAS}** will specify container linking parameters. Container linking is a mechanism to automatically provide access, network, and environment parameters for one container to discover and communicate with another container. In this example, we are linking the database container '**db**' to the '**web**' container and giving it the alias '**db**'.

> * **expose:{PORT}** informs Docker that the container listens on the specified network ports at runtime.

4. Before, running the app, you need to ensure that Docker is running locally and the Docker Compose client can connect to it. You can verify this with the following command.

		$ docker-compose ps
		Name   Command   State   Ports
		------------------------------

	Your output should be similar.

### Running the app

You now can build and run the app. 

It is recommended that you build all images **before** you run them. That is why **docker-compose** has the following two options: `build` and `up`.

The `build` option builds an image for every service that has a `build:` parameter in the `docker-compose.yml` file. However, it doesn't actually create any containers from that image. 

The `up` option runs the services described in the `docker-compose.yml` file. The `up` option WILL build the services' images before it runs them. However, it is **recommended** to build all the required images before running the containers.

>**Note:** All remaining `docker-compose` commands must be ran from within the same directory as the `docker-compose.yml` file.

The following steps will build and run the app:

1. Build the app with the `docker-compose build` command

		node-0:~/dockchat$ docker-compose build
		db uses an image, skipping
		Building web
		<snip>
		Successfully built b858d650581e

	Your app may take a minute or two to build.

2. Bring the app up with the `docker-compose up` command

		node-0:~/dockchat$ docker-compose up  
		<snip>
		Creating dockchat_db_1
		Creating dockchat_web_1
		Attaching to dockchat_db_1, dockchat_web_1
		db_1  | 2015-11-06T19:24:40.698+0000 I JOURNAL  [initandlisten] journal dir=/data/db/journal
		db_1  | 2015-11-06T19:24:40.707+0000 I JOURNAL  [initandlisten] recover : no journal files present, no recovery needed
		db_1  | 2015-11-06T19:24:41.102+0000 I JOURNAL  [initandlisten] preallocateIsFaster=true 3.02
		web_1 |  * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
		web_1 |  * Restarting with stat


	The output above means that you have successfully created the web and db containers.

3. Check the app is running by pointing a web browser to `http://{your node-0 public IP address}:5000`. You should see something like this:

	![](images/orchestration-step1-1.png)

4. Stop the app and remove the two containers with the following commands

		node-0:~/dockchat$ Ctrl+C

		node-0:~/dockchat$ docker-compose stop && docker-compose rm -f
		Going to remove dockchat_web_1, dockchat_db_1
		Removing dockchat_web_1 ... done
		Removing dockchat_db_1 ... done


## Task 2: Set Up a Docker Swarm cluster

**Docker Swarm** is native clustering for Docker. It turns a pool of Docker hosts (engines) into a single, virtual host (engine).

Swarm serves the standard Docker API, meaning any tool which already communicates with the Docker daemon can use Swarm to transparently scale to multiple hosts. Some of these tools include: Dokku, Compose, Krane, Flynn, Deis, DockerUI, Shipyard, Drone, Jenkins... and, of course, the Docker client itself.

There are multiple ways to create a Swarm cluster - full details [here](https://github.com/docker/swarm/tree/master/discovery). 

In this exercise you will use the Docker Hub token-based discovery service. You will create a Swarm Cluster with 2 nodes (**node-1** and **node-2**). The *Swarm manager* will be a container running on **node-0**. The two Swarm nodes will be *labeled* for deployment scheduling and filtering purposes.

The following steps will walk you through the process of:

- Configuring the Docker Engines on **node-1** and **node-2** to listen on the network
- Add "staging" and "production" tags/labels to the cluster nodes 
- Restart the Docker daemons on **node-1** and **node-2**

\

1. Configure **node-1** and **node-2** so that both daemons listen on the network and are labeled as follows:
	- **node-1**: labeled as "staging"
	- **node-2**: labeled as "production"

	Edit `/etc/default/docker` on **node-1** to have the following

		DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --label=environment=staging"

	Edit `/etc/default/docker` on **node-2** to have the following

		DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --label=environment=production"




2. Restart Docker on **node-1 and node-2**.

		$ sudo service docker restart

	>**Note:** if Docker Engine TLS verification is enabled, it is recommended to use TCP port 2376 instead of 2375. For the remainder of these exercises, we will not use Docker TLS verification.

3. Use the following command to create a new cluster definition and save it's unique token to an environment variable called '**TOKEN**'. You will use this token for the remainder of the tutorial.

		node-0:~$ export TOKEN=$(docker run --rm swarm create)

4. Configure the Swarm Manager on **node-0**. The manager runs in a container and is configured to use a different TCP port (3375) than engine (2375)

		node-0:~$ docker run -d -p 3375:2375 swarm manage token://$TOKEN

5. Register the Swarm agents to the discovery service

	Perform this step on **node-0**. **Node-1** and **node-2**'s IPs must be accessible from the Swarm Manager (**node-0**). Use the following commands and be sure to <node_x_private_ip> with the **private** IP address asigned to each of your respective nodes.

		node-0:~$ docker run -d swarm join --addr=<node_1_private_ip:2375> token://$TOKEN
		node-0:~$ docker run -d swarm join --addr=<node_2_private_ip:2375> token://$TOKEN

	Be sure to use node-1 and node-2's **private IPs** (10.x.x.x) and NOT their public IPs. 

6. Confirm that the two nodes are part of the Swarm cluster:

	The following command uses the `-H` flag to tell the Docker client to talk to the Swarm manager.

		node-0:$ docker -H tcp://0.0.0.0:3375 info
		Containers: 0
		Images: 0
		Role: primary
		Strategy: spread
		Filters: health, port, dependency, affinity, constraint
		Nodes: 2
		 node-1: ************.compute.amazonaws.com:2375
		  └ Containers: 3
		  └ Reserved CPUs: 0 / 1
		  └ Reserved Memory: 0 B / 3.859 GiB
		  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-26-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
		 node-2: *****************.eu-central-1.compute.amazonaws.com:2375
		  └ Containers: 2
		  └ Reserved CPUs: 0 / 1
		  └ Reserved Memory: 0 B / 3.859 GiB
		  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-26-generic, operatingsystem=Ubuntu 14.04.3 LTS, storagedriver=aufs
		CPUs: 2
		Total Memory: 7.718 GiB
		Name: 5dc162006656

7. Confirm that the Docker server you're talking to is actually Swarm master (shown in the **server version** section).

		node-0:$ docker -H tcp://0.0.0.0:3375 version
		Client:
		 Version:      1.9.0
		 API version:  1.21
		 Go version:   go1.4.2
		 Git commit:   76d6bc9
		 Built:        Tue Nov  3 17:43:42 UTC 2015
		 OS/Arch:      linux/amd64
		
		Server:
		 Version:      swarm/1.0.0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		 API version:  1.21
		 Go version:   go1.5.1
		 Git commit:   087e245
		 Built:
		 OS/Arch:      linux/amd64


## Task 3: Re-deploy DockChat on the Swarm Cluster

Now that we have a Swarm cluster, you can re-deploy DockChat on the Swarm Cluster.

**Step 1 :** The first step is to point all Docker client commands at the Swarm manager instead of a single local engine on **node-0**. To do so, you need to set `DOCKER_HOST` to point at the Swarm Master's IP and TCP port. Remember that the Swarm Master is just a container running and listening on port 3375.

Remember to replace <node-0-privateIP> with the private IP address of your node-0 AWS instance

	node-0:$ export DOCKER_HOST=<node-0-PrivateIP>:3375

**Step 2 :** Currently, **docker-compose** does not support building an image across all Swarm nodes. Therefore, you need to first build the image using the Docker client, tag it, push it to Docker Hub, and use that image in docker-compose.yml file.


	node-0:~/dockchat$ docker login
	Username:
	WARNING: login credentials saved in /root/.docker/config.json
	Login Succeeded
	
	node-0$ docker build -t {Your_Docker_Hub_username}/dockchat:v1 .
	...
	Successfully built 40a0a638005a
	
	node-0$ docker push {Your_Docker_Hub_username}/dockchat:v1
	...
	e2a4fb18da48: Image successfully pushed

**Step 3 :** Now, you need to change `docker-compose.yml` file to deploy on Swarm. The first thing to change would be the source of the '**web**' image as follows:

(-) build: .

(+) image: {Your_Docker_Hub_username}/dockchat:v1


**Step 4 :** We will also use constraints/affinity rules to ensure Swarm selects the right nodes for deployment. Initially, we labeled **node 1** as a "staging" node, and **node 2** as a "production" node. We can specify certain constraints in the `docker-compose.yml` file to ensure the service is deployed on the environment we want. 

Add the following parameters under **BOTH** services (**db** and **web**) in the `docker-compose.yml` file.


(+) environment:

(+)   - "constraint:environment==staging"


The final Compose file should look like this :

	# Mongo DB
	db:
	  image: mongo
	  expose:
	    - 27017
	  command: --smallfiles
	  environment:
	   - "constraint:environment==staging"
	# Python App
	web:
	  image: <your_Docker_Hub_username>/dockchat:v1
	  ports:
	    - "5000:5000"
	  links:
	   - db:db
	  environment:
	   - "constraint:environment==staging"

**Step 5:** Let's rename the file to `staging.docker-compose.yml`. We are doing this because it is recommended to have unique Docker Compose files for each deployment for better version control and deployment isolation. For example, you can easily integrate a CI/CD workflow that deploys to **staging** first using the `staging.docker-compose.yml` then if certain tests succeed deploy to the **production** nodes.

	mv docker-compose.yml staging.docker-compose.yml

**Step 6:** Now, you need to pull the images on all nodes, and deploy and check the services. But this time you need to specify both the custom Docker Compose YAML file **and** a custom project name for this deployment. This is a requirement to ensure unique and correct mapping between configuration file and project.

The `-f` switch allows you to specify a custom YAML file. `-p` allows you to name the project.


	node-0:~/dockchat$ docker-compose -f staging.docker-compose.yml -p dockchat_staging pull
	Pulling db (mongo:latest)...
	node-2: Pulling mongo:latest... : downloaded
	node-1: Pulling mongo:latest... : downloaded
	Pulling web (nicolaka/dockchat:v1)...
	node-1: Pulling nicolaka/dockchat:v1... : downloaded
	node-2: Pulling nicolaka/dockchat:v1... : downloaded
	
	node-0:~/dockchat$ docker-compose -f staging.docker-compose.yml -p dockchat_staging up -d
	
	Creating dockchatstaging_db_1
	Creating dockchatstaging_web_1
	
	node-0:~/dockchat$ docker-compose -f staging.docker-compose.yml -p dockchat_staging ps
	        Name                      Command             State             Ports
	---------------------------------------------------------------------------------------
	dockchatstaging_db_1    /entrypoint.sh --smallfiles   Up      27017/tcp
	dockchatstaging_web_1   python webapp.py              Up      10.0.10.77:5000->5000/tcp



You can also use the "Names" column in the `docker ps` output to verify that both containers were deployed on **node-1** (the staging node). This is because we constrained the deployment of both services only on the **'staging'** nodes. Also, since the two services are linked, Docker Compose will ensure they are deployed on the same node.

**Step 7:** Do the same for the **production** deployment:

	node-0:~/dockchat$ cp staging.docker-compose.yml production.docker-compose.yml

and change the following in the `production.docker-compose.yml`:


(-) - "constraint:environment==staging"

(+) - "constraint:environment==production"


sed is your friend, it can do the replacement for you:

	sed -i "s/staging/production/g"  production.docker-compose.yml 


**Step 8:** Deploy again using the `production.docker-compose.yml` :


	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production pull
	Pulling db (mongo:latest)...
	node-2: Pulling mongo:latest... : downloaded
	node-1: Pulling mongo:latest... : downloaded
	Pulling web (nicolaka/dockchat:v1)...
	node-2: Pulling nicolaka/dockchat:v1... : downloaded
	node-1: Pulling nicolaka/dockchat:v1... : downloaded
	
	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production up -d
	Creating dockchatproduction_db_1
	Creating dockchatproduction_web_1
	
	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production ps
	          Name                       Command             State             Ports
	------------------------------------------------------------------------------------------
	dockchatproduction_db_1    /entrypoint.sh --smallfiles   Up      27017/tcp
	dockchatproduction_web_1   python webapp.py              Up      10.0.11.50:5000->5000/tcp


Using `docker ps`'s NAMES column, note that now the two containers were deployed on Node 2, which is the production node.


	node-0:~/dockchat$ docker ps
	CONTAINER ID        IMAGE                  COMMAND                  CREATED              STATUS              PORTS                       NAMES
	618b949413e4        nicolaka/dockchat:v1   "python webapp.py"       About a minute ago   Up About a minute   10.0.11.50:5000->5000/tcp   node-2/dockchatproduction_web_1
	30e0105aa493        mongo                  "/entrypoint.sh --sma"   About a minute ago   Up About a minute   27017/tcp                   node-2/dockchatproduction_db_1,node-2/dockchatproduction_web_1/db,node-2/dockchatproduction_web_1/db_1,node-2/dockchatproduction_web_1/dockchatproduction_db_1
	f77b3a038ba8        nicolaka/dockchat:v1   "python webapp.py"       3 minutes ago        Up 3 minutes        10.0.10.77:5000->5000/tcp   node-1/dockchatstaging_web_1
	e136e52638bd        mongo                  "/entrypoint.sh --sma"   3 minutes ago        Up 3 minutes        27017/tcp                   node-1/dockchatstaging_db_1,node-1/dockchatstaging_web_1/db,node-1/dockchatstaging_web_1/db_1,node-1/dockchatstaging_web_1/dockchatstaging_db_1
	root@node-0:~/dockchat$

You can check out the app by going to `http://{node-1-PUBLIC IP}:5000` for the **staging** deployment and to `http://{node-2-PUBLIC IP}:5000` for the **production** deployment.

## Task 4: Scale DockChat with Interlock

**DockChat** is becoming very popular and it's getting a lot of traffic! You need to scale it to accommodate the surge in traffic. The good news is that you can use Docker Compose to scale the **web** service to handle more traffic in the **production** deployment. Scaling a service that does host-port mapping (**web**'s TCP Port 5000) will not work because you can only have a single service listen on the host's port 5000. Therefore, you will need to remove host-port mapping to avoid this problem. But then how will you direct traffic to the container? Here comes **Interlock** which is an event-driven plugin that can register new containers to a service.

In this example, you'll use Interlock to dynamically register your **web** service containers to an HAProxy load-balancing service. This way any container that is part of the **web** service can receive traffic directed at that service. Interlock can be easily deployed as a service in Compose!

**Step 1:** Stop the production deployment. We know that sounds silly, but it is needed, as we need to add certain environment variables to the **web** service containers.


	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production stop
	Stopping dockchatproduction_web_1 ... done
	Stopping dockchatproduction_db_1 ... done

**Step 2:** Edit the production.docker-compoe.yml to:

 * Remove host-port mapping for the **web** service ( add `"5000"` instead of `"5000:5000"`).

 * Add the Interlock service using the `ehazlett/interlock:latest` image.

 * Add a JSON-formatted hostname environment variable inside the **web** service containers. This is needed for Interlock to discover these services (`- INTERLOCK_DATA={"hostname":"dockchat.com","domain":"dockchat.com"} `).


Your configuration file should look like:


	# Mongo DB
	db:
	  image: mongo
	  expose:
	   - 27017
	  command: --smallfiles
	  environment:
	   - "constraint:environment==production"
	# Python App
	web:
	  image: nicolaka/dockchat:v1
	  ports:
	   - "5000"
	  links:
	   - db:db
	  environment:
	   - "constraint:environment==production"
	   - INTERLOCK_DATA={"hostname":"dockchat.com","domain":"dockchat.com"}
	interlock:
	  image: ehazlett/interlock:latest
	  ports:
	    - "80:80"
	  volumes:
	    - /var/lib/docker:/etc/docker
	  environment:
	   - "constraint:environment==production"
	  command: "--swarm-url tcp://$DOCKER_HOST --debug --plugin haproxy start"

**Step 3:** Re-deploy the service and check that all containers are up:


	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production pull
	Pulling db (mongo:latest)...
	node-2: Pulling mongo:latest... : downloaded
	node-1: Pulling mongo:latest... : downloaded
	Pulling web (nicolaka/dockchat:v1)...
	node-2: Pulling nicolaka/dockchat:v1... : downloaded
	node-1: Pulling nicolaka/dockchat:v1... : downloaded
	Pulling interlock (ehazlett/interlock:latest)...
	node-2: Pulling ehazlett/interlock:latest... : downloaded
	node-1: Pulling ehazlett/interlock:latest... : downloaded
	
	
	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production up -d
	Creating dockchatproduction_db_1
	Creating dockchatproduction_web_1
	Creating dockchatproduction_interlock_1
	
	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production ps
	             Name                           Command               State               Ports
	--------------------------------------------------------------------------------------------------------
	dockchatproduction_db_1          /entrypoint.sh --smallfiles      Up      27017/tcp
	dockchatproduction_interlock_1   /usr/local/bin/interlock - ...   Up      443/tcp, 10.0.11.50:80->80/tcp
	dockchatproduction_web_1         python webapp.py                 Up      10.0.11.50:32769->5000/tcp


**Step 4:** To test the app from your browser, you need to add a new entry in your local `/etc/hosts` pointing to `dockchat.com` as follows:


	mylaptop$ vim /etc/hosts

	(+) {PUBLIC_IP_OF_NODE-2}   dockchat.com

>**Note:** Be sure to substitute the correct **public** IP address of your node-2.

Then go to `dockchat.com` from your browser and test if it works.

Finally, we need to scale the app, and that can be done easily with the `docker-compose scale` functionality.


	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production scale web=10
	
	Creating and starting 2 ... done
	Creating and starting 3 ... done
	Creating and starting 4 ... done
	Creating and starting 5 ... done
	Creating and starting 6 ... done
	Creating and starting 7 ... done
	Creating and starting 8 ... done
	Creating and starting 9 ... done
	Creating and starting 10 ... done
	
	
	node-0:~/dockchat$ docker-compose -f production.docker-compose.yml -p dockchat_production ps
	
	             Name                           Command               State               Ports
	--------------------------------------------------------------------------------------------------------
	dockchatproduction_db_1          /entrypoint.sh --smallfiles      Up      27017/tcp
	dockchatproduction_interlock_1   /usr/local/bin/interlock - ...   Up      443/tcp, 10.0.11.50:80->80/tcp
	dockchatproduction_web_1         python webapp.py                 Up      10.0.11.50:32769->5000/tcp
	dockchatproduction_web_10        python webapp.py                 Up      10.0.11.50:32771->5000/tcp
	dockchatproduction_web_2         python webapp.py                 Up      10.0.11.50:32770->5000/tcp
	dockchatproduction_web_3         python webapp.py                 Up      10.0.11.50:32775->5000/tcp
	dockchatproduction_web_4         python webapp.py                 Up      10.0.11.50:32777->5000/tcp
	dockchatproduction_web_5         python webapp.py                 Up      10.0.11.50:32774->5000/tcp
	dockchatproduction_web_6         python webapp.py                 Up      10.0.11.50:32773->5000/tcp
	dockchatproduction_web_7         python webapp.py                 Up      10.0.11.50:32772->5000/tcp
	dockchatproduction_web_8         python webapp.py                 Up      10.0.11.50:32776->5000/tcp
	dockchatproduction_web_9         python webapp.py                 Up      10.0.11.50:32778->5000/tcp



Now if you go back to your browser, you'll see that with every time you refresh the page, you're being served from a different **web** container.

Note: you can visit **dockchat.com/haproxy?stats** and log in with `stats/interlock` to view the HAProxy stats for each container.

## Conclusion

Congrats! You have completed the tutorial!

In this tutorial you used Docker Compose and Docker Swarm to deploy and scale a multi-service app.

Interested in scaling **DockChat** horizontally across multiple nodes ? You can do that with the new multi-host networking introduced with Docker 1.9. Check out this [this repo](https://github.com/nicolaka/dockchat-multihost).

### Share on Twitter!

<p>
<a href="http://ctt.ec/2cUZ6" target=“_blank”>
<img src="http://www.wyntercon.com/wp-content/uploads/2015/04/twitter-bird-blue-on-white-small.png" width="100" height="100">
</p>

## Clean up

If you plan to do another lab, you need to cleanup your EC2 instances. Cleanup removes any environment variables, configuration changes, Docker images, and running containers. To do a clean up, log into each EC2 instance and run the following:

```bash
$ source /home/ubuntu/cleanup.sh
```

## Related information

* [Docker Swarm ](https://www.docker.com/docker-swarm)
* [Docker Compose ](https://www.docker.com/docker-compose)
* [Dockchat Repo](https://github.com/nicolaka/dockchat)
