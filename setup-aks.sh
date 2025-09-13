#! /bin/bash
# --- Your variables (edit as needed) ---
RG="rg-nifi-aks"
LOC="westeurope" # pick your nearest Azure region
AKS="nifi-aks"
NODE_COUNT=2                # enough for a 2-node NiFi
NODE_SIZE="Standard_D4s_v5" # 4 vCPU, 16 GB RAM per node
K8S_VERSION=""              # leave blank for latest GA on region, or set "1.xx.x"

# --- Login & subscription (skip if already done) ---
# az login
# az account set --subscription "<your-subscription-id>"

# --- Resource group ---
# az group create -n "$RG" -l "$LOC"
echo "Creating AKS cluster in resource group $RG (location: $LOC)"
# --- AKS cluster (managed identity + ssh keys auto-generated) ---
az aks create \
  -g "$RG" -n "$AKS" \
  --enable-managed-identity \
  --node-count $NODE_COUNT \
  --node-vm-size "$NODE_SIZE" \
  ${K8S_VERSION:+--kubernetes-version $K8S_VERSION} \
  --generate-ssh-keys
echo "AKS cluster $AKS created"
echo "Setting kubeconfig context to $AKS"
# --- Kubeconfig ---
az aks get-credentials -g "$RG" -n "$AKS"

echo "Creating nifi namespace and checking storage classes"
# --- Dedicated namespace for NiFi ---
kubectl create namespace nifi
kubectl get ns nifi
kubectl get sc
