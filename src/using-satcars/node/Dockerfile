FROM node:8-alpine
WORKDIR /app
COPY . .
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY --chmod=600 --chown=sshd:sshd sshd_config /etc/ssh/
RUN npm install &&\
    apk add --no-cache openrc openssh nginx su-exec gettext &&\
    # As weird at it seems, the root password MUST be "Docker!" to allow \
    # for SSH connections from the Azure portal
    echo "root:Docker!" | chpasswd &&\
    # The runtime user, having no home dir nor password
    adduser -HD -s /bin/ash appuser &&\
    # Generate SSH keys pairs. On Windows, the authorized cyphers may not work
    cd /etc/ssh && \
    ssh-keygen -A &&\
    cd -
EXPOSE 3000 50002 3500 80 2222 443
ENTRYPOINT [ "/app/entrypoint.sh" ]
