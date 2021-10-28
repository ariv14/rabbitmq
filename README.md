# rabbitmq
Setup RabbitMq HA cluster



keytool -genkeypair -keystore rootca.jks -storepass password -keyalg RSA -validity 3650 -keypass password -alias rabbitmq -dname "CN=*.innolab.idemia.com,OU=Lab, O=IDEMIA, L=SG S=SG C=SG" -ext san=dns:node01.innolab.idemia.com,dns:node02.innolab.idemia.com,dns:node03.innolab.idemia.com,ip:192.168.18.47,ip:192.168.18.48,ip:192.168.18.49
keytool -importkeystore -srckeystore rootca.jks -destkeystore trustcert.p12 -deststoretype pkcs12 -srcstorepass password -deststorepass password -alias rabbitmq
openssl pkcs12 -in trustcert.p12 -out server_cert.pem -passin pass:password -passout pass:password
mkdir testca server client
sed -n '/-----BEGIN ENCRYPTED PRIVATE KEY-----/,/-----END ENCRYPTED PRIVATE KEY-----/p' server_cert.pem > enc.pem
openssl rsa  -in enc.pem  -out unenc.pem  -passin pass:password
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' server_cert.pem > cert.pem
cp cert.pem /etc/rabbitmq/testca/cacert.pem
cp cert.pem /etc/rabbitmq/server/cert.pem
cp unenc.pem /etc/rabbitmq/server/key.pem
cp cert.pem /etc/rabbitmq/client/cert.pem
cp unenc.pem /etc/rabbitmq/client/key.pem 
chown -R rabbitmq: /etc/rabbitmq/testca
chown -R rabbitmq: /etc/rabbitmq/server
chown -R rabbitmq: /etc/rabbitmq/client
