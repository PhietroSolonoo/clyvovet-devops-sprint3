#!/bin/bash
RESOURCE_GROUP="rg-clyvovet-sprint3"

echo "Apagando tudo em $RESOURCE_GROUP..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "Exclusao iniciada. Aguarde 2-3 min."
