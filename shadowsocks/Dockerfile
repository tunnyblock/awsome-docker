FROM alpine
MAINTAINER feisky <feiskyer@gmail.com>

LABEL Description="Shadowsocks docker image"

RUN set -ex \
    && echo 'http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && apk add -U curl libsodium python \
    && curl -sSL https://bootstrap.pypa.io/get-pip.py | python \
    && pip install shadowsocks \
    && apk del curl \
    && rm -rf /var/cache/apk/*

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 1080
ENV PASSWORD    shadowsocks
ENV TIMEOUT     300
ENV WORKERS     10

EXPOSE $SERVER_PORT

CMD ssserver -s "$SERVER_ADDR"              \
             -p "$SERVER_PORT"              \
             -k "$PASSWORD"                 \
             -m aes-256-cfb                 \
             -t "$TIMEOUT"                  \
             --workers "$WORKERS"           \
             --fast-open

