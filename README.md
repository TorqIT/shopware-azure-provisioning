This Docker image can be used to easily provision an Azure environment to host a Shopware solution, leveraging Docker and [Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview).

## Initial provisioning

Follow these steps to provision an environment for the first time:

1. Pull the image and run it with either `docker run` or `docker-compose`. With `compose`, use something like the following:
   ```yaml
   services:
     shopware-azure-provisioning:
        image: ghcr.io/torqit/shopware-azure-provisioning:latest
        volumes:
           # Necessary for running Docker commands within the container
           - /var/run/docker.sock:/var/run/docker.sock
           # Volume mount in your parameter file as needed - copy this from stub.parameters.json and
           # fill in your preferred values
           - ./azure/parameters.json:/azure/parameters.json:rw
           # You may also want to declare per-environment files like so
           - ./azure/parameters.dev.json:/azure/parameters.dev.json:rw
           - ./azure/parameters.prod.json:/azure/parameters.prod.json:rw
           # Define a volume to hold your login information between container restarts
           - azure:/root/.azure
   volumes:
      azure:
   ```
2. Update `parameters.json` with the appropriate values for your Azure environment. Note that the comments present in `stub.parameters.json` will need to be removed. Note that you will also need to remove the parameters related to custom domains and certificates (see section below) for the initial provisioning.
3. Enter the container shell with `docker exec -it <container-name> bash`.
4. Run `./login-to-tenant.sh parameters.json` and follow the browser prompts to log in. If you wish to use a Service Principal instead of your Microsoft account to perform the provisioning, instead run `az login --service-principal -u <service principal id> -p <service principal password> --tenant <your tenant>`.
5. If a Resource Group has not yet been created (e.g. if you are not an Owner in the Azure tenant), ensure it is created before running any scripts. Ensure also that you have Owner permissions on the created Resource Group.
6. Run `./create-key-vault.sh parameters.json` to create a Key Vault in your Resource Group. Once created, navigate to the created Key Vault in the Azure Portal and use the "Access control (IAM)" blade to add yourself to the "Key Vault Secrets Officer" role (the Owner role at the Resource Group will allow you to do this; but it is not itself sufficient to actually manage secrets). Additionally, make sure the Key Vault is using a "Role-based Access Policy" in the "Access configuration" blade. Make up a secure database password and add it as a secret to this vault using either the Azure Portal or CLI (make sure the `databasePasswordSecretName` value matches the secret name in the vault). Add any other secrets your Container App will need to this vault as well (see `stub.parameters.jsonc` for details on how to reference these).
   1. NOTE: There is an open issue to improve the Key Vault scripting (see [#50](https://github.com/TorqIT/pimcore-azure-provisioning/issues/50))
7. Run `./provision.sh parameters.json` to provision the Azure environment.
8. On first run of the script, a Service Principal will be created with permissions that will allow it to deploy to your environment via CI/CD workflows. Note down the appId and password returned by this section of the script.

## Custom domains and HTTPS certificates

Container Apps support custom domains and Azure-managed HTTPS certificates, but since they require some manual interaction with your DNS, it is best to configure them manually in your initial provisioning. Use this repository to manage these as follows:

1. For the initial provisioning, leave the `shopwareContainerAppCustomDomains` array blank, like so:
   ```
   "shopwareContainerAppCustomDomains": {
     "value": [
     ]
   },
   ```
2. Once your environment is provisioned, go to https://portal.azure.com and navigate to your Shopware Container App.
3. In the left-hand menu, click "Custom Domains". Click "Add", select the "Managed Certificate" option, and follow the instructions for adding a custom domain to your DNS.
4. Once complete, you should be able to access your Container App at the configured custom domain, and it should be secured with HTTPS.
5. Add the custom domain and certificate to the `shopwareContainerAppCustomDomains` parameter in your `parameters.json` file like so:
   ```
   "shopwareContainerAppCustomDomains": {
      "value": [
         {
            "domainName": "my-domain.example.com"
            "certificateName": "my-certificate"
         }
      ]
   }
   ```
   This will ensure these settings are maintained whenever you deploy infrastructure updates. The certificate name can be found by going to the Container Apps Environment, clicking "Certificates", and copying the value in the "Friendly name" column.

## Automated backups

The provisioning script will automatically configure the following backups:

1. Point-in-time snapshots of the database. Retention of these snapshots is controlled by the `databaseBackupRetentionDays` parameter.
2. Point-in-time snapshots of the Storage Account (which contains persistent Shopware files such as assets). Retention of these snapshots is controlled by the `storageAccountBackupRetentionDays` parameter.
3. Long-term backups of the database. The provisioning script will automatically create a Backup Vault that stores weekly backups of the database. These backups are retained for up to one year.
4. Long-term backups of the Storage Account. The script will use the Backup Vault created above to store monthly backups of the Storage Account containers. These backups are retained for up to one year.

Note that all backups are stored using Local Redundancy (see https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy#locally-redundant-storage for more information).

## Configuring CI/CD

See https://github.com/TorqIT/shopware-github-actions-workflows for examples of GitHub Actions workflows that can be used to deploy to Container Apps, in particular the `container-apps-*.yml` files.

## Updating an existing environment

Bicep files are declarative, meaning that they declare the desired state of your resources. This means that you can deploy using the same files multiple times, and only the new changes that you've made will be applied. If you wish to change any resource names or properties, simply update them in your `parameters.json` file and re-run `./provision.sh parameters.json`. Keeping the `parameters.json` files committed in your source control is a good practice as it will allow you to maintain a snapshot of your environment's state.

When adding/updating/removing Container Apps secrets for the Shopware web container, you will need to deactivate any active revisions that are using the existing secrets (Azure will throw an error if you do not first deactivate). To deactivate the active revisions, enter this container and run `./scripts/deactivate-shopware-container-app-revisions.sh parameters.json`.

## Useful scripts

Once an environment has been provisioned, the `scripts/` directory contains some useful scripts that can be run against the running environment (see its [README](https://github.com/TorqIT/shopware-azure-provisioning/blob/main/scripts/README.md)).
