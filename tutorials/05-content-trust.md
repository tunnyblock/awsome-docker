# Lab 05 : Docker Content Trust

> **Difficulty**: Magic

> **Time**: 20 minutes

> **Tasks**:
>
* [Prerequisites](#prerequisites)
* [Task 1: Create a new Docker Hub repository](#task-1-create-a-new-docker-hub-repository)
* [Task 2: Enable Content Trust](#task-2-enable-content-trust)
* [Task 3: Push a signed image](#task-3-push-a-signed-image)
* [Task 4: Pulling images](#task-4-pulling-images)
* [Task 5: Docker Content Trust with Yubikey](#task-5-docker-content-trust-with-yubikey)




## What is Docker Content Trust?

Docker Content Trust allows image operations with a remote Docker registry to enforce
client-side signing and verification of image tags. It enables
digital signatures for data sent to, and received from, remote Docker registries.
These signatures allow Docker client-side interfaces to verify the integrity and
publisher of specific image tags.

Image publishers can sign their images. Image consumers can ensure that the
images they pull are signed. Both publishers and consumers can be either
individuals or organizations. Docker Content Trust supports users and
automated processes pipelines.

Docker Content Trust works with Docker Hub as well as Docker Trusted Registry (Notary integration is experimental in version 1.4 of Docker Trusted Registry). 

## Prerequisites

* You will be using **node-0**
* An existing Docker Hub account

## Task 1: Create a new Docker Hub repository

Before you enable Docker Content Trust, you must create a new temporary repository on Docker Hub. You'll use this temporary repository for the lab.

1. Log into your `node-0` instance

2. Use the `docker login` command to log into Docker Hub

        $ docker login
        Username: <username>
        Password: <password>
        Email: <email>
        WARNING: login credentials saved in /home/ubuntu/.docker/config.json
        Login Succeeded

3. Pull the `busybox` image:

        $ docker pull busybox

4. Create a new tag for the busybox image using your Docker Hub namespace

    Your Docker Hub account name is your namespace.

        $ docker tag busybox <username>/dctrust:latest

5. Push this unsigned image to Docker Hub:

        $ docker push <username>/dctrust:latest

6. Open [Docker Hub](https://hub.docker.com) in your browser and login

  At this point you should have a new unsigned image repository **dctrust** (with the `latest` tag) under your Docker Hub account.

  ![On Docker Hub](images/dctrust-pushed.png)

## Task 2: Enable Content Trust

Currently, Docker Content Trust is disabled by default. To enable it, set the `DOCKER_CONTENT_TRUST` environment variable as follows:

```
$ export DOCKER_CONTENT_TRUST=1
```

Once you set this environment variable, every Docker operation is secure. This means that any future Docker commands are executed based on signatures.

Now that you've enabled Docker Content Trust, try to pull the image you just pushed.

    $ docker pull <username>/dctrust:latest
    no trust data available


You'll notice that the Docker client did not pull the image.  This is because the Docker client is now expecting images to be signed, but the image you tried to pull image is not signed.

## Task 3: Push a signed image

To create the trust data for an image (sign it) you need push an image with Docker Content Trust enabled (`DOCKER_CONTENT_TRUST=1`). 

The first push of an image after Docker Content Trust has been enabled requires you to enter two new passphrases. A **root key** and a **repository key**.

1. Create a new tag for the `busybox` image called `signed`:

        $ docker tag busybox <username>/dctrust:signed

2. Push the image making sure to enter two new passphrases when prompted

        $ docker push <username>/dctrust:signed

	> **Note:** Be sure to use strong passphrases as these are used to protect your keys.

  Example output:

        $ docker push <username>/dctrust:signed
        The push refers to a repository [docker.io/<username>/dctrust] (len: 1)
        2c5ac3f849df: Image already exists
        ab2b8a86ca6c: Image already exists
        signed: digest: sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143 size: 3214
        Signing and pushing trust metadata
        You are about to create a new root signing key passphrase. This passphrase
        will be used to protect the most sensitive key in your signing system. Please
        choose a long, complex passphrase and be careful to keep the password and the
        key file itself secure and backed up. It is highly recommended that you use a
        password manager to generate the passphrase and keep it safe. There will be no
        way to recover this key. You can find the key in your config directory.
        Enter passphrase for new root key with id 020aa4f:
        Repeat passphrase for new root key with id 020aa4f:
        Enter passphrase for new repository key with id docker.io/<username/dctrust (ab6b057):
        Repeat passphrase for new repository key with id docker.io/<username/dctrust (ab6b057):
        Finished initializing "docker.io/<username/dctrust"

## Task 4: Pulling images

At this point, you now have two different tagged dctrust images in your Docker Hub repository:

| Image            | Description                                                                      |
|------------------|----------------------------------------------------------------------------------|
| `dctrust:latest` | This image is still unsigned and cannot be pulled when content trust is enabled. |
| `dctrust:signed` | This image is signed and can be pulled if content trust is enabled or disabled.  |

At this point, you have Docker Content Trust enabled.

1. Pull the latest image and then the signed image.

        $ docker pull <username/dctrust:latest
        No trust data for latest
        
        $ docker pull <username/dctrust:signed
        Pull (1 of 1): <username/dctrust:signed@sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143
        sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143: Pulling from <username/dctrust
        Digest: sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143
        Status: Downloaded newer image for <username/dctrust@sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143
        Tagging <username/dctrust@sha256:b33669e38aef420ff10d4787c07afe11a679564f65c31bde39572c9196f3e143 as <username/dctrust:signed

    Only the signed image is successfully pulled.

2. Pull the images again, this time using the `--disable-content-trust` flag to temporarily disable Docker Content Trust.

        $ docker pull --disable-content-trust <username/dctrust:latest
        latest: Pulling from <username/latest
        Digest: sha256:f3fefef65b040546adab73e2e6a624376373b0f12e83a5e5a921d9cd9059953c
        Status: Image is up to date for <username/dctrust:latest

        $ docker pull --disable-content-trust <username/dctrust:signed
        signed: Pulling from <username/dctrust
        Digest: sha256:357cb702777f1bdf9a6241e8cf9d17b05d30fc203e7e4e51464a067e826c7906
        Status: Downloaded newer image for <username/dctrust:signed

    Both images are successfully pulled.

## Task 5: Docker Content Trust with Yubikey

**Please Note: This task can only be completed on Mac/Linux machines. All the following steps will be completed from the local Docker Toolbox (DockerCon edition) and NOT from your EC2 instances. This task requires a Yubikey 4 (Edge/Neo will not work). `lsusb` can tell you about which version you have. In order for this tutorial to work the output should include:**

    $ lsusb | grep Yubikey
    Bus 020 Device 031: ID 1050:0406 1050 Yubikey 4 U2F+CCID

In this task, you will use the [Yubikey](https://www.yubico.com/products/yubikey-hardware/yubikey-2/) to sign an image and push it to Docker Hub. This step requires installing a spceial DockerCon Toolbox. 

### For MAC Users:

**Step 1:** **Installing Docker Toolbox**

Please note that this step will require you to have updated version of virtualbox and therefore would require you to stop any Virtualbox VMs. It will also require a laptop restart at the end.

Download and install the experimental Docker Toolbox [here](https://s3.eu-central-1.amazonaws.com/docker-toolbox-demopack/DockerToolbox-dockercon-demopack-edition-1.9.0d.pkg). Then open the downloaded package and follow the steps to complete the installation.

After the installation is complete, launch the **Docker Quickstart Terminal**.  

**Step 2:** Plug in your Yubikey (touch sensor facing up)

**Step 3:** Check the available keys. You should see no keys as shown below:

```
My-Macbook-Pro:~ user$ notary key list

# Root keys:

# Signing keys:
```

**Step 4:** Generate a new Root Key

##WARNING: The root key is really important. You should be careful not lose it or delete it. Make sure to use a dummy repo in this step in the case you delete it accidentally.

To generate a new root key, simply do the following:

```
My-Macbook-Pro:~ user$ notary key generate
You are about to create a new root signing key passphrase. This passphrase
will be used to protect the most sensitive key in your signing system. Please
choose a long, complex passphrase and be careful to keep the password and the
key file itself secure and backed up. It is highly recommended that you use a
password manager to generate the passphrase and keep it safe. There will be no
way to recover this key. You can find the key in your config directory.
Enter passphrase for new root key with ID 37e0ee8: <ENTER A PASSWORD>
Repeat passphrase for new root key with ID 37e0ee8:<ENTER SAME PASSWORD>
Generated new ecdsa root key with keyID:
****************************
```

Check the new key:

```
My-Macbook-Pro:~ user$ notary key list

# Root keys:
******************************************************* - yubikey
```
**Step 5:** Sign an image with the new root key. First, pull a small image to use:

```
My-Macbook-Pro:~ user$ docker pull alpine
Using default tag: latest
Pull (1 of 1): alpine:latest@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec: Pulling from library/alpine
3b4d28ce80e4: Pull complete
Digest: sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
Status: Downloaded newer image for alpine@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
Tagging alpine@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec as alpine:latest
```

Tag an image with your Docker Hub username:

```
$ docker tag alpine <DOCKER_HUB_USERNAME>/alpine:signed
```

Ensure the **Docker Content Trust** is enabled

```
$ export DOCKER_CONTENT_TRUST=1
```

Ensure that you are logged in Docker Hub:

```
$ docker login
Username: <DOCKER_HUB_USERNAME>
Password:<YOUR_PASSWORD>
Email:<YOUR_EMAIL>
WARNING: login credentials saved in /Users/<YOUR_USERNAME>/.docker/config.json
Login Succeeded

```

Push the new image using `docker-x`, the experimental Docker engine. During the push process, you will be prompted to touch the Yubikey sensor to perform signing. You will also be prompted to provide a new passphrase to be used to encrypt the repository key.


```
$ docker-x push DOCKER_HUB_USERNAME/alpine:signed
The push refers to a repository [docker.io/DOCKER_HUB_USERNAME/alpine] (len: 1)
3b4d28ce80e4: Image already exists
signed: digest: sha256:0ec83084fcf6a8a96f80ccda270ccefa743601b33048bcc74e970e82d96efade size: 1608
Signing and pushing trust metadata
Please touch the attached Yubikey to perform signing.
Enter passphrase for new repository key with ID 4ec62d9 (docker.io/DOCKER_HUB_USERNAME/alpine):
Repeat passphrase for new repository key with ID 4ec62d9 (docker.io/DOCKER_HUB_USERNAME/alpine):
Please touch the attached Yubikey to perform signing.
Finished initializing "docker.io/DOCKER_HUB_USERNAME/alpine"
```
Congrats! you have signed and pushed a new image using the Yubikey. Docker users with enabled Docker Content Trust can pull the image that you just pushed.

### For Linux Users:

Before you start, ensure there is a Docker engine running on your Linux machine.
You will need to run the experimental version of Docker Engine inside a container on your machine. You will mount the Yubikey into the container and go through signing and pushing images within the container itself.

**Step 1:** Run Docker Experimental inside a Container

```
$ docker run -it --rm --privileged -v /dev/bus/usb:/dev/bus/usb dockersecurity/dct_lab:latest
```

**Step 2:** Insert the Yubikey

**Step 3:** In the container, run Smart Card Daemon and Docker Daemon

```
# pcscd
# docker daemon > /dev/null 2>&1 &

```

**Step 4:** Enable Docker Content Trust

```
# export DOCKER_CONTENT_TRUST=1
```

**Step 5:** Login to Docker Hub and pull a dummy image

```
# docker login
Username: <DOCKER_HUB_USERNAME>
Password:<YOUR_PASSWORD>
Email:<YOUR_EMAIL>
WARNING: login credentials saved in /Users/<YOUR_USERNAME>/.docker/config.json
Login Succeeded


# docker pull alpine
$Using default tag: latest
Pull (1 of 1): alpine:latest@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec: Pulling from library/alpine
3b4d28ce80e4: Pull complete 
Digest: sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
Status: Downloaded newer image for alpine@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec
Tagging alpine@sha256:074de05bbd8554cf454a19094df34985c8674f54e14474731427a2a31d1970ec as alpine:latest
```

**Step 6:** Check Available Root Keys on Yubikey. You should see no keys.

```
# notary key list

No signing keys found.

```

**Step 7:** Tag , Sign, and Push an Image

In this step, you will tag the image and push it to Docker Hub. Since there are no available root keys on Yubikey, Docker will automatically generate one upon the first push. Please follow the instructions below:

```
# docker tag alpine:latest <DOCKER_HUB_USERNAME>/<REPO_NAME>:signed
# docker push <DOCKER_HUB_USERNAME>/<REPO_NAME>:signed

The push refers to a repository [docker.io/<DOCKER_HUB_USERNAME>/dct_demo] (len: 1)
3b4d28ce80e4: Pushed 
latest: digest: sha256:61b63b333e5f6132c70e3258701b75d787ac37536bc457873c23886627e64f86 size: 1611
Signing and pushing trust metadata
You are about to create a new root signing key passphrase. This passphrase
will be used to protect the most sensitive key in your signing system. Please
choose a long, complex passphrase and be careful to keep the password and the
key file itself secure and backed up. It is highly recommended that you use a
password manager to generate the passphrase and keep it safe. There will be no
way to recover this key. You can find the key in your config directory.
Enter passphrase for new root key with ID dbe580a: 
Repeat passphrase for new root key with ID dbe580a: 
Please touch the attached Yubikey to perform signing.
Enter passphrase for new repository key with ID fbe7380 (docker.io/<DOCKER_HUB_USERNAME>/<REPO_NAME>):  <ENTER A PASSWORD>
Repeat passphrase for new repository key with ID fbe7380 (docker.io/<DOCKER_HUB_USERNAME>/<REPO_NAME>):<ENTER A PASSWORD> 
Please touch the attached Yubikey to perform signing.
Finished initializing "docker.io/<DOCKER_HUB_USERNAME>/<REPO_NAME>"
```
**Step 8:** Check the new key

You will notice that a new root key  was created. It is stored both in the Yubikey as well as on disk for backup.

```
# notary key list

    ROLE                GUN                                           KEY ID                                             LOCATION               
------------------------------------------------------------------------------------------------------------------------------------------------
  root                                  ***************   file (/root/.docker/trust/private)  
  root                                  ***************   yubikey               

```
Congrats! you have signed and pushed a new image using the Yubikey. Docker users with enabled Docker Content Trust can pull the image that you just pushed.


## Conclusion

At this point you have successfully enabled Docker Content Trust on your Docker client, signed an image, and pushed the image to Docker Hub.

### Share on Twitter!

<p>
<a href="http://ctt.ec/8PzW6" target=“_blank”>
<img src="http://www.wyntercon.com/wp-content/uploads/2015/04/twitter-bird-blue-on-white-small.png" width="100" height="100">
</p>

## Clean up

If you plan to do another lab, you need to cleanup your EC2 instances. Cleanup removes any environment variables, configuration changes, Docker images, and running containers. To do a clean up, log into each EC2 instance and run the following:

```bash
$ source /home/ubuntu/cleanup.sh
```

## Related information

For more in-depth examples and advanced concepts refer to the Docker documentation:

- [Content Trust Concepts](https://docs.docker.com/security/trust/content_trust/)
- [Automation Systems](https://docs.docker.com/security/trust/trust_automation/)
- [Understanding and Managing Keys](https://docs.docker.com/security/trust/trust_key_mng/)
- [Personal Sandbox](https://docs.docker.com/security/trust/trust_sandbox/)
