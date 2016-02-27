FROM centos
MAINTAINER feisky <feiskyer@gmail.com>

# Hyper dependency
RUN yum install -y epel-release
RUN yum install -y automake \
	autoconf \
	gcc \
	make \
	glibc-devel \
	glibc-devel.i686 \
	golang \
	git \
	qemu-system-x86.x86_64 \
	device-mapper-devel \
	pcre-devel \
	libsepol-devel \
	libselinux-devel \
	systemd-container-devel \
	sqlite-devel

# CBFSTool
RUN cd /root && \
	curl -sSL https://www.coreboot.org/releases/coreboot-4.2.tar.xz | tar --xz -xf -  && \
	cd coreboot-4.2/util/cbfstool && \
	make && \
	cp cbfstool /usr/local/bin/ && \
	rm -rf /root/coreboot-4.2

EXPOSE 80
ENV GOPATH /root
ENV STORAGE_DRIVER overlay
ENV PATH /root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN mkdir -p /var/lib/hyper/ /var/run/hyper /etc/hyper
COPY config /etc/hyper/config
COPY start.sh /start.sh

# qboot
RUN cd /root && \
	git clone https://github.com/bonzini/qboot.git && \
	cd qboot && \
	make && \
	cp bios.bin /var/lib/hyper/qboot-bios.bin && \
	rm -rf /root/qboot

# Build HyperStart
RUN mkdir -p ${GOPATH}/src/github.com/hyperhq && \
	cd ${GOPATH}/src/github.com/hyperhq && \
	git clone https://github.com/hyperhq/hyperstart.git && \
	cd hyperstart && \
	./autogen.sh && \
	./configure && \
	make && \
	make cbfs && \
	cd build && \
	cp kernel hyper-initrd.img  /var/lib/hyper/ && \
	cp cbfs.rom /var/lib/hyper/qboot-cbfs.rom

# Build Hyper
RUN cd ${GOPATH}/src/github.com/hyperhq && \
	git clone https://github.com/hyperhq/runv.git runv && \
	git clone https://github.com/hyperhq/hyper.git hyper && \
	cd hyper && \
	./autogen.sh && \
	./configure &&\
	 make && \
	 make install && \
	 rm -rf ${GOPATH}/src/github.com/hyperhq

# Start Hyper
CMD ["/start.sh"]
