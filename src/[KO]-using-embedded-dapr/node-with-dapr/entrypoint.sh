#!/usr/bin/env ash

# Turn on job management
set -m

# Read all env variable from the container. Used in SSH sessions
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# Start the sshd server
rc-update add sshd
/usr/sbin/sshd

# Start the nginx reverse proxy
nginx&

# Create app service log file
mkdir -p /home/LogFiles
touch /home/LogFiles/dotnet_$WEBSITE_ROLE_INSTANCE_ID_out.log
echo "$(date) Container started" >> /home/LogFiles/dotnet_$WEBSITE_ROLE_INSTANCE_ID_out.log

# Start the app !
echo "Starting default app..."
node /app/app.js &
echo "CONNECTING TO ${PLACEMENT_HOST:-localhost}:${PLACEMENT_PORT:-50006} with APP_ID ${APP_ID:-nodeapp}"

/app/daprd -config config.yaml -dapr-internal-grpc-port "443" -log-level debug -app-id ${APP_ID:-nodeapp} -app-port "${APP_PORT:-3000}" -placement-host-address "${PLACEMENT_HOST:-localhost}":"${PLACEMENT_PORT:-50006}" -components-path "/components" 