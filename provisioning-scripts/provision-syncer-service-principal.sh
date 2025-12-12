// Creates a service principal for "syncing" data between to Azure environments, namely
// the MySQL databases and Storage Accounts. Accepts a source and target parameter file
// and assigns the necessary roles to the service principal. Mainly for use with 
// https://github.com/TorqIT/pimcore-github-actions-workflows/blob/main/.github/workflows/job-azure-sync.yml.

SOURCE_FILE=$1
TARGET_FILE=$2
SERVICE_PRINCIPAL_NAME="sync-sp"

SERVICE_PRINCIPAL_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].{spID:id}" --output tsv)
if [ -z $SERVICE_PRINCIPAL_ID ]
then
    echo "Creating service principal $SERVICE_PRINCIPAL_NAME..."
    az ad sp create-for-rbac --display-name $SERVICE_PRINCIPAL_NAME
    echo "IMPORTANT: Note the appId and password returned above!"
    SERVICE_PRINCIPAL_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].{spID:id}" --output tsv)
else
    echo "Service principal $SERVICE_PRINCIPAL_NAME already exists"
fi

echo "Assigning roles for service principal..."
az deployment sub create \
    --location eastus \
    --template-file ./bicep/service-principal/sync/syncer-service-principal-roles.bicep \
    --parameters \
    syncerServicePrincipalId=$SERVICE_PRINCIPAL_ID \
    sourceSubscriptionId=$(jq -r '.parameters.subscriptionId.value' $SOURCE_FILE) \
    sourceResourceGroupName=$(jq -r '.parameters.resourceGroupName.value' $SOURCE_FILE) \
    sourceMySqlServerName=$(jq -r '.parameters.databaseServerName.value' $SOURCE_FILE) \
    sourceStorageAccountName=$(jq -r '.parameters.storageAccountName.value' $SOURCE_FILE) \
    targetSubscriptionId=$(jq -r '.parameters.subscriptionId.value' $TARGET_FILE) \
    targetResourceGroupName=$(jq -r '.parameters.resourceGroupName.value' $TARGET_FILE) \
    targetMySqlServerName=$(jq -r '.parameters.databaseServerName.value' $TARGET_FILE) \
    targetStorageAccountName=$(jq -r '.parameters.storageAccountName.value' $TARGET_FILE) \
    targetPhpContainerAppName=$(jq -r '.parameters.phpContainerAppName.value' $TARGET_FILE) \
    targetSupervisordContainerAppName=$(jq -r '.parameters.supervisordContainerAppName.value' $TARGET_FILE)