This Docker image can be used to easily provision an Azure environment to host a Pimcore solution. 

## Initial provisioning
Follow these steps to provision an environment for the first time:

1. Pull the image and run it with either `docker run` or `docker-compose`. With `compose`, use something like the following:
   ```yaml
   services:
     pimcore-azure-provisioning:
        image: ghcr.io/torqit/pimcore-azure-provisioning:latest
        volumes:
           # Necessary for running Docker commands within the container
           - /var/run/docker.sock:/var/run/docker.sock
           # Volume mount in your parameter file as needed - copy this from stub.parameters.jsonc and
           # fill in your values
           - ./azure/parameters.json:/azure/parameters.json
           # You may also want to declare per-environment files like so
           - ./azure/parameters.dev.json:/azure/parameters.dev.json
           - ./azure/parameters.prod.json:/azure/parameters.prod.json
         environment:
           # These vars are required so that the scripts can properly tag and
           # push the necessary images to Azure. Ensure these images are built
           # and set the values here to match the image names (can be found by
           # running docker image ls).
           - LOCAL_PHP_FPM_IMAGE=${LOCAL_PHP_FPM_IMAGE}
           - LOCAL_SUPERVISORD_IMAGE=${LOCAL_SUPERVISORD_IMAGE}
           - LOCAL_REDIS_IMAGE=${LOCAL_REDIS_IMAGE}
   ```
2. Enter the container shell with `docker exec -it <container-name> bash`.
3. Update `parameters.json` with the appropriate values for your Azure environment. Note that the comments present in `stub.parameters.jsonc` will need to be removed.
4. Run `./login-to-tenant.sh parameters.json` and follow the browser prompts to log in.
5. If a Resource Group and Service Principal have not yet been created (e.g. if you are not an Owner in the Azure tenant), run `initialize-resource-group-and-service-principal.sh parameters.json`. Once complete, note down the `appId` and `password` that are returned from the creation of the Service Principal (the app ID is the service principal ID).
6. Run  `./create-key-vault.sh parameters.json` to create a Key Vault in your Resource Group. Make up a secure database password and add it as a secret to this vault using either the Azure Portal or CLI. Add any other secrets your Container App will need to this vault as well (see `stub.parameters.jsonc` for details on how to reference these).
7. Run `./provision.sh parameters.json` to provision the Azure environment. 
8. Once provisioned, follow these steps to seed the database with the Pimcore schema:
    1. Make up a secure password that you will use to log into the Pimcore admin panel and save it somewhere secure such as LastPass.
    2. Ensure that your PHP-FPM image contains the SSL certificate required for communicating with the database (can be downloaded from https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem). The command below assumes the file is present at `/var/www/html/config/db/DigiCertGlobalRootCA.crt.pem`.
    3. Run `az containerapp exec --resource-group <your-resource-group> --name <your-php-fpm-container-app> --command bash` to enter the Container App's shell.
    5. Run the following command to seed the database:
       ```bash
       runuser -u www-data -- vendor/bin/pimcore-install \
         --admin-username=admin \
         --admin-password=<secure admin password> \         
         --mysql-host-socket=$DATABASE_HOST \
         --mysql-database=$DATABASE_NAME \
         --mysql-username=$DATABASE_USER \         
         --mysql-password=$DATABASE_PASSWORD \         
         --mysql-ssl-cert-path=config/db/DigiCertGlobalRootCA.crt.pem \
         --ignore-existing-config \
         --skip-database-config
        ```
9. TODO custom domains and HTTPS certs

## Updating an existing environment

TODO how to update an existing environment (e.g. updating DB storage size, adding Container Apps envs/secrets)
