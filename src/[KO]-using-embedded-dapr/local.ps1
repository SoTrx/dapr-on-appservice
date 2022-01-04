$env:COMPONENTS_PATH="../components-local"
$env:NETWORK="meh"
$env:PLACEMENT_HOST="placement"

start powershell { docker stop ${env:PLACEMENT_HOST} ; docker rm ${env:PLACEMENT_HOST} ; docker run --network ${env:NETWORK} --name ${env:PLACEMENT_HOST} -p 50006:50006 -it daprio/dapr ./placement -port 50006; Read-Host }
start powershell { docker stop redis ; docker rm redis ; docker run --network=${env:NETWORK}  --name redis -it redis; Read-Host }
start powershell { docker stop consul ; docker rm consul ; docker run --network=${env:NETWORK} --name consul  -it consul; Read-Host }

sleep 15s

start powershell { docker run -v ${env:COMPONENTS_PATH}:/components --network=${env:NETWORK} -e PLACEMENT_HOST=${env:PLACEMENT_HOST} -it hello-python-with-dapr-local; Read-Host }
start powershell { docker run -v ${env:COMPONENTS_PATH}:/components -e PLACEMENT_HOST=${env:PLACEMENT_HOST} --network=${env:NETWORK} -it hello-node-with-dapr-local; Read-Host }