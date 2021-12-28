#!/usr/bin/env ash
REQUIRED_ENV_VARS='APP_ID APP_HOST APP_PORT'

retryNginx() {
    nginx
    while [ $? -ne 0 ]; do
        echo "Restarting nginx"
        sleep 5
        nginx
    done
}


# Check for all the env variable to be defined, die if not
checkEnvVar () {
    for element in $REQUIRED_ENV_VARS
    do
        # A bit of shell magic interpolating var from the array.
        # This is quite unsafe but ash as not indirect ${!var} like bash does.
        key=$(echo \"\$${element}\")
        eval "value=$(echo $key)"
        
        if [ -z $value ]; then
             echo "$element is unset. The program will not work properly without it. Aborting !" >&2; 
             exit 1;
        else 
            echo "$element is set to $value"; 
        fi
    done
}

# Turn on job management
set -m

# Read all env variable from the contain${APP_PORT}er. Used in SSH sessions
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)
checkEnvVar

echo "Now starting satcar for ${APP_ID} (${APP_HOST}:${APP_PORT:-80}). Placement service is located at ${PLACEMENT_HOST}:${PLACEMENT_PORT}"

# Start the nginx reverse proxy
envsubst '${APP_HOST} ${APP_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
retryNginx&

# Only pass the placement service arg to Daprd if the variables are defined
# Although this won't stop daprd, a lot of useless warning would be thrown otherwise
OPTIONAL_ARGS="-placement-host-address ${PLACEMENT_HOST}:${PLACEMENT_PORT}"
if [[ -z ${PLACEMENT_HOST}] || -z ${PLACEMENT_PORT} ]]; then
    echo "PLACEMENT_HOST or PLACEMENT_PORT is not defined, placement service won't be used."
    OPTIONAL_ARGS=""
else
    echo "Placement service is ${PLACEMENT_HOST}:${PLACEMENT_PORT}"
fi

su-exec appuser /app/daprd \
-config /config/config.yaml \
-dapr-internal-grpc-port "5555" \
-components-path "/components" \
-log-level debug \
-app-id ${APP_ID:-pythonapp} \
-app-port "${APP_PORT:-80}" \
${OPTIONAL_ARGS}

#/app/daprd -dapr-internal-grpc-port "5555" -log-level debug -app-id ${APP_ID:-pythonapp} -app-port "${APP_PORT:-80}" -placement-host-address "${PLACEMENT_HOST:-localhost}":"${PLACEMENT_PORT:-50006}"