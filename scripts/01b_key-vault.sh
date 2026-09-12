#!/bin/bash
RESOURCE_GROUP="rg-clyvovet-sprint3"
LOCATION="southafricanorth"
KEY_VAULT="kv-clyvovet-rm563358"

if [ -z "$ORACLE_PASSWORD" ]; then
  read -s -p "Digite a senha do Oracle: " ORACLE_PASSWORD
  echo ""
fi

echo "Criando Key Vault..."
az keyvault create --resource-group $RESOURCE_GROUP --name $KEY_VAULT --location $LOCATION

echo "Concedendo permissao..."
az role assignment create --role "Key Vault Secrets Officer" \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope $(az keyvault show --name $KEY_VAULT --query id -o tsv)

sleep 30

echo "Adicionando segredos..."
az keyvault secret set --vault-name $KEY_VAULT --name oracle-password --value "$ORACLE_PASSWORD"
az keyvault secret set --vault-name $KEY_VAULT --name oracle-user --value "system"
az keyvault secret set --vault-name $KEY_VAULT --name oracle-url \
  --value "jdbc:oracle:thin:@aci-oracle-clyvovet.southafricanorth.azurecontainer.io:1521/XEPDB1"

echo "Segredos armazenados!"