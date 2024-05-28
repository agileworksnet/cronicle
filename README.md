# Cronicle

## Prepare the project

First, install the project Cronicle, install node dependencies (`npm install`) and following the instructions to install Cronicle with nodejs enviroment:

```text
Welcome to Cronicle!
First time installing?  You should configure your settings in '/opt/cronicle/conf/config.json'.
Next, if this is a master server, type: '/opt/cronicle/bin/control.sh setup' to init storage.
Then, to start the service, type: '/opt/cronicle/bin/control.sh start'.
For full docs, please visit: http://github.com/jhuckaby/Cronicle
Enjoy!
```

* `cp -R sample_conf conf`
  * You can update the default configuration here.
* `cd bin/build.js` to build the assets in htdocs.
* `./control.sh setup` to prepare the project with `conf`.

If all configuration are correctly installed, you can see this message:

```
Setup completed successfully!
This server (laptop-0a6c7d69f262) has been added as the single primary master server.
An administrator account has been created with username 'admin' and password 'admin'.
You should now be able to start the service by typing: '/opt/cronicle/bin/control.sh start'
Then, the web interface should be available at: http://laptop-0a6c7d69f262:3012/
Please allow for up to 60 seconds for the server to become master.
```

* `cp -R htdocs ../` to make a copy and bind to the docker container.
* `cp -R conf ../ to make a copy and bind to the docker container.

## Cronicle DockerExec Command

This project of `Cronicle` can manage commands in a docker deployment context. Is an extension of [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle).

If you need to manage the crontab of a docker applications, you can bind the volume of docker host with `- /var/run/docker.sock:/var/run/docker.sock` to make that cronicle exec commands in a docker container. 

```yml
services:

  cronicle:
    container_name: cronicle
    build:
      context: .
      dockerfile: docker/Dockerfile
    image: fbaconsulting/cronicle
    restart: unless-stopped
    hostname: cronicle
    ports:
      - 3012:3012
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - ./data/data:/opt/cronicle/data
      - ./data/logs:/opt/cronicle/logs
      - ./data/plugins:/opt/cronicle/plugins
    extra_hosts:
      - "cronicle.lab.io:0.0.0.0"
    environment:
      - TZ=Europe/Madrid
      - DEBUG=1
      - CRONICLE_VERSION=0.9.46
      - CRONICLE_foreground=1
      - CRONICLE_echo=1
      - CRONICLE_color=1
      - debug_level=1
      - HOSTNAME=main      
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider localhost:3012/api/app/ping || exit 1"]
      interval: 5s
      timeout: 1s
      retries: 3
    logging:
        driver: "json-file"
        options:
            max-size: "10m"
    networks:
      - network

networks:
  network:
    name: cronicle_network
```

# Enviroment vars

Envvars has been moved to the docker-compose file:

```text
- DEBUG=1
- CRONICLE_VERSION=0.9.46
- CRONICLE_foreground=1
- CRONICLE_echo=1
- CRONICLE_color=1
- debug_level=1
- HOSTNAME=main  
```

# Docker commands with Cronicle

`docker exec -it $(docker ps -aqf "name=container_name") sh -c "echo a && echo b"`

Replace `container_name` with the docker container name. You can define it on the service on `docker-compose.yml`.

## Add event on Cronicle

Add event with `shell plugin` and connect the command with your container:

```text
#!/bin/sh

# Enter your shell script code here
docker exec -it $(docker ps -aqf "name=container_name") sh -c "echo a && echo b"
```

## Prevent input device is not a TTY

Another requirement is that the container need tty enable to prevent ` Error: Script exited with code: 1: the input device is not a TTY` when you run the script. this error appears when docker exec command is running with flag -t, which assigs a pseudo-TTY, in a docker context with no support for interactive terminal.

```text
# Job ID: jlwq3cmyt05
# Event Title: Docker exec command
# Hostname: main
# Date/Time: 2024/05/28 09:43:49 (GMT+2)

the input device is not a TTY

# Job failed at 2024/05/28 09:43:49 (GMT+2).
# Error: Script exited with code: 1: the input device is not a TTY
# End of log.
```

If you don't need a interactive terminal, don't use the flag -t. For example:

`docker exec -i $(docker ps -aqf "name=container_name") sh -c "echo a && echo b"`

```text
# Job ID: jlwq3jjnr07
# Event Title: Docker exec command
# Hostname: main
# Date/Time: 2024/05/28 09:49:12 (GMT+2)

[2024/05/28 09:49:12] a
[2024/05/28 09:49:12] b

# Job completed successfully at 2024/05/28 09:49:12 (GMT+2).
# End of log.
```

## Dockerfile

This `Dockerfile` only use `node:18-bullseye` to build the container.
Is a image based on `apt` and includes the Cronicle project if is neccesary realize any customization to the original project.

```Dockerfile

FROM node:18-bullseye

# Copy the real project from Cronicle to work over this UI
COPY ./app /opt/cronicle/

WORKDIR /opt/cronicle

# Prepare cronicle image content
RUN yarn --cwd /opt/cronicle/app

# Apply the Soulteary patches to Cronicle project
COPY ./docker/patches /app/patches
RUN patch -p3 < /app/patches/engine.patch lib/engine.js
COPY ./docker/docker-entrypoint.js ./bin/

# Install docker to exec docker commands

# Instalar dependencias necesarias para instalar Docker
RUN apt-get update -y && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Agregar la clave GPG oficial de Docker
RUN mkdir -m 0755 -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Agregar el repositorio de Docker al sources.list
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar e instalar el cliente de Docker
RUN apt-get update && apt-get install -y docker-ce-cli

# Limpiar cachés de apt para reducir el tamaño de la imagen
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Add libraries required by cronicle
RUN apt-get install -y procps curl

RUN node bin/build.js dist && bin/control.sh setup

CMD ["node", "bin/docker-entrypoint.js"]
```

# Deploy with application url context

For this example, we need to change the url context of the application. If you need, you can modify the sample conf and make bind this sample_conf directory with the app. The app is linked by the original Cronicle repository, but the config must be updated:

```json
{
  "action": "bundleCompress",
  "uglify": false,
  "header": "/* Copyright (c) PixlCore.com, MIT License. https://github.com/jhuckaby/Cronicle */",
  "dest_bundle": "htdocs/js/_combo.js",
  "html_file": "htdocs/index.html",
  "match_key": "COMBINE_SCRIPT",
  "dest_bundle_tag": "<script src=\"./capture/js/_combo.js\"></script>"
},
```

Now our application list this files on http//hostname/capture. For this example, we use a real world example how is a mod_proxy on apache,
to prevent to add extra proxy rules for css, js, etc.

```text
# our_domain/capture
# Crons server to our application
ProxyPass "/capture"  "http://our_ip:3012/"
ProxyPassReverse "/capture"  "http://our_ip:3012/"
ProxyHTMLURLMap http://our_ip:3012/ /capture

ProxyPreserveHost On
SSLProxyEngine on
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLProxyCheckPeerExpire off
```

# Update the web interface

You can add the htdocs to make more customizable the Cronicle user interface. Modify the index-dev.html to change the HTML content.
This changes can't be made with `setup.json` and `config.son` of sample conf. Read the `docker-compose.yml` to check the example.

# Reference

* [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle)
* [Exec docker command](https://docs.docker.com/reference/cli/docker/container/exec/#description)
* [Container ID by container name](https://stackoverflow.com/a/34497614)