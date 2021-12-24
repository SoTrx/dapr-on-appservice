# Dapr on Appservice

![How it works](./assets/images/how-it-works.png)

## The demo app


### Running it locally
To run the sample app locally, you must have Docker and make installed. Then run :
```sh
    make run 
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

@TDB