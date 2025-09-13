run setup-aks.sh
kubectl apply -f zookeeper-deployment.yaml
kubectl apply -f nifi-services.yaml
wait for some time
run setup-tls.sh
kubectl apply -f nifi-deployment.yaml
