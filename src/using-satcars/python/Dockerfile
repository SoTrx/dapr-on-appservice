# Expected size:
#   Unoptimized : 83MB
#   Optimized : 33MB

FROM python:3.7.1-alpine3.8 as build
ARG OPTIMIZE=0
WORKDIR /app
RUN apk add alpine-sdk zlib zlib-dev && pip install pyinstaller
COPY requirements.txt . 
RUN pip install -r requirements.txt && mkdir /build
COPY . . 
RUN if [[ "$OPTIMIZE" -eq 1 ]]; then\
        # If optimized, build a bundled binary
        # First, build a dynamically-linked app
        pyinstaller -F app.py &&\
        # Then, relink it statically to prevent runtime weirdnesses
        # We need patchelf and scons, which are on the edge repo 
        echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
        apk update && \
        # Deps of staticx
        apk add patchelf scons && \
        pip install staticx && \
        staticx dist/app app_static &&\
        chmod u+x app_static &&\
        echo "./app_static" > /build/start.sh &&\
        cp app_static /build/;\
    else\ 
        # Otherwise, passthru the entire app as usual
        echo "Bypassing optimizations"&&\
        echo "python3 /app/app.py" > /build/start.sh &&\
        cp -r ./* /build/;\
    fi;
RUN chmod u+x /build/start.sh

FROM alpine:latest as release
WORKDIR /app
ARG OPTIMIZE=0
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY --chmod=600 --chown=sshd:sshd sshd_config /etc/ssh/
COPY entrypoint.sh /app/entrypoint.sh 
COPY --from=build /build/ .
RUN \
    # If the app isn't bundled, install the python runtime and the app dependencies 
    if [[ "$OPTIMIZE" -eq 0 ]]; then\
         apk add --no-cache python3 py3-pip && \
        pip3 --no-cache-dir install -r /app/requirements.txt;\
    fi &&\
    chmod ugo+x /app/entrypoint.sh &&\
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
EXPOSE 3500 80 8000 2222 443
ENTRYPOINT [ "/app/entrypoint.sh" ]
