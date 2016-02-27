
# Lab 09: Continuous Integration and Continious Delivery(CICD) with Docker, GitHub, and Jenkins

> **Difficulty**: Advanced

> **Time**: 75-90 minutes

> **Tasks**:
> 
> 
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Task 1: Jenkins Setup](#task-1-jenkins-setup)
- [Task 2: Github Repo and Webhooks](#task-2-github-repo-and-webhooks)
- [Task 3: DTR Setup](#task-3-dtr-setup)
- [Task 4: The Build Jobs](#task-4-the-build-jobs)
- [Task 5: The Deploy Job](#task-5-the-deploy-job)
- [Task 6: Deploying the App](#task-6-deploying-the-app)

# Overview

![](images/9_image_0.png)

Docker is the open platform to build, ship and run distributed applications, anywhere. At the core of the Docker solution is a registry service to manage images and the Docker Engine to build, ship and and run application containers.  Continuous Integration (CI) and Continuous Delivery (CD) practices have emerged as the standard for modern software testing and delivery.  The Docker solution accelerates and optimizes CI/CD pipelines, while maintaining a clear separation of concerns between the development and operations teams.

In this lab, you will build and deploy [The Awesome Voting App](https://github.com/nicolaka/example-voting-app) using a CI pipeline consisting of Docker, GitHub, Jenkins, and Docker Trusted Registry (DTR). The pipeline will be kicked off by a commit to a GitHub repository. The commit will cause Jenkins to run (3) build+push to DTR jobs on a Jenkins slave, and upon successful completion of these jobs, pull new images from DTR and deploy the app on Swarm using `docker-compose`. The following diagram illustrates the CI pipeline. 

![](images/9_image_1.png)

The app is deployed using Docker Compose and consists of 5 different containers as follows. 


    voting-app:
      image: $DTR/engineering/voting-app:$GIT_COMMIT
      ports:
        - "5000:80"
    redis:
      image: redis
      ports: ["6379"]
    
    worker:
      image: $DTR/engineering/worker:$GIT_COMMIT
    
    db:
      image: postgres:9.4
    
    result-app:
      image: $DTR/engineering/result-app:$GIT_COMMIT
      ports:
        - "5001:80"


Since we will be using Docker multi-host networking, all containers will be part of the same overlay network and do not require any linking.

**Setup Reference:**

* `node-0` will host DTR, Swarm Manager, Jenkins Master. Consul key-value store
* `node-1` will be a Jenkins Slave and a Swarm Node.
* `node-2` will be a Swarm Node.
* `node-3` will be a Swarm Node.

# Prerequisites

* This lab only works with a cloud-based setup (local Docker Machine setup will not work).
* You will use all four nodes : `node-0`,`node-1`,`node-2`, and `node-3`. 
* This lab requires a Docker Trusted Registry (DTR). See steps below.
* This lab requires multi-host networking. See steps below.
* This lab requires a Swarm cluster. See steps below.
* This lab requires a Github account.
* Docker Compose version 1.5.0 + must be installed on all Swarm nodes. Check using `docker-compose version` on `node-1`,`node-2`, and `node-3`.

**Note :** Throughout this lab, you may be required to substitute the IP of an instance. AWS only allows certain TCP ports on the private AWS network. Therefore, make sure you use the private network (10.X.X.X) when you substitute the IP of the instance.

**Note :** Some of the actions in this lab require `sudo`. Where `sudo` is required, the lab so indicates.

### Install DTR

The following procedure will install DTR on **node-0**.

1. Run the following command on `node-0`

        $ sudo bash -c "$(sudo docker run docker/trusted-registry install)"

    This will automatically download and run the required containers that comprise the Docker Trusted Registry service. It might take a couple of minutes to complete. 

2. Once complete, check if all DTR containers are up using the `docker ps` command. Output will look like the following (there are several containers comprising the DTR service)

        $  docker ps
        CONTAINER ID        IMAGE                                          COMMAND                  CREATED             STATUS              PORTS                                      NAMES
        4494912febf8        docker/trusted-registry-nginx:1.4.2            "nginxWatcher"           12 hours ago        Up 12 hours         0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   docker_trusted_registry_load_balancer
        c9a66b28fbf9        docker/trusted-registry-admin-server:1.4.2     "server"                 12 hours ago        Up 12 hours         80/tcp                                     docker_trusted_registry_admin_server
        eaad8df99c25        docker/trusted-registry-log-aggregator:1.4.2   "log-aggregator"         12 hours ago        Up 12 hours                                                    docker_trusted_registry_log_aggregator
        682c014cf459        docker/trusted-registry-garant:1.4.2           "garant /config/garan"   12 hours ago        Up 12 hours                                                    docker_trusted_registry_auth_server
        21439e31e4b0        postgres:9.4.1                                 "/docker-entrypoint.s"   12 hours ago        Up 12 hours         5432/tcp                                   docker_trusted_registry_postgres
        6b029ece4740        docker/trusted-registry-index:1.4.2            "index"                  12 hours ago        Up 12 hours                                                    docker_trusted_registry_registry_index
        78cf25a17bf4        docker/trusted-registry-distribution:v2.2.1    "registry /config/sto"   12 hours ago        Up 12 hours         5000/tcp                                   docker_trusted_registry_image_storage_1
        840c3c2529ca        docker/trusted-registry-distribution:v2.2.1    "registry /config/sto"   12 hours ago        Up 12 hours         5000/tcp                                   docker_trusted_registry_image_storage_0

3. Browse to the URL of your **Node 0** over HTTPS

	The URL of your **node-0** is the DNS name of your **node-0** AWS isntance and is provided to you as part of this lab. It will look something like `https://ec2-52-91-195-21.compute-1.amazonaws.com`

4. Proceed insecurely when you get a certificate warning
5. Configure **Domain name**, **Authentication**, and **License**
    
    Each of these operations is shown in steps 1 and 2 of Lab 3: DTR.

### Configure multi-host networking

The following procedure will configure the Consul key-value store on `node-0`. This will be used to store network state etc.

1. SSH into `node-0`.

2. Start the Consul container.

        $ docker run -d -p 8500:8500 -h consul --name consul progrium/consul -server -bootstrap
        Unable to find image 'progrium/consul:latest' locally
        latest: Pulling from progrium/consul
        3b4d28ce80e4: Pull complete
        e5ab901dcf2d: Pull complete
        <snip>

3.  Ensure that the container is Up and listening to port 8500

        $ docker ps
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                            NAMES
        3092b9afa96c        progrium/consul     "/bin/start -server -"   35 seconds ago      Up 34 seconds       53/tcp, 53/udp, 8300-8302/tcp, 8301-8302/udp, 8400/tcp, 0.0.0.0:8500->8500/tcp   consul

Follow the procedure below on `node-1`, `node-2`,and `node-3` to configure the Docker daemon to listen on TCP port `2375` and to use the Consul key-value store created in the previous steps.

1. Add the following options to the `DOCKER_OPTS` line in the `/etc/default/docker` file.

        "-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-store=consul://<NODE-0-PRIVATE-IP>:8500/network --cluster-advertise=eth0:2375"

 	Make sure you substitute <NODE-0-PRIVATE-IP> with the private IP of your `node-0` that you just ran the Consul container on.

    > **Note**: node-0 has to be healthy and reachable by `node-1`, `node-2`, and `node-3`.

4. Save and close the file.

5. Restart the Docker Engine for these settings to take effect:

		$ sudo service docker restart
		docker stop/waiting
		docker start/running, process 2003

6. Ensure that each engine restarts successfully:

		$ docker ps
		CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

7. Be sure to execute these steps on all three nodes - `node-1`, `node-2`, and `node-3`.

All three nodes are now configured for multi-host networking.

> **Note:** If you have already ran Lab 6: Networking.  You may wish to execute the following commands on `node-1`, `node-2`, and `node-3`.
>
> 1. `service docker stop`
> 2. `umount /var/run/docker/netns/*`
> 3. `rm /var/run/docker/netns/*`
> 4. `service docker start`
>
> This procedure cleans up any potential networking config from the Networking lab.

### Installing a Swarm cluster

The following procedure will walk you through building a Swarm cluster.

1. Type the following command on `node-0` run an official swarm container with the `create` command and apps the return value to the `TOKEN` environment variable. This token uniquely identifies your Swarm cluster.

        node-0:~$ export TOKEN=$(docker run --rm swarm create)

2. Configure the Swarm Manager on `node-0`. The manager runs in a container and is configured to use a different TCP port (3375) than Engine (2375)

        node-0:~$ docker run -d -p 3375:2375 swarm manage token://$TOKEN

3. Register the Swarm agents to the discovery service

	Perform this step on **node-0**. 

        node-0:~$ docker run -d swarm join --addr=<node_1_private_ip:2375> token://$TOKEN
        node-0:~$ docker run -d swarm join --addr=<node_2_private_ip:2375> token://$TOKEN
        node-0:~$ docker run -d swarm join --addr=<node_3_private_ip:2375> token://$TOKEN

    Be sure to use `node-1`, `node-2`, and `node-3`'s **private IPs** (10.x.x.x) and NOT their public IPs. 

4. Confirm that the two nodes are part of the Swarm cluster:

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

5. Confirm that the Docker server you're talking to is actually Swarm master (shown in the **server version** section).

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

6. One `node-0` point all Docker client commands at the Swarm manager instead of the local engine daemon. To do so, you need to set `DOCKER_HOST` to point at the Swarm Master's IP and TCP port. Remember that the Swarm Master is just a container running and listening on port 3375.

    Remember to replace <node-0-privateIP> with the private IP address of your node-0 AWS instance

        node-0:$ export DOCKER_HOST=<node-0-PrivateIP>:3375

Your lab environment is now configured and ready to proceed with the tutorial.


# Task 1: Jenkins Setup

**Step 1:** Log in to  `node-0` :

    ssh -i <username>.key ubuntu@<username-node-0 IP Address>

**Step 2:** Install a Jenkins Master container locally (not on the Swarm cluster).

    $ docker -H unix:///var/run/docker.sock run -d -p 8080:8080 jenkins

**Step 3:** Using your web browser, go to `node-0`'s domain name/IP using port 8080.

**Step 4:** Go to `Manage Jenkins` > `Configure Global Security`. Click on `Enable Security` then select `Jenkin's own data base`. For Authorization, select `Logged-in users can do anything`. Click on `Apply`  and then `Save`. 


**Step 5:** Create a Jenkins user by clicking on `Create an account` and complete the form. You should be signed in after completing the form. 

**Step 6:** Making `node-1` a Jenkins Slave node:

For this step please make sure that Java is installed on that node (`node-1`). You can do so by performing the following:

    sudo apt-get install -y default-jre

Back in your web browser, go to `Manage Jenkins` > `Manage Nodes` > `New Node`. Name the node "slave1", select the `Dumb node` option and click `OK`.  Fill out the form as follows:

- Name: slave1
- Description: Arbitrary
- # of executors: 1
- Remote root directory: `/home/ubuntu`
- Labels: Leave blank
- Usage: Leave as default
- Launch method: Leave as default
    - Host: Enter `node-1`'s DNS name
    - Credentials: Click `Add`.
      
      On the next page set the username to "ubuntu" and click `Enter key directly`. Paste in the contents of the `.ppk` key file that you use to access your AWS instances. Leave all other options at their default values.

**Step 7:**  In this exercise, no jobs should run on Master node. While still on the `Nodes` dashboard click the **tool** icon to the right of the **master** to configure the master. Make sure that `# of executors` is **0** and click `Save`.

You should see that the new slave (in this case called `slave1`) is added to your Jenkins node:

![](images/9_image_2.png)


**Step 8:** Install Required Jenkins Plugins

We need the following plugins installed: 

- **Github plugin**
- **CloudBees Docker Build and Publish**

Go to `Manage Jenkins` > `Manage Plugins` and select the `Available` tab. Locate the above plugins, place a check in their checkboxes, and install them.

> **Note:** Be sure to select **Restart after Installation** when installing these plugins.

# Task 2: Github Repo and Webhooks

**Step 1:** Log into your Github account and fork the following repo:

	https://github.com/nicolaka/example-voting-app
	
**Step 2:**  Configure Github to trigger Jenkins jobs.

You need the following two things to be able to trigger Jenkins jobs when a new commit is made to your Github repo: 

* Configure GitHub to trigger a webhook to the Jenkins master. 
* Configure Jenkins to pull your repo

Let's look at each of these.

Go to your newly forked GitHub repo. Click `Settings` > `Webhooks & Services` > `Add Service` > search for  `Jenkins (GitHub plugin)` and add the following `Jenkins hook url`: `http://<node_0_url>:8080/github-webhook/`. Click `Add service`. This allows GetHub send an HTTP POST message to the Jenkins Master telling it when the repo has changed.


# Task 3: DTR Setup

The voting app has 5 different microservices. **voting-app, worker, and result-app** are built from the repo that you cloned. The other two, **db and redis**, use standard Docker Hub images. In this task you will create the appropriate DTR repos from the UI and ensure that each of the nodes in the Swarm cluster can pull from/push to DTR successfully. Please remember that you do need to install DTR as instructed in the prerequisites. 

**Step 1:** Creating the `jenkins` DTR user

Go to your web UI and click `Settings` > `Auth`. If you are not already using "managed" authentication, select "Managed" from t he dropdown. Add a new user "jenkins". Configure the account with a password and give it the **Admin - allrepositories** Global role. Click `Save`.  You may need to log back in as the newly created user.

**Step 2:** Creating the Repos.

If you completed the DTR Lab #3, you have already created the `engineering` organization, if not just create it. 

**Note:** You Need to ensure that you create your repos under this organization. The Docker Compose file points to this organization.

Click on `Ogranizations` > `engineering`, and click on `New Repository`. You need to create three repositories **voting-app**, **worker**, and **result-app**. Set them all as **Private** repositories and **Save** as follows:

![](images/9_image_4.png)

**Step 3:** Trusting DTR Certificates on Docker Engines

In order to login successfully into DTR, you need to trust DTR's certificates on each of the Swarm nodes (node-1,node-2,node-3). To do this, carry out the following procedure on all three nodes.

    $ export DTR_DOMAIN_NAME=<DOMAIN NAME OF node-0>
    $ docker run --rm -v /etc/docker/certs.d/:/etc/docker/certs.d/ -e DTR_DOMAIN_NAME=$DTR_DOMAIN_NAME nicolaka/dtr-trust:v1

This will run a container that will trust DTR's certificate automatically.


# Task 4: The Build Jobs

The Voting app has 5 different microservices : `voting-app` , `redis`, `worker`, `db`, and `result-app`.  
`voting-app`, `worker`, and `result-app` are built from the repo that you cloned. The other two (`db` and `redis`) use standard Docker Hub images. You will create three build jobs for building the images required to deploy the app. These build jobs will be triggered independently whenever changes are made to the Github repo. 

**Warning:** Be careful with the info you provide when creating these jobs. You will repeat the following steps **for each** of the 3 build jobs, changing the name of the 3 microservices: `voting-app`, `worker`, and `result-app`. 

**Step 1:**  Go to the Jenkins web UI home page and click the `Create new jobs` link. Choose `Freestyle project`and give it a meaningful name such as "build voting-app". Click `OK`

**Step 2:** Under `Source Code Management` select `Git`. Provide the url to YOUR repo (e.g https://github.com/YOUR_USERNAME/example-voting-app.git). No need for any credentials if the repo is public.

**Step 3:** Under `Build Triggers`, select `Build when a change is pushed to GitHub`.

**Step 4:**  Under `Build` section, select `Docker Build and Publish` option from the dropdown. For each new job created, use the name of the specific image the job will be building (e.g. "voting-app" or "worker"). Enter `engineering/voting-app`,  `engineering/worker`, or `engineering/result-app` as the repository name.

For this example, use `${GIT_COMMIT}` as the tag. This will use Git's sha256 hash as the image tag. 

`Docker Host URI` is the URI for engine where you'd like to BUILD the image, please use `tcp://0.0.0.0:2375`. This means that as Jenkins runs this script on your `node-1`, it will also build the image locally.

**Step 5:** For the `Docker registry URL` enter the DNS name of your DTR server (`node-0`'s DNS name). 

Under `Registry credentials` click `Add`. for `Kind` select `Username with password` and use the `jenkins` username and password that you created in Task #3. Click `Add`. Back at the main `configuration` page make sure that the newly entered `Registry credentials` are selected from the dropdown.

**Step 6:** Under `Advanced settings`, ensure that your `Build Context` path is listed as `vote-apps/voting-app`,`vote-apps/worker`, or `vote-apps/result-app`. This will tell `docker build` to look for a Dockerfile in that directory and NOT in repo's root directory.

Ensure that **Skip tag as latest** is checked.

**Step 7:** Your configs should be as follows. You should then click **Apply** + **Save**.


![](images/9_image_5.png)


**Step 8:** Ensure you repeate the above steps for all three build jobs: **build-voting-app**, **build-worker**, and **build-result-app**. You can create subsequent jobs as copies from the first job by clicking on `New Item` from the top left corner of the screen, choosing the `Copy existing Item` option, and typing in the name of the first job you created.

**Step 9:**  Navigate to the Jenkins home page perform a test build on each job to make sure they work and push an image to DTR. It may take several minutes for your jobs to build. You can monitor their progress by manually refreshing the Jenkins web server home page. You can also see the new tags etc from within the individual repositories via your DTR web UI.




# Task 5: The Deploy Job

You will create a single deploy job for (re)deploying the voting app. Although there are Jenkins plugins to deploy docker containers, deploying using Docker Compose is not supported with these plugins. We will use a bash script to deploy the app! This job will get triggered after the three upstream build jobs are completed successfully.

**Step 1:** Go to `Manage Jenkins` and click `New Item` in the top left corner. Select a new `Freestyle project`. 

**Step 2:** Provide a name for your item (e.g `vote-apps-deploy`) and click `OK`.

**Step 3:** Under Source Code Management select `Git`. Provide the url to your forked repo (e.g `https://github.com/YOUR_USERNAME/example-voting-app`). No need for any credentials if the repo is public.

**Step 4:** Under Build Triggers, select `Build after other projects are built`, and type the names of all three build jobs you created in Task #4 (e.g. `build-voting-app`, `build-worker`, and `build-result-app`).

**Step 5:** Under Build section, select `Execute Shell` and paste the following block of code.

    export DOCKER_HOST=<node-0-DOMAIN-NAME:3375>
    export DTR=<node-0-DOMAIN-NAME>
    docker-compose --x-networking -f vote-apps/docker-compose.yml stop voting-app result-app worker
    docker-compose --x-networking -f vote-apps/docker-compose.yml rm -f 
    docker-compose --x-networking -f vote-apps/docker-compose.yml pull voting-app result-app worker
    docker-compose --x-networking -f vote-apps/docker-compose.yml up -d 

>**Note**: Be sure to substitute "<node-0-DOMAIN_NAME>" with the DNS name of your `node-0` in the top two lines of the code block above.

This script will use Docker Compose to stop and recreate any running services with updated images from DTR.

**Step 6:** click `Apply` and `Save`.

# Task 6: Deploying the App

Now that you have completed both the build and deploy jobs. You can deploy the app using a single git commit!

**Step 1:** On your preferred dev environment (local, docker-machine, or any of the AWS instances), clone the repo from Github.

	git clone https://username@github.com/$YOUR_USERNAME/example-voting-app.git

**Step 2:** Edit the README.md file of the repo and do a Git commit.

    $ cd example-voting-app
    $ echo "#test" >> README.md
    $ git add .
    $ git commit -am "editing README.md"
    $ git push

>**Note**: You may be asked to enter your GitHub username and password

**Step 3** Check the deployment process.

The git push from Step 2 should have triggered the build jobs. If you navigate to your Jenkins server, you should see all 4 jobs running.

![](images/9_image_6.png)

You can also check that your Swarm cluster to confirm. Go to `node-0` and you should see something similar to the following:

    $ export DOCKER_HOST=0.0.0.0:3375
    $ docker ps
    CONTAINER ID        IMAGE                                                                             COMMAND                  CREATED             STATUS              PORTS                        NAMES
    146205a6c39d        <DTR_HOSTNAME>/engineering/result-app:c8653b784d4400bdbc1f748b802bed86ab8d9f0a   "node server.js"         28 seconds ago      Up 28 seconds       10.0.0.165:5001->80/tcp      ip-10-0-0-165/voteapps_result-app_1
    f145673fb808        <DTR_HOSTNAME>/engineering/voting-app:c8653b784d4400bdbc1f748b802bed86ab8d9f0a   "python app.py"          40 seconds ago      Up 39 seconds       10.0.0.164:5000->80/tcp      ip-10-0-0-164/voteapps_voting-app_1
    62890d2fe373        <DTR_HOSTNAME>/engineering/worker:c8653b784d4400bdbc1f748b802bed86ab8d9f0a       "/usr/lib/jvm/java-7-"   41 seconds ago      Up 40 seconds                                    ip-10-0-0-164/voteapps_worker_1
    1c6d0c43cf79        postgres:9.4                                                                      "/docker-entrypoint.s"   57 minutes ago      Up 57 minutes       5432/tcp                     ip-10-0-0-163/voteapps_db_1
    ab2bde390e8a        redis                                                                             "/entrypoint.sh redis"   57 minutes ago      Up 57 minutes       10.0.0.165:32775->6379/tcp   ip-10-0-0-165/voteapps_redis_1


Now you can check out the app from your browser by going the nodes that are either running the `voting-app` or `result-app` on ports 5000 and 5001 respectively.

![](images/9_image_7.png)

You can now edit various components in the repo and with a single commit trigger a full redeployment of the changes. For example, you can change the voting options by editing the `app.py` under `voting-app` module in the repo. 

**Note:** The app containers may be redeployed on different nodes so ensure that you are using the correct DNS name or IP.

# Conclusion

Congrats! You have completed the tutorial!

In this tutorial you learned how to create a full CICD pipeline using Docker, GitHub and Jenkins. You learned how to integrate that workflow with DTR to store the images and Docker Compose to deploy them on a Swarm Cluster.


## Share on Twitter!

<p>
<a href="http://ctt.ec/98GCb" target=“_blank”>
<img src="http://www.wyntercon.com/wp-content/uploads/2015/04/twitter-bird-blue-on-white-small.png" width="100" height="100">
</p>



## Related information

* [Docker and Continuous Integration](https://www.docker.com/products/use-cases)
