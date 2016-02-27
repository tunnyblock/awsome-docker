# Lab 11: Infrastructure as Code: Image building best practices

> **Difficulty**: Easy
>
> **Time**: 20 minutes
>
> **Tasks**:
>
>* [Prerequisites](#prerequisites)
>* [Task 1: Review Dockerfile](#task-1-review-the-unoptimized-dockerfile)
>* [Task 2: Inspect and build from the unoptimized Dockerfile](#task-2-inspect-and-build-from-the-unoptimized-dockerfile)
* [Task 3: Optimize the Dockerfile and image](#task-3-optimize-the-dockerfile-and-image)

## What is a Dockerfile?
A Dockerfile is a manifest that has instructions on what goes into a docker image. Because all commands are expressed as plain text, the image can be reconstructed in a predictable and automated manner if necessary.

Almost every line in a Dockerfile will create a new image layer when built. Therefore, keeping the number of layers to a minimum, without impacting the readability of the Dockerfile, is vital to building optimized images.

## A Good Dockerfile = Optimized Docker image

In this lab, we'll take an existing unoptimized Dockerfile and apply best practices to it. This will reduce the number of layers produced when building form the Dockerfile. This will also translate to faster image pulls as well as smaller overall image sizes. Subsequent `docker build` invocations should adequately utilize the build cache and we'll understand how to avoid some common pitfalls during the building of images. We will also use accepted conventions to mark metadata (in the form of labels) as described [here](https://docs.docker.com/engine/userguide/labels-custom-metadata/).

In other words, we'll optimize and unoptimized Dockerfile. 

Remember, optimization is a process, not a destination. We will therefore, use a process of incremental optimization to improve the Dockerfile. Using a version control system (Git, SVN, Perforce etc) is recommended to track changes and quantitatively measure improvements.

## Prerequisites

* Any node with Docker engine (>=1.9) installed.
* A file editor (vi, emacs, nano).
* A version control respository (Git, SVN Perforce etc) *Not shown here.*

## Task 1: Review the unoptimized Dockerfile

	FROM ubuntu
	MAINTAINER user@acme.com
	RUN apt-get update
	RUN apt-get install -y curl
	RUN apt-get install -y python-all
	RUN apt-get install -y nginx
	RUN rm -rf /var/lib/apt/lists/*
	COPY index.html /usr/share/nginx/html
	EXPOSE 80
	LABEL vendor=Acme\ Example\ Corp.
	LABEL version="0.9.0-beta"
	LABEL is-beta=true
	LABEL release-date="2016-01-01"
	CMD ["nginx", "-g", "daemon off;"]

## Task 2: Inspect and build from the unoptimized Dockerfile

1. Create a folder called `nginx` under `/home/ubuntu` and navigate into it: 

		$ mkdir ~/nginx && cd ~/nginx

2. Using your preferred text editor (`vi` and `nano` are installed on your lab nodes) create a file called `Dockerfile` inside the `~/nginx` folder and copy the contents of the Dockerfile shown in Task 1.

	Be sure to use a capital "D" when creating your `Dockerfile`.

3. Save and exit your `Dockerfile`
		
4. Create a file `index.html` in the same folder with the following basic HTML content

		$ echo '<h1>Hello World</h1>' > index.html

5. Build an image from the Dockerfile

		$ docker build -t nginx-img:0.1 .

	Do not omit the trailing period (.) in the previous command.
	
	It will take a few minutes to build the image.

6. Use the `docker history` command to view how many layers, and each layer size, in the newly built image.

		$ docker history nginx-img:0.1
    
	You should see output similar to below:
   
		IMAGE               CREATED              CREATED BY                                      SIZE                COMMENT
		af1e357c08b1        53 seconds ago       /bin/sh -c #(nop) CMD ["nginx" "-g" "daemon o   0 B
		665b0be837a1        53 seconds ago       /bin/sh -c #(nop) LABEL release-date=2016-01-   0 B
		e7116bdcdcef        53 seconds ago       /bin/sh -c #(nop) LABEL is-beta=true            0 B
		f15b10af432f        54 seconds ago       /bin/sh -c #(nop) LABEL version=0.9.0-beta      0 B
		e9eb3d51b24e        54 seconds ago       /bin/sh -c #(nop) LABEL vendor=Acme Example C   0 B
		bb337f0c5e3c        54 seconds ago       /bin/sh -c #(nop) EXPOSE 80/tcp                 0 B
		72957a9cbf5a        54 seconds ago       /bin/sh -c #(nop) COPY file:d0411b7ac48ed3171   21 B
		d28ef2970965        54 seconds ago       /bin/sh -c rm -rf /var/lib/apt/lists/*          0 B
		7d8e6240468d        55 seconds ago       /bin/sh -c apt-get install -y nginx             18.29 MB
		042e7a731dce        About a minute ago   /bin/sh -c apt-get install -y python-all        23.59 MB
		db2a32d8c546        About a minute ago   /bin/sh -c apt-get install -y curl              11.39 MB
		06e9d2d8bd27        About a minute ago   /bin/sh -c apt-get update                       21.43 MB
		e88690a17306        About a minute ago   /bin/sh -c #(nop) MAINTAINER user@acme.com      0 B
		89d5d8e8bafb        9 days ago           /bin/sh -c #(nop) CMD ["/bin/bash"]             0 B
		e24428725dd6        9 days ago           /bin/sh -c sed -i 's/^#\s*\(deb.*universe\)$/   1.895 kB
		1796d1c62d0c        9 days ago           /bin/sh -c echo '#!/bin/sh' > /usr/sbin/polic   194.5 kB
		0bf056161913        9 days ago           /bin/sh -c #(nop) ADD file:9b5ba3935021955492   187.7 MB

Each line in the output represents an image layer. The above output shows 17 image layers.
  
6. Test that the image works by running a container with it

		$ docker run -d -p 80:80 --name www1 nginx-img:0.1

7. Navigate to `http://<node-ip>` and you should see a web page displaying the basic HTML we placed in `index.html` earlier

	Remember to substitute <node-ip> with the public IP or public DNS of the Docker host you are working with.

8. Let's clean up before we attempt to optimize the Dockerfile. 

		$ docker rm -f www1

# Task 3: Optimize the Dockerfile and image

Now let's see if we can optimize the `Dockerfile` and reduce the number of layers in the resulting image.

1. Open the `Dockerfile` with your favorite text editor (`vi` and `nano` are available on the lab nodes) 

2. Pin the version number of the base image specified with the `FROM` instruction

	Change `FROM ubuntu` to `FROM ubuntu 14.04`

3. Modify the `apt-get` statements so that they all run as part of a single `RUN` instruction

		FROM ubuntu:14.04
		MAINTAINER <user@acme.com>
		RUN apt-get update && \					<----------
		  apt-get install -y curl && \			<----------
		  apt-get install -y python-all && \	<----------
		  apt-get install -y nginx && \			<----------
		  rm -rf /var/lib/apt/lists/*			<----------

	The arrows in the code above are for illustration purposes only and show the lines that have changed since the previous step.

	Running multiple `apt-get` commands as part of a single `RUN` instruction will result in only a single image layer being created for all of the `apt-get` commands.

	Do not save and exit the Dockerfile yet, we've more improvements to make!

4.  Modify the `LABEL` instructions to reduce the number of layers

		FROM ubuntu:14.04
		MAINTAINER <user@acme.com>
		RUN apt-get update && \					
		  apt-get install -y curl && \			
		  apt-get install -y python-all && \	
		  apt-get install -y nginx && \			
		  rm -rf /var/lib/apt/lists/*			
		COPY index.html /usr/share/nginx/html
		EXPOSE 80
		LABEL com.acme.vendor=Acme\ Example\ Corp. \	<----------
		    com.acme.version="0.9.0-beta" \				<----------
		    com.acme.is-beta=true \						<----------
			com.acme.release-date="2016-01-01"			<----------
		CMD ["nginx", "-g", "daemon off;"]

	The arrows in the code above are for illustration purposes only and show the lines that have changed since the previous step.

	Applying all labels as part of a single `LABEL` instruction allows all lables to be applied as part of a single layer.

5. Save the updated `Dockerfile`  

6. Let's build a new image using the updated improved Dockerfile. We'll tag this one as `0.2`

		$ docker build -t nginx-img:0.2 .

	Do not omit the trailing period (.) in the above command.

	It will take a few minutes to build the image.

7. Use the `docker history` command to see if the number of layers has reduced from 17

		$ docker history nginx-img:0.2

		IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
		cfb976c0c191        7 minutes ago       /bin/sh -c #(nop) CMD ["nginx" "-g" "daemon o   0 B
		95ae6dd917fa        7 minutes ago       /bin/sh -c #(nop) LABEL vendor=Acme Example C   0 B
		df255a6a034c        7 minutes ago       /bin/sh -c #(nop) EXPOSE 80/tcp                 0 B
		955559830d7a        7 minutes ago       /bin/sh -c #(nop) COPY file:d0411b7ac48ed3171   21 B
		5718d61aad87        7 minutes ago       /bin/sh -c apt-get update &&  apt-get install   51.19 MB
		12989f8e0228        10 minutes ago      /bin/sh -c #(nop) MAINTAINER USER CANE <user@   0 B
		89d5d8e8bafb        9 days ago          /bin/sh -c #(nop) CMD ["/bin/bash"]             0 B
		e24428725dd6        9 days ago          /bin/sh -c sed -i 's/^#\s*\(deb.*universe\)$/   1.895 kB
		1796d1c62d0c        9 days ago          /bin/sh -c echo '#!/bin/sh' > /usr/sbin/polic   194.5 kB
		0bf056161913        9 days ago          /bin/sh -c #(nop) ADD file:9b5ba3935021955492   187.7 MB

	As can be seen form the output above, the number of layers produced by the improved Dockerfile is 10.

8. Check that the labels are still available

		docker inspect --format '{{json .Config.Labels}}' nginx-img:0.2

		{"com.acme.is-beta":"true","com.acme.release-date":"2016-01-01","com.acme.vendor":"Acme Example Corp.","com.acme.version":"0.9.0-beta"}
    
9. Ensure that every optimization step is followed by a validation step to ensure that the image is functionally adequate and does not break any of its base requirements.

Next, consider using a `Volume` to make development more flexible.

## Conclusion

Congrats!! You have completed this lab and learned how optimize Dockerfiles.

## Clean up

If you plan to do another lab, you need to cleanup your EC2 instances. Cleanup removes any environment variables, configuration changes, Docker images, and running containers. To do a clean up,

Log into each EC2 instance you used and run the following command:

	$ source /home/ubuntu/cleanup.sh
