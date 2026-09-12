#!/bin/bash
RESOURCE_GROUP="rg-clyvovet-sprint3"
LOCATION="southafricanorth"
ACR_NAME="clyvovetrm563358"

echo "Criando Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Registrando providers..."
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerInstance
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault

echo "Criando ACR..."
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Standard \
  --location $LOCATION \
  --public-network-enabled true \
  --admin-enabled true

echo "Setup concluido!"
