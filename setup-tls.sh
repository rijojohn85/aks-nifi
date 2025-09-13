# in a working dir (e.g., ~/nifi-test)
mkdir -p tls && cd tls
EXT_IP="$(kubectl -n nifi get svc nifi-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "External IP: ${EXT_IP}"
cat >openssl.conf <<EOF
[req]
distinguished_name=req_distinguished_name
req_extensions=v3_req
prompt=no

[req_distinguished_name]
CN = nifi.nifi.svc.cluster.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = nifi.nifi.svc.cluster.local
DNS.2 = nifi
DNS.3 = nifi-0.nifi.nifi.svc.cluster.local
DNS.4 = nifi-1.nifi.nifi.svc.cluster.local
DNS.5 = localhost
IP.1  = ${EXT_IP}
IP.2  = 127.0.0.1
EOF

# Key → CSR → self-signed cert
openssl genrsa -out nifi-key.pem 2048
openssl req -new -key nifi-key.pem -out nifi.csr -config openssl.conf
openssl x509 -req -in nifi.csr -signkey nifi-key.pem -out nifi-cert.pem -days 365 -extensions v3_req -extfile openssl.conf

# PKCS12 → JKS (passwords = changeit to match NiFi env)
openssl pkcs12 -export -in nifi-cert.pem -inkey nifi-key.pem -out nifi.p12 -name nifi -password pass:changeit
keytool -importkeystore -srckeystore nifi.p12 -srcstoretype PKCS12 -srcstorepass changeit \
  -destkeystore keystore.jks -deststorepass changeit -deststoretype JKS -noprompt

# Truststore with our cert
keytool -import -file nifi-cert.pem -alias nifi-ca -keystore truststore.jks -storepass changeit -noprompt

# K8s secret
kubectl -n nifi create secret generic nifi-tls \
  --from-file=keystore.jks=keystore.jks \
  --from-file=truststore.jks=truststore.jks

cd ..
