FROM node:18-bullseye AS Builder

ENV CRONICLE_VERSION=0.9.46

WORKDIR /opt/cronicle

RUN curl -L -o /tmp/Cronicle-${CRONICLE_VERSION}.tar.gz https://github.com/jhuckaby/Cronicle/archive/refs/tags/v${CRONICLE_VERSION}.tar.gz

# COPY Cronicle-${CRONICLE_VERSION}.tar.gz /tmp/
RUN tar zxvf /tmp/Cronicle-${CRONICLE_VERSION}.tar.gz -C /tmp/ && \
    mv /tmp/Cronicle-${CRONICLE_VERSION}/* . && \
    rm -rf /tmp/* && \
    yarn

# COPY ./patches /tmp/patches
# RUN patch -p3 < /tmp/patches/engine.patch lib/engine.js

FROM node:18-alpine
# FROM node:18-bullseye

# RUN apt-get install -y procps curl
# RUN apk add procps curl

# Instalar Docker CLI en Alpine
RUN apk add --no-cache \
    procps \
    curl \
    device-mapper \
    shadow \
    bash \
    xz

# Instalar Docker CLI
ENV DOCKER_VERSION=24.0.2

RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar xzv && \
    mv docker/* /usr/local/bin/ && \
    rmdir docker

COPY --from=builder /opt/cronicle/ /opt/cronicle/

WORKDIR /opt/cronicle

# Define build argument
ARG CRONICLE_base_url
# Set environment variable
ENV CRONICLE_base_url=${CRONICLE_base_url}

# Validate the environment variable
RUN echo "CRONICLE_base_url is: $CRONICLE_base_url"
RUN if [ -z "$CRONICLE_base_url" ]; then echo "Cronicle base url is not found" && exit 1; fi

COPY ./bin/build-tools.js ./bin
COPY ./bin/docker-entrypoint.js ./bin

COPY conf/ ./conf/

ENV CRONICLE_foreground=1
ENV CRONICLE_echo=1
ENV CRONICLE_color=1
ENV debug_level=1
ENV HOSTNAME=main

# Complete the install of the Cronicle project
RUN node bin/build.js dist && bin/control.sh setup

# Expone el puerto de Cronicle
EXPOSE 3012

CMD ["node", "bin/docker-entrypoint.js"]