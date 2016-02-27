# Lab 07 : Understanding Docker Volumes
> **Difficulty**: Intermediate

> **Time**: 30 minutes

> **Tasks**
- [Prerequisites](#prerequisites)
- [Task 1: Implementing a volume via the Docker client](#task-1-implementing-a-volume-via-the-docker-client)
- [Task 2: Understand how Docker represents volume data in the file system](#task-2-understand-how-docker-represents-volume-data-in-the-file-system)
- [Task 3: Deleting a volume](#task-3-deleting-a-volume)
- [Task 4: Map a host directory to a Docker volume](#task-4-map-a-host-directory-to-a-docker-volume)
- [Task 5: Use a volume to share data between containers](#task-5-use-a-volume-to-share-data-between-containers)

## What are Docker data volumes?

A data volume is a specially designated directory within one or more containers that bypasses Docker’s storage driver and interacts directly with the host file system. Data volumes provide several useful features for persistent or shared data:

* Volumes are initialized when a container is created. If the container’s base image contains data at the specified mount point, that existing data is copied into the new volume upon volume initialization.
* Data volumes can be shared and reused among containers.
* Changes to a data volume are made directly to the host filesystem (vs. going through the storage driver)
* Changes to a data volume will not be included when you update an image.
* Data volumes persist even if the container itself is deleted.

Data volumes are designed to persist data, independent of the container’s lifecycle. Docker therefore never automatically deletes volumes when you remove a container, nor will it "garbage collect" volumes that are no longer referenced by a container.

## Prerequisites
For this lab, please use `node-0` and ensure no containers are running on that node. To check for running containers use the `docker ps` command.

## Task 1: Implementing a volume via the Docker client
In this task, you're going to create a new container and add a file to it.

1. SSH into your `node-0` AWS instance with your supplied credentials, for example:

		ssh -i user23.pem ubuntu@ec2-52-24-109.us-west-2.compute.amazonaws.com`

    > **Note:** Your .pem filename and instance name will be different to those shown above. 

2. Pull down the official Nginx image.

		$ docker pull nginx

3. Create a new volume named `barcelona`.

		$ docker volume create --name barcelona

	Your new volume is created on the host in the `/var/lib/docker/volumes`
	directory.

4. List the volumes on your Docker host

 		$ docker volume ls
		DRIVER              VOLUME NAME
		local               barcelona

	You should see the `barcelona` volume listed. You may see other volumes as well.

5. Instantiate a Docker container with your `barcelona` volume.

	 	$ docker run -it -v barcelona:/barcelona --name volumeslab nginx /bin/bash

	This command creates an Nginx container named `volumeslab`. It also mounts
	your volume `barcelona`	at `/barcelona` in the root of the container's file
	system. Then, the `/bin/bash` command opens an interactive shell inside the
	container.

	You are at your running container's shell prompt.

6. Change into the `/barcelona` directory.

		$ cd /barcelona

7. Create a file.

		$ touch file.txt

8. List the directory contents to make sure the file exists.

		$ ls
		file.txt

9. Press `Ctrl+P` and `Ctrl+Q` to exit the container shell.

	This key combination leaves the container running. You should return to your Docker host's shell.

10. Ensure your container is still running:

		$ docker ps

	The output should be similar to:

		CONTAINER ID   IMAGE   COMMAND         CREATED             STATUS                           
		0124480582a2   nginx   "/bin/bash"     6 minutes ago       Up 6 minutes                           
	The `STATUS` should show `Up` instead of `Exited`

## Task 2: Understand how Docker represents volume data in the file system

Docker manages volumes independently from the storage driver system it uses to manage the container layers. This allows for data persistence; The volume is not destroyed when the container is destroyed.

In this task, you're going to take a quick look at where Docker stores volume data. Then, you'll change the volume on the Docker host file system and see the change appear in the container.

1. Inspect the `barcelona` volume values.

		$ docker volume inspect barcelona

	Your output should be similar to:
	
 		[
   			{
        		"Name": "barcelona",
        		"Driver": "local",
        		"Mountpoint": "/var/lib/docker/volumes/barcelona/_data"
    		}
		]

	The volume mount point above is: `/var/lib/docker/volumes/barcelona/_data`

2. Elevate your user privileges:

		$ sudo su

	You need superuser privileges to view the location of the Docker volume data in your host filesystem.

3. Change to the `barcelona` data directory.

		$ cd /var/lib/docker/volumes/barcelona/_data

4. List the directory contents.

		$ ls
		file.txt

	Notice the file you previously created `file.txt` is listed in the host directory.

5. Create a new file.

		$ touch file2.txt

6. Check that`file.txt` and `file2.txt` are in the directory.

		$ ls
		file2.txt file.txt

7. Log back into the Nginx container's shell.

		$ docker exec -it volumeslab /bin/bash

8. List the contents of the `/barcelona` directory.

		$ ls /barcelona
		file.txt file2.txt

	 The file you created from the Docker host shell `file2.txt` should
	 appear inside your running container.

9. Exit the container and return to your Docker host.

		$ exit

## Task 3: Deleting a volume

By default, when you destroy a container Docker does not remove any volumes associated with the container. You can, however, delete a given volume with the `docker volume rm` command.

1. Stop the `volumeslab` container you created.

		$ docker stop volumeslab

2. Remove the container.

		$ docker rm volumeslab

	Removing the containers does not remove the `barcelona` volume the container was using.

3. Ensure the `barcelona` volume still exists.

		$ docker volume ls
		DRIVER              VOLUME NAME
		local               barcelona

	You may see other volumes listed in addition to `barcelona`.

4. Elevate your privileges.

		$ sudo su

5. List the contents of the `barcelona` volume directory.

		$ ls /var/lib/docker/volumes/barcelona/_data
		file.txt file2.txt

	The volume and its data are still intact.

6. Exit elevated privileges.

		$ exit

7. Remove the volume.

		$ docker volume rm barcelona
		barcelona

8. Ensure the volume was removed.

		$ docker volume ls
		DRIVER              VOLUME NAME

	The `barcelona` volume is no longer listed, although other volumes may be.

## Task 4: Map a host directory to a Docker volume

In the previous exercises, you were able to manipulate data files in a Docker volume via the host file system,. However, it was a bit cumbersome. You had to learn the mount point via `docker volume inspect` and elevate your privileges to create a new file. In practice, this workflow is impractical.

Thankfully there is an easier way to make local files available inside a running container. You can, instead, mount existing local files and directories  as volumes into a running container. This allows developers, for instance, to hot-mount code into their containers, and have changes made locally reflected instantaneously in their containers.

In this example, you'll create two containers `foo` and `bar`. You'll modify some HTML in `bar` and then see how the changes are reflected immediately on the container-based website in `foo`. Additionally, you'll create a volume using the `-v` option with the `docker run` command.  The lab switches between the containers so stay sharp as you read!

1. Create a `www` subdirectory on your Docker host.

		$ mkdir ~/www

2. Change into the `www` directory.

		$ cd ~/www

3. Create an `index.html` file with some content.

	Be sure to use single quotes in the command/

		$ echo '<h1>Hola Barcelona!</h1>' > index.html

4. Instantiate an Nginx container with the `~/www` directory.

		$ docker run -d -v ~/www:/usr/share/nginx/html --name mywebserver -p 80:80 nginx

	This command maps the `~/www` directory on the host to `/usr/share/nginx/html`
	in the running container. The `usr/share/nginx/html` is the default directory
	for serving web content with Nginx.

5. In your browser navigate to the  `http://<docker host>` address.

	For the, `<docker host>` use the name provided to you when you signed up for
	this lab. Your browser should display a website with your `Hello, Barcelona`
	message.

6. Return to your Docker host’s terminal window.

7. Update the index.html file.

	Be sure to use single quotes as shown.

		$ echo '<h1>Adios Barcelona!</h1>' > index.html

7. Reload your website in your browser,

	The change to the local filesystem is immediately reflected by the running
	Nginx container.

## Task 5: Use a volume to share data between containers

You can also use volumes to share data between containers. For instance, one container could write data to a log file, and a second container could read that data and provide a graphical interpretation.

In this example, you'll create a new file from one container in a directory that is a mount point for a named container. Then, you'll list the directory from another container.

**Note**: This example is purely for academic purposes. In a real-world deployment, it’s extremely dangerous to have multiple containers writing to the same volume without adequate application awareness and protection against conflicts.

1. Create a new named volume `shared-data`.

		$ docker volume create --name shared-data
		shared-data

2. Create a new container `foo` and mount the `shared-data` volume.

		$ docker run -it -v shared-data:/foo --name foo nginx /bin/bash

	This command mounts `shared-data` to the `/foo` directory and logs you into the container's shell.

3. Create a new file in the `/foo` directory.

	In the command below, be careful to use the right single quote (‘) and double quotes (").

		$ echo 'Tu dices "hola"' > /foo/file.txt

	The `/foo` directory is mapped to your `shared-data` volume.

4. Verify the content of your new file.

		$ cat /foo/file.txt
		Tu dices "hola"

5. Press `Ctrl-P` and then `Ctrl-Q` on you keyboard.

	This exits the container shell but leaves the container running.

6. Create a second, `bar` container.

 	The command mounts the existing `shared-data` volume to the container's `/bar` directory and starts a shell.

		$ docker run -it -v shared-data:/bar --name bar nginx /bin/bash

	You are now working in the shell of your Docker container.

7. Create a new file in the `/bar` directory.

	Be careful to use the right single quote (‘) and double quotes ("). Also, be sure to use `>>` double pipes otherwise you will overwrite your original file.

		$ echo 'Y yo digo "adios"' >> /bar/file.txt

8. Verify the content of your new file.

		$ cat /bar/file.txt
		Tu dices "hola"
		Y yo digo "adios"

	The text you created in the first container (`Tu dices "hola"`) is still accessible in this container	as well as the text you just added  (`Y yo digo “adios”`).

9. Exit the `bar` container.

		$ exit

	This closes the shell and stops the container.

10. Log back into the shell of the `foo` container.

		$ docker exec -it foo /bin/bash

	You are now working in the shell of your Docker container.

11. Look for the changes you made in the `bar` container in this container.

		$ cat /foo/file.txt
		Tu dices "hola"
		Y yo digo "adios"

12. Exit and stop the `foo` container.

		$ exit

## Conclusion

In this lab, you learned the basics of Docker volumes. You created a new Docker volume using the Docker client, and then explored the host file system to understand the relationship between the local file system and the mounted volume in the container. You then deleted the volume, and mapped a new volume to a specific directory on the host file system. Finally we looked at how you can share a volume between multiple containers.

Feel free to continue exploring Docker volumes.

### Share on Twitter!

<p>
<a href="http://ctt.ec/qG30I" target=“_blank”>
<img src="http://www.wyntercon.com/wp-content/uploads/2015/04/twitter-bird-blue-on-white-small.png" width="100" height="100">
</p>


## Cleanup

If you plan to do another lab, you need to cleanup your EC2 instances. Cleanup removes any environment variables, configuration changes, Docker images, and running containers. To do a clean up,

1. Log into each EC2 instance you used and run the following:

		$ source /home/ubuntu/cleanup.sh
