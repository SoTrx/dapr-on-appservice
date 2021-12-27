#!/usr/bin/env ash

retryNginx() {
    nginx
    while [ $? -ne 0 ]; do
        echo "Restarting nginx"
        sleep 5
        nginx
    done
}

# Turn on job management
set -m

# Read all env variable from the container. Used in SSH sessions
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# Start the sshd server
rc-update add sshd
/usr/sbin/sshd

envsubst '${DAPR_HOST}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
# Start the nginx reverse proxy
retryNginx &


# Create app service log file
mkdir -p /home/LogFiles
touch /home/LogFiles/dotnet_$WEBSITE_ROLE_INSTANCE_ID_out.log
echo "$(date) Container started" >> /home/LogFiles/dotnet_$WEBSITE_ROLE_INSTANCE_ID_out.log

# Start the app !
echo "Starting default app..."
su-exec appuser /app/start.sh

