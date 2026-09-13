#!/bin/bash
RESOURCE_GROUP="rg-clyvovet-sprint3"
ACR_NAME="clyvovetrm563358"
KEY_VAULT="kv-clyvovet-rm563358"

ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

echo "Buscando senha do Oracle do Key Vault..."
ORACLE_PASSWORD=$(az keyvault secret show --vault-name $KEY_VAULT --name oracle-password --query value -o tsv)

if [ -z "$ORACLE_PASSWORD" ]; then
  echo "ERRO: Senha nao encontrada no Key Vault"
  exit 1
fi

echo "Criando ACI da API..."
az container create \
  --resource-group $RESOURCE_GROUP \
  --name aci-api-clyvovet \
  --image $ACR_NAME.azurecr.io/clyvovet-api:v1 \
  --cpu 1 \
  --memory 1.5 \
  --os-type Linux \
  --ports 8080 \
  --ip-address Public \
  --dns-name-label aci-api-clyvovet \
  --registry-login-server $ACR_NAME.azurecr.io \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --environment-variables \
    ORACLE_URL="jdbc:oracle:thin:@aci-oracle-clyvovet.southafricanorth.azurecontainer.io:1521/XEPDB1" \
    ORACLE_USER="system" \
    ORACLE_PASSWORD="$ORACLE_PASSWORD"

echo "ACI API criado!"