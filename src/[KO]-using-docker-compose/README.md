# KO Demo : Docker-compose

From the [following article from the Microsoft documentation](https://docs.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux), we learn that :

+ build (not allowed)
+ **depends_on** (ignored)
+ **networks** (ignored)
+ **expose** (ignored)
+ secrets (ignored)
+ ports other than 80 and 8080 (ignored)

Are not supported. 

This is why we can't use sidecars in App Services.

We could however use remote sidecars as we did in the accepted solution, grouping a main app and its sidecar in a single docker-compose file. 
Plus, this wouldn't require an external DNS resolver, as we could use the docker default network in itself.
Nonetheless, this won't solve the **HTTP/2.0 is not supported in App Service** and sidecars won't be able to communicate.

This approach is a no go.