FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    nginx openssh-server procps \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

RUN useradd -m -s /bin/bash sysguard \
    && usermod -p '*' sysguard \
    && mkdir -p /home/sysguard/.ssh /app/backups /run/sshd \
    && chmod 700 /home/sysguard/.ssh \
    && chown sysguard:sysguard /home/sysguard/.ssh \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/; s/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

COPY --chown=sysguard:sysguard --chmod=600 source/docker/authorized_keys /home/sysguard/.ssh/authorized_keys
COPY source/scripts /app/source/scripts
COPY source/data /app/source/data

RUN chmod +x /app/source/scripts/*.sh \
    && chown -R sysguard:sysguard /app/source/data /app/backups

WORKDIR /app
EXPOSE 80 22
CMD ["sh", "-c", "service ssh start && nginx -g 'daemon off;'"]
