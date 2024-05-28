# Cronicle

This project is based on `Cronicle` with the different that we can manage commands in a docker deployment context. Is inspired on project [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle).

## Requirements: prepare the project

* Synchronize app submodule
* Install the project
* Install node dependencies (`npm install`)
* Following the instructions to install Cronicle with nodejs enviroment

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

## Dockerfile

This `Dockerfile` only use `node:18-bullseye` to build the container.
Is a image based on `apt` and includes the Cronicle project if is neccesary realize any customization to the original project.

This scripts update the real Cronicle scripts to make the docker context deployment:

```
# Move updated scripts
COPY ./bin/docker-entrypoint.js ./app/bin/docker-entrypoint.js
COPY ./bin/build-tools.js ./app/bin/build-tools.js
```

## Exec docker commands

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
    environment:
      - TZ=Europe/Madrid
      - DEBUG=1
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

# Deploy with application url context

To make this we need to change the url context of the application. If you need, you can modify the sample conf and make bind this sample_conf directory with the app. The app is linked by the original Cronicle repository, but the config must be updated:

```json
{
	"base_app_url": "http://localhost:3012/context",
  ...
}
```

Now our application url base is listen on `http://localhost:3012/context`. An exmaple with a apache proxy:

```text
# our_domain/context
# Crons server to our application
ProxyPass "/context"  "http://our_ip:3012/"
ProxyPassReverse "/context"  "http://our_ip:3012/"
ProxyHTMLURLMap http://our_ip:3012/ /context

ProxyPreserveHost On
SSLProxyEngine on
SSLProxyVerify none
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLProxyCheckPeerExpire off
```

# Reference

* [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle)
* [Exec docker command](https://docs.docker.com/reference/cli/docker/container/exec/#description)
* [Container ID by container name](https://stackoverflow.com/a/34497614)