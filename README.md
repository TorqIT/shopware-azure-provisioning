This Docker image can be used to easily provision an Azure environment to host a Pimcore solution. Follow these steps:

1. Pull the image and run it with either `docker run` or `docker-compose`. With `compose`, use something like the following:
   ```yaml
   services:
     pimcore-azure-provisioning:
        image: ghcr.io/torqit/pimcore-azure-provisioning:latest
        volumes:
           # Necessary for running Docker commands within the container
           - /var/run/docker.sock:/var/run/docker.sock
           # Volume mount in your environment/secret files as needed - copy these from stub.environment.sh and stub.secrets.sh, respectively
           - ./azure/environment.sh:/provisioning/environment.sh
           - ./azure/secrets.sh:/provisioning/secrets.sh
           # You may want instead want to mount in environment and secret files for specific environments
           - ./azure/environment.dev.sh:/provisioning/environment.dev.sh
           - ./azure/secrets.dev.sh:/provisioning/secrets.dev.sh
           - ./azure/environment.prod.sh:/provisioning/environment.prod.sh
           - ./azure/secrets.prod.sh:/provisioning/secrets.prod.sh
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
3. Update `environment.sh` with the appropriate values for your Azure environment, and run it with `. ./environment.sh` to ensure the values are available to the scripts.
4. Run `initialize.sh` to create a Resource Group and Service Principal (which will act as a "user" for the rest of the scripts). Note that this will prompt you to log into Azure in your browser. Once complete, note down the `appId` and `password` that are returned from the creation of the Service Principal (the app ID is the service principal ID).
5. Update `secrets.sh` with the Service Principal credentials from the previous step. Additionally, make up a secure database password and add it here. These values should also be added to LastPass. Ensure that `secrets.sh` is executable by running `chmod +x secrets.sh`, and run `. ./secrets.sh` to make the values available to the remaining scripts. Also, make sure that this file is NOT checked into source control.
6. Run `./provision.sh` to provision the Azure environment. Note that you may experience an error when running this script that complains about the Service Principal not being available in the Resource Group. This appears to just be a lag in the provisioning process - simply wait a minute or two before trying to run `provision.sh` again.
7. The initial deployments of Container Apps from Bicep do not appear to work reliably, so you will likely need to create new revisions of at least the PHP-FPM and supervisord apps (either manually in the portal or via a GitHub Action - see https://github.com/TorqIT/pimcore-github-actions-workflows for examples).
8. Follow these steps to seed the database with the Pimcore schema:
    1. Inside the container, run `. ./environment.sh`, `. ./secrets.sh` and `./login.sh`.
    2. Make up a secure password that you will use to log into the Pimcore admin panel and save it somewhere secure such as LastPass.
    3. Ensure that your PHP-FPM image contains the SSL certificate required for communicating with the database (can be downloaded from https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem). The command below assumes the file is present at `/var/www/html/config/db/DigiCertGlobalRootCA.crt.pem`.
    4. Run `az containerapp exec --resource-group $RESOURCE_GROUP --name $PHP_FPM_CONTAINER_APP_NAME --command bash` to enter the Container App's shell.
    5. Run the following command to seed the database:
       ```bash
       vendor/bin/pimcore-install \
         --admin-username=admin \
         --admin-password=<secure admin password> \         
         --mysql-host-socket=$DATABASE_HOST \
         --mysql-database=$DATABASE_NAME \
         --mysql-username=$DATABASE_USER \         
         --mysql-password=$DATABASE_PASSWORD \         
         --mysql-ssl-cert-path=config/db/DigiCertGlobalRootCA.crt.pem
        ```
9. TODO custom domains and HTTPS certs
10. The `container-app-exec` scripts can be used to enter the shell of a running PHP-FPM Pimcore container app (analogous to SSH'ing into a virtual machine).

