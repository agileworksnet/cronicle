# Overview

This project is build based on **Cronicle**, a multi-server task scheduler and runner, with a web based front-end UI. It handles both scheduled, repeating and on-demand jobs, targeting any number of worker servers, with real-time stats and live log viewer. It's basically a fancy [Cron](https://en.wikipedia.org/wiki/Cron) replacement written in [Node.js](https://nodejs.org/).  You can give it simple shell commands, or write Plugins in virtually any language.

![Main Screenshot](https://pixlcore.com/software/cronicle/screenshots-new/job-details-complete.png)

## Documentation

We add the Cronicle documentation to manage the application:

- &rarr; **[Installation & Setup](https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md)**
- &rarr; **[Configuration](https://github.com/jhuckaby/Cronicle/blob/master/docs/Configuration.md)**
- &rarr; **[Setup](https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md)**
- &rarr; **[Web UI](https://github.com/jhuckaby/Cronicle/blob/master/docs/WebUI.md)**
- &rarr; **[Plugins](https://github.com/jhuckaby/Cronicle/blob/master/docs/Plugins.md)**
- &rarr; **[Command Line](https://github.com/jhuckaby/Cronicle/blob/master/docs/CommandLine.md)**
- &rarr; **[Inner Workings](https://github.com/jhuckaby/Cronicle/blob/master/docs/InnerWorkings.md)**
- &rarr; **[API Reference](https://github.com/jhuckaby/Cronicle/blob/master/docs/APIReference.md)**
- &rarr; **[Development](https://github.com/jhuckaby/Cronicle/blob/master/docs/Development.md)**

# Features

This project can manage commands in a docker deployment context. The image is a idea extracted from [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle). 

##  Docker commands with Cronicle

Important: if you need to manage the crontab of a docker applications, you can bind the volume of docker host with `- /var/run/docker.sock:/var/run/docker.sock` to make that cronicle exec commands in a docker container.  View the `docker-compose.yml` example added to this project.

`docker exec -it $(docker ps -aqf "name=container_name") sh -c "echo a && echo b"`

* Replace `container_name` with the docker container name. You can define it on the service on `docker-compose.yml`.
* Add event with `shell plugin` and connect the command with your container:

```text
#!/bin/sh

# Enter your shell script code here
docker exec -it $(docker ps -aqf "name=container_name") sh -c "echo a && echo b"
```

### Prevent input device is not a TTY

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

## Application with url context

Is neccesary update some scripts of the original project of `Cronicle`, that is updated on image construction:

```
# Only copy this scripts, another scripts are Cronicle property
COPY ./bin/docker-entrypoint.js ./bin/docker-entrypoint.js
COPY ./bin/build-tools.js ./bin/build-tools.js
```

* `docker-entrypoint.js`: Config the project and build the docker context of the application.
* `build-tools.js`: This make that in HTML compilation, the base tag is added to head.

## webSocket configuration

Cronicle requires that you have a network route from your local browser to your individual servers, via their LAN IPs. If you have a setup which prevents this, you may need to look into these two configuration options: server_comm_use_hostnames and web_socket_use_hostnames.

### server_comm_use_hostnames
Setting this parameter to 1 will force the Cronicle servers to connect to each other using hostnames rather than LAN IP addresses. This is mainly for special situations where your local server IP addresses may change, and you would prefer to rely on DNS instead. The default is 0 (disabled), meaning connect using IP addresses.

### web_socket_use_hostnames
Setting this parameter to 1 will force Cronicle's Web UI to connect to the back-end servers using their hostnames rather than IP addresses. This includes both AJAX API calls and Websocket streams. You should only need to enable this in special situations where your users cannot access your servers via their LAN IPs, and you need to proxy them through a hostname (DNS) instead. The default is 0 (disabled), meaning connect using IP addresses.

```json
"server_comm_use_hostnames": true,
"web_direct_connect": false,
"web_socket_use_hostnames": true,`
```

## Problems with webSockets with URL context

Configure your proxy to connect `socket.io` library with your application:

```
<Location /socket.io>
    # Configuración del proxy de WebSocket
    ProxyPass ws://51.89.229.6:3012/socket.io
    # Configuración del proxy de WebSocket inverso
    ProxyPassReverse ws://51.89.229.6:3012/socket.io
</Location>
```

### Examples to build the container

You can check the [examples](./example):

* Without any config [simple](./example/simple).
* With storage the data info [storage](./example/storage).
* With custom config [simple](./example/config).

# Reference

* [Docker Cronicle By Soulteary](https://github.com/soulteary/docker-cronicle)
* [Exec a docker command](https://docs.docker.com/reference/cli/docker/container/exec/#description)
* [Retrieve container ID by container name](https://stackoverflow.com/a/34497614)

# License

**The MIT License (MIT)**

*Copyright (c) 2015 - 2023 Joseph Huckaby*

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
