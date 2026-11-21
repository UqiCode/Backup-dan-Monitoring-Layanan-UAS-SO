FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    nginx \
    openssh-server \
    bash \
    sudo \
    && rm -rf /var/lib/apt/lists/*

COPY source/scripts /app/scripts
COPY source/data /app/data

RUN chmod +x /app/scripts/*.sh

WORKDIR /app

EXPOSE 80 22

CMD service ssh start && nginx -g "daemon off;"
