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
gunicorn -w 4 serv:app -b 0.0.0.0:8000 & 
echo "CONNECTING TO ${PLACEMENT_HOST:-localhost}:${PLACEMENT_PORT:-50006} with APP_ID ${APP_ID:-pythonapp}"
/app/daprd -config config.yaml -dapr-internal-grpc-port "80" -log-level debug -app-port 8000 -app-id ${APP_ID:-pythonapp} -placement-host-address "${PLACEMENT_HOST:-localhost}":"${PLACEMENT_PORT:-50006}" -components-path "/components" &
sleep 10s
python /app/app.py