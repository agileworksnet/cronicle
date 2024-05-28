FROM node:18-bullseye

# Copy the real project from Cronicle to work over this UI
COPY ./app /opt/cronicle/

# Move updated scripts to docker deployment context
COPY ./bin/docker-entrypoint.js ./opt/cronicle/bin/docker-entrypoint.js
COPY ./bin/build-tools.js ./opt/cronicle/bin/build-tools.js

WORKDIR /opt/cronicle

# Install docker to exec docker commands
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

CMD ["node", "bin/docker-entrypoint.js"]
