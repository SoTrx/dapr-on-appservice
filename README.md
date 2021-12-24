# Dapr on Appservice

![How it works](./assets/images/how-it-works.png)

## The demo app

![Demo App](./assets/images/demo-app.png)
There are 3 main components :
- Nodeapp
- Pythonapp
- Satcar [readme](src/using-satcars/satcar/README)


### Running it locally
To run the sample app locally, you must have Docker and make installed. Then run :
```sh
    # The OPTIMIZE flag can be set to 1. 
    # This will reduce the container final size by compressing the binaries (when applicable). 
    # This will however erase debug symbols, to not use it in development
    make OPTIMIZE=0 run 
```
This will build and run the containers and start the apps.

You can also push the nodeapp, pythonapp, satcar images to the Dockerhub with the following command

```sh
    make push DOCKERHUB_USERNAME=<YOUR_DOCKERHUB_USENAME>
```

### Deploying it on azure 
To deploy the app on Azure (using Terraform), use the following commands :
```sh
    cd deploy
    terraform apply 
```

The deployment will last 3 hours or so ( an ASE creation is really slow)


## Viability and performance consideration


@TDB