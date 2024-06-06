FROM node:18-bullseye AS Builder

# Retrieve the argument from env file
ARG CRONICLE_VERSION
ENV CRONICLE_VERSION ${CRONICLE_VERSION}

RUN echo "CRONICLE_VERSION is: $CRONICLE_VERSION"
RUN if [ -z "$CRONICLE_VERSION" ]; then echo "Cronicle version is not defined, can't build the image." && exit 1; fi

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

# Install Docker CLI by version
ENV DOCKER_VERSION=24.0.2

# Prepare the Docker install
RUN apk add --no-cache \
    procps \
    curl \
    device-mapper \
    shadow \
    bash \
    xz

RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar xzv && \
    mv docker/* /usr/local/bin/ && \
    rmdir docker

COPY --from=builder /opt/cronicle/ /opt/cronicle/

WORKDIR /opt/cronicle

ARG CRONICLE_BASE_URL
ARG CRONICLE_FOREGROUND
ARG CRONICLE_ECHO
ARG CRONICLE_COLOR
ARG CRONICLE_DEBUG_LEVEL
ARG CRONICLE_HOSTNAME
ARG CRONICLE_TZ

# Set environment variable

ENV CRONICLE_BASE_URL ${CRONICLE_BASE_URL}
ENV CRONICLE_foreground ${CRONICLE_FOREGROUND}
ENV CRONICLE_echo ${CRONICLE_ECHO}
ENV CRONICLE_color ${CRONICLE_COLOR}
ENV debug_level ${CRONICLE_DEBUG_LEVEL}
ENV HOSTNAME ${CRONICLE_HOSTNAME}
ENV TZ ${CRONICLE_TZ}

# Validate the environment variables
RUN echo "CRONICLE_BASE_URL is: $CRONICLE_BASE_URL"
RUN if [ -z "$CRONICLE_BASE_URL" ]; then echo "Cronicle base url is not found" && exit 1; fi

RUN echo "CRONICLE_foreground is: $CRONICLE_foreground"
RUN if [ -z "$CRONICLE_foreground" ]; then echo "Cronicle foreground is not defined" && exit 1; fi

RUN echo "HOSTNAME is: $HOSTNAME"
RUN if [ -z "$HOSTNAME" ]; then echo "Cronicle hostname is not defined" && exit 1; fi

RUN echo "TZ is: $TZ"
RUN if [ -z "$TZ" ]; then echo "Cronicle timezone is not defined" && exit 1; fi

COPY ./bin/build-tools.js ./bin
COPY ./bin/docker-entrypoint.js ./bin

COPY conf/ ./conf/

# Complete the install of the Cronicle project
RUN node bin/build.js dist && bin/control.sh setup

# Expone el puerto de Cronicle
EXPOSE 3012

CMD ["node", "bin/docker-entrypoint.js"]