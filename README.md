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
6. Run `./create-key-vault.sh parameters.json` to create a Key Vault in your Resource Group. Make up a secure database password and add it as a secret to this vault using either the Azure Portal or CLI. Add any other secrets your Container App will need to this vault as well (see `stub.parameters.jsonc` for details on how to reference these).
7. Run `./provision.sh parameters.json` to provision the Azure environment.
8. Once provisioned, follow these steps to seed the database with the Pimcore schema:
   1. Make up a secure password that you will use to log into the Pimcore admin panel and save it somewhere secure such as LastPass.
   2. Ensure that your PHP-FPM image contains the SSL certificate required for communicating with the database (can be downloaded from https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem). The command below assumes the file is present at `/var/www/html/config/db/DigiCertGlobalRootCA.crt.pem`.
   3. Run `az containerapp exec --resource-group <your-resource-group> --name <your-php-fpm-container-app> --command bash` to enter the Container App's shell.
   4. Run the following command to seed the database:
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

## Custom domains and HTTPS certificates

Container Apps support custom domains and Azure-managed HTTPS certificates, but since they require some manual interaction with your DNS, it is best to configure them manually in your initial provisioning. Use this repository to manage these as follows:

1. For the initial provisioning, leave out the `phpFpmContainerAppCustomDomain` and `phpFpmContainerAppCertificateName` parameters from your `parameters.json` file.
2. Once provisioned, go to https://portal.azure.com and navigate to your PHP-FPM Container App.
3. In the left-hand menu, click "Custom Domains". Click "Add", select the "Managed Certificate" option, and follow the instructions for adding a custom domain to your DNS.
4. Once complete, you should be able to access your Container App at the configured custom domain, and it should be secured with HTTPS.
5. Add the `phpFpmContainerAppCustomDomain` and `phpFpmContainerAppCertificateName` parameters to your `parameters.json` file. This will these settings to be maintained whenever you deploy infrastructure updates. The certificate name can be found by going to the Container Apps Environment, clicking "Certificates", and copying the value in the "Friendly name" column.

## Updating an existing environment

Bicep files are declarative, meaning that they declare the desired state of your resources. This means that you can deploy using the same files multiple times, and only the new changes that you've made will be applied. If you wish to change any resource names or properties, simply update them in your `parameters.json` file and re-run `./provision.sh parameters.json`. Keeping the `parameters.json` files committed in your source control is a good practice as it will allow you to maintain a snapshot of your environment's state.

When adding/updating/removing Container Apps secrets for the PHP-FPM container, you will need to deactivate any active revisions that are using the existing secrets (Azure will throw an error if you do not first deactivate). To deactivate a revision, find its revision number in the Azure Portal, then `exec` into this container and run `./scripts/deactivate-php-fpm-container-app-revisions.sh`.

## Useful scripts

Once an environment has been provisioned, the `scripts/` directory contains some useful scripts that can be run against the running environment (see its [README](https://github.com/TorqIT/pimcore-azure-provisioning/blob/main/scripts/README.md)).
