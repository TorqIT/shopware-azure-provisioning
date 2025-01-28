RESOURCE_GROUP=$(jq -r '.parameters.resourceGroupName.value' $1)
KEY_VAULT_NAME=$(jq -r '.parameters.keyVaultName.value' $1)
KEY_VAULT_RESOURCE_GROUP_NAME=$(jq -r --arg RESOURCE_GROUP "$RESOURCE_GROUP" '.parameters.keyVaultResourceGroupName.value // $RESOURCE_GROUP' $1)

set +e
az keyvault show \
  --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
  --name $KEY_VAULT_NAME
returnCode=$?
set -e

# If the Key Vault does not yet exist deploy it initially
if [ $returnCode -ne 0 ]; then
  KEY_VAULT_ENABLE_PURGE_PROTECTION=$(jq -r '.parameters.keyVaultEnablePurgeProtection.value // empty' $1)
  echo "Deploying Key Vault..."
  az deployment group create \
    --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
    --template-file ./bicep/key-vault/key-vault.bicep \
    --parameters \
      name=$KEY_VAULT_NAME \
      enablePurgeProtection=$KEY_VAULT_ENABLE_PURGE_PROTECTION
fi

echo "Assigning Key Vault Secrets Officer role to current user..."
PRINCIPAL_TYPE=$(az account show --query "user.type" -o tsv)
az deployment group create \
  --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
  --template-file ./bicep/key-vault/key-vault-roles.bicep \
  --parameters \
    keyVaultName=$KEY_VAULT_NAME \
    principalType=$PRINCIPAL_TYPE

KEY_VAULT_GENERATE_RANDOM_SECRETS=$(jq -r '.parameters.keyVaultGenerateRandomSecrets.value' $1) 
if [ "${KEY_VAULT_GENERATE_RANDOM_SECRETS}" != "null" ] || [ "${KEY_VAULT_GENERATE_RANDOM_SECRETS}" = true ]; then
  echo Adding temporary network rule to the Key Vault firewall...
  az keyvault network-rule add \
    --name $KEY_VAULT_NAME \
    --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
    --ip-address $(curl ipinfo.io/ip)

  SECRETS=("database-admin-password" "app-password" "app-secret")
  for secret in "${SECRETS[@]}"; do
    set +e
    echo Checking for existence of secret $secret in Key Vault...
    az keyvault secret show \
      --vault-name $KEY_VAULT_NAME \
      --name $secret \
      --output none
    returnCode=$?
    set -e
    if [ $returnCode -ne 0 ]; then
      echo Setting random value for secret $secret...
      az keyvault secret set \
        --vault-name $KEY_VAULT_NAME \
        --name $secret \
        --value $(openssl rand -hex 16) \
        --output none
    else
      echo Secret $secret already exists in Key Vault!
    fi
  done
  
  echo Removing network rule for this runner from the Key Vault firewall...
  az keyvault network-rule remove \
    --name $KEY_VAULT_NAME \
    --resource-group $KEY_VAULT_RESOURCE_GROUP_NAME \
    --ip-address $(curl ipinfo.io/ip)
fi