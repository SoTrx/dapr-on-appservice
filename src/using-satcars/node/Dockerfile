# Expected size:
#   Unoptimized : 70MB
#   Optimized : 67MB (Not much to gain until pkg support UPX)

FROM node:16-alpine as build 
WORKDIR /app
COPY . .
RUN mkdir -p /build 
ARG OPTIMIZE=0
RUN npm install --only=production
RUN if [[ "$OPTIMIZE" -eq 1 ]]; then\
        # If optimized, build a bundled binary with the node runtime and the node
        npm install -g pkg &&\
        pkg app.js --compress brotli -t node16-alpine-x64 &&\
        chmod u+x app &&\
        echo "./app" > /build/start.sh &&\
        cp app /build/;\
    else\ 
        # Otherwise, passthru the entire app as usual
        echo "Bypassing optimizations"&&\
        echo "node /app/app.js" > /build/start.sh &&\
        cp -r ./* /build/;\
    fi;
RUN chmod u+x /build/start.sh

FROM alpine:latest as release 
WORKDIR /app
ARG OPTIMIZE=0
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY --chmod=600 --chown=sshd:sshd sshd_config /etc/ssh/
COPY entrypoint.sh /app/entrypoint.sh
RUN if [[ "$OPTIMIZE" -eq 0 ]]; then apk add nodejs;fi && \
    apk add --no-cache openrc openssh nginx su-exec gettext &&\
    # As weird at it seems, the root password MUST be "Docker!" to allow \
    # for SSH connections from the Azure portal
    chmod ugo+x /app/entrypoint.sh &&\
    echo "root:Docker!" | chpasswd &&\
    # The runtime user, having no home dir nor password
    adduser -HD -s /bin/ash appuser &&\
    # Generate SSH keys pairs. On Windows, the authorized cyphers may not work
    cd /etc/ssh && \
    ssh-keygen -A &&\
    cd -
COPY --from=build /build/ .
EXPOSE 3000 50002 3500 80 2222 443
ENTRYPOINT [ "/app/entrypoint.sh" ]