# Lab 04: Tutum: Provision, Deploy, Manage

> **Difficulty**: Beginner

> **Time**: 30 Minutes

> **Tasks**
> - [Prerequisites](#prerequisites)
>	- [Task 1: Attaching a New Node](#task-1-attaching-a-new-node)
>	- [Task 2: Deploying a Service](#task-2-deploying-a-service)
>	- [Task 3: Deploying a Stack](#task-3-deploying-a-stack)


# What is Tutum?

Tutum is a cloud-based system for managing Docker infrastructure that allows users to easily:

- Provision any infrastructure, on-premises or in the cloud, and automatically install, configure, and cluster Docker Engines.

- Deploy Docker containers and Docker Compose-defined applications to the provisioned infrastructure from any registry (including Docker Hub).

- Manage updates and scaling of Dockerized apps and infrastructure through a GUI Dashboard, CLI, and RESTful APIs.

## Prerequisites

* To complete this lab you will need a Docker Hub account.
* For this lab you'll be using `node-2`. Be sure there are no containers running on this node.


## Task 1: Attaching a New Node

In Tutum, Docker hosts are referred to Nodes. In this task, you curl the Tutum agent onto one of you AWS-based docker hosts.

### Logging into Tutum

1. Navigate to http://www.tutum.co (use `.co` and not `.com` in the address).

2. Click `Login` in the top right corner of the window

3. Supply your Docker Hub credentials

4. Click `I understand` to dismiss the information about cookie usage

5. Click the `X` to dismiss Bryan’s welcome message

	> **Note:** Tutum has a welcome tour, but we won't be using that for this lab. So, if you see the welcome tour pop up, click to skip the tour in the screen's bottom-right corner.

### Connecting your Docker Host to Tutum

Tutum can manage Docker applications on a wide variety of cloud platforms.
However, for this lab, you're going to use the `Bring your own node` option. This
is not the same thing as linking an AWS account, but it works better for the
lab.

1. Click the `Nodes` tab

2. Click `Bring your own node` near the top right

3. Select the **curl** command in the middle of the window and copy it to the clipboard

4. Using the terminal of your choice, SSH into `node-2`

		ssh -i <username>.key ubuntu@<username-node-2 IP Address>

	> **Note**: If you get a warning that your private key is unprotected, issue
	> the following command:

	>  `chmod 400 <username>.key	`

	> You may also get a warning about an RSA fingerprint. If you do, enter `yes`.

5. Paste the `curl` command into the terminal window of your SSH session

		ubuntu@node-2:~$ curl -Ls https://get.tutum.co/ | sudo -H sh -s 26d1d6a99c8d4c2494c3b01cec2eb687

	You should see a lot of text scroll by ending with:

		tutum-agent start/running, process 5602
		-> Done!

		*******************************************************************************
		Tutum Agent installed successfully
		*******************************************************************************

		You are now ready to deploy containers to this node using Tutum.

6. Exit out of the SSH session

		ubuntu@node-2:~$ exit
		logout
		Connection to 52.29.14.250 closed.

	>**Note**: Your IP Address will be different

7. In your browser, click the `X` in the top right corner of the Bring Your Own Node window

8. Click the `Nodes` tab

9. Click on the name of your newly deployed node

10. On the left hand of the screen press `Click to add deploy tags`

11. Type `HOL` and press Save

    > **Note:** You may have to click save twice

## Task 2: Deploying a Service

A service in Tutum is a collection of containers performing the same role. Using
services makes it easier to scale out your applications. In the steps below,
you'll deploy the “hello world” service in a single container to the node you
imported previously.

1. Click the `Services` tab

2. Click `Create your first service`

3. Click `Public Repositories`

	Use this screen to search Docker Hub for an image to deploy. There are currently over 185,000 public images available on Docker Hub. For this lab, you'll use a Jumpstart. Jumpstarts are repos the Tutum team have created to make it easy to get up and running quickly.

4. Click `Jumpstarts`

5. Click on `Miscellaneous`

6. Click `Select` next to the "tutum/hello-world" repo

7. In Deploy tags type `HOL`

	This is the same deploy tag you just specified for you newly imported node.

8. Click the gray rectangle over the Ports section

9. Click `Published`

10. Click `dynamic` and enter `80` for the port number

11. Click the green check mark next to the port number

12. Click `Create and Deploy`

	The system displays a dialog for your new service.

13. Click `Timeline` and then `Service Start`

	From here you can see the progress of the service creation.

14. After you see the service has successfully started, click endpoints

		This lab only uses a subset of the available Tutum deploy options.

15. Click the arrow next to the container endpoint URL

	Your Hello World website launches in a new browser tab.


## Task 3: Deploying a Stack

A stack is a collection of services that make up an application. Just like services are based on Docker Swarm, stacks are based on Docker Compose.

1. If you haven't already done so, return to Tutum in your browser.

2. Click `Stacks`

3. Click `Create your first stack`

4. Underneath the empty Stackfile text box, click `try ours`

	Tutum creates the following Stackfile:

		web:
  			image: tutum/quickstart-python
  			links:
   				 - redis
  			ports:
    			- "5000:80"
		redis:
  			image: redis
  			
	>**Note**: Stackfiles have similar syntax to Docker Compose files.

	The first line of the Stackfile specifies the name of our service, in this case `web`. You’re going to build a web service based on the `tutum/quickstart-python` image. You'll link the `web` service to the `redis` service (defined below).

	Map port `5000` on the host to port `80` in the container. This mapping allows users to access your service via port `5000`, but Docker  redirect that request to container's port `80`.
	
5. Enter `Lab` for the Stack name above the Stackfile text box

6. Click `Create and Deploy`

 	Tutum displays pop up for your new service.

7. Click `Timeline` and then `Stack Start`

	From here you can see the progress of your Stack being created

8. When this stack is successfully deployed, click `Endpoints`

	The application you created is a simple Python app that increments a counter each time the page is loaded. The number of visits is stored in a Redis cache.

9. Click the arrow to the far right of the service endpoint

	This opens a new browser tab pointing to your newly created service.

10. Refresh the page a few times to see the counter increment

	Service endpoints load balance requests across every container listed under the Container endpoints. They load balance using round robin DNS entries. This simple service only has a single web container, but it is possible to scale your app to have multiple web containers all listed under Container endpoints*

## Conclusion

In this lab you learned how use your own Docker host and configure it as a node in Tutum. You then deployed your first service, and then finally you deployed an application stack. Feel free to continue to explore Tutum.

Try pulling down an Nginx image down from Docker hub, and launching a website (Hint: You’ll need to be sure to map the ports correctly). If you get stuck, ask a moderator or one of your peers for assistance.

### Share on Twitter!

<p>
<a href="http://ctt.ec/9Ce0n" target=“_blank”>
<img src="http://www.wyntercon.com/wp-content/uploads/2015/04/twitter-bird-blue-on-white-small.png" width="100" height="100">
</p>

##Cleaning Up

1. **Delete you stack:** Click `Stacks` in the top menu bar, and select your "Lab" stack. Click `terminate` and then `OK`

2. **Delete your service:** Click `Services` in the top menu bar, and select the hello-world service. Click the trash can icon to the right and then `OK`.


3. **Delete your node:** Click `Nodes` in the top menu bar and click `remove` to the right of the node you configured earlier

4. SSH into **node-2**

5. Remove the tutum agent

		$ sudo apt-get remove tutum-agent
