The scripts in this directory can be used to easily provision an Azure environment to host a Pimcore solution. Follow these steps:

1. Pull the image and run it with either `docker run` or `docker-compose`. With `compose`, use the following specification:
   ```yaml
   services:
     pimcore-azure-provisioning:
        image: torqitdev/pimcore-azure-provisioning:latest
        volumes:
           # Necessary for running Docker commands within the container
           - /var/run/docker.sock:/var/run/docker.sock
           # Volume mount in your environment/secret files as needed - copy these from stub.environment.sh and stub.secrets.sh, respectively
           - environment.sh:/provisioning/environment.sh
           - secrets.sh:/provisioning/secrets.sh
         environment:
           # These vars are required so that the scripts can properly tag and
           # push the necessary images to Azure. Ensure these images are built
           # and set the values here to match the image names.
           - LOCAL_PHP_FPM_IMAGE:${LOCAL_PHP_FPM_IMAGE}
           - LOCAL_SUPERVISORD_IMAGE:${LOCAL_SUPERVISORD_IMAGE}
           - LOCAL_REDIS_IMAGE:${LOCAL_REDIS_IMAGE}
   ```
2. Enter the container shell with `docker exec -it <container-name> bash`.
3. Update `environment.sh` with the appropriate values for your Azure environment, and run it with `. ./environment.sh` to ensure the values are available to the scripts.
4. Run `initialize.sh` to create a Resource Group and Service Principal (which will act as a "user" for the rest of the scripts). Note that this will prompt you to log into Azure in your browser. Once complete, note down the `appId` and `password` that are returned from the creation of the Service Principal (the app ID is the service principal ID).
5. Update `secrets.sh` with the Service Principal credentials from the previous step. Additionally, make up a secure database password and add it here. These values should also be added to LastPass. Ensure that `secrets.sh` is executable by running `chmod +x secrets.sh`, and run `. ./secrets.sh` to make the values available to the remaining scripts. Also, make sure that this file is NOT checked into source control.
6. Run `./provision.sh` to provision the Azure environment. Note that you may experience an error when running this script that complains about the Service Principal not being available in the Resource Group. This appears to just be a lag in the provisioning process - simply wait a minute or two before trying to run `provision.sh` again.
7. The initial deployments of Container Apps from Bicep do not appear to work reliably, so you will likely need to create new revisions of at least the PHP-FPM and supervisord apps (either manually in the portal or via a GitHub Action).
8. TODO custom domains and HTTPS certs
