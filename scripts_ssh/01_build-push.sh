#!/bin/bash
ACR_NAME="clyvovetrm563358"

echo "Login no ACR..."
TOKEN=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken)
echo $TOKEN | docker login $ACR_NAME.azurecr.io \
  --username 00000000-0000-0000-0000-000000000000 \
  --password-stdin

echo "Build da imagem..."
docker build -t clyvovet-api:v1 .

echo "Tag + Push..."
docker tag clyvovet-api:v1 $ACR_NAME.azurecr.io/clyvovet-api:v1
docker push $ACR_NAME.azurecr.io/clyvovet-api:v1

echo "Imagem no ACR!"
