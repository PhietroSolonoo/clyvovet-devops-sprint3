#!/bin/bash
RESOURCE_GROUP="rg-clyvovet-sprint3"
KEY_VAULT="kv-clyvovet-rm563358"

echo "Buscando senha do Oracle do Key Vault..."
ORACLE_PASSWORD=$(az keyvault secret show --vault-name $KEY_VAULT --name oracle-password --query value -o tsv)

if [ -z "$ORACLE_PASSWORD" ]; then
  echo "ERRO: Senha nao encontrada no Key Vault"
  exit 1
fi

echo "Criando ACI do Oracle..."
az container create \
  --resource-group $RESOURCE_GROUP \
  --name aci-oracle-clyvovet \
  --image gvenzl/oracle-xe:21-slim \
  --cpu 2 \
  --memory 4 \
  --os-type Linux \
  --ports 1521 \
  --ip-address Public \
  --dns-name-label aci-oracle-clyvovet \
  --environment-variables \
    ORACLE_PASSWORD="$ORACLE_PASSWORD"

echo "ACI Oracle criado!"
echo "Aguarde 5-10 min para o Oracle subir"