#!/bin/bash

mkdir rabbitmq_certs
cd rabbitmq_certs
mkdir certs private
chmod 700 private
echo 01 > serial
touch index.txt
touch openssl.cnf

cat <<'EOF' > openssl.cnf
[ ca ]
default_ca = rootca

[ rootca ]
dir = .
certificate = $dir/ca_certificate.pem
database = $dir/index.txt
new_certs_dir = $dir/certs
private_key = $dir/private/ca_private_key.pem
serial = $dir/serial

default_crl_days = 7
default_days = 365o
default_md = sha256

policy = rootca_policy
x509_extensions = certificate_extensions

[ rootca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = optional
emailAddress = optional
organizationName = optional
organizationalUnitName = optional
domainComponent = optional

[ certificate_extensions ]
basicConstraints = CA:false

[ req ]
default_bits = 2048
default_keyfile = ./private/ca_private_key.pem
default_md = sha256
prompt = yes
distinguished_name = root_ca_distinguished_name
x509_extensions = root_ca_extensions

[ root_ca_distinguished_name ]
commonName = hostname

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

[ client_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.2

[ server_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
EOF

read -p "Enter CA -subj (eg: "/C=SG/ST=SG/L=SG/O=Global/OU=ITDepartment/CN=SWATSupport"):\n " subj
openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 3650 -out ca_certificate.pem -outform PEM -subj $subj -nodes
openssl x509 -in ca_certificate.pem -out ca_certificate.cer -outform DER

mkdir server

read -p "Enter Server 1 -subj (eg: "/C=SG/ST=SG/L=SG/O=Server/OU=DevOps/CN=node01.server.com"):\n " subj1
read -p "Enter Server 2 -subj (eg: "/C=SG/ST=SG/L=SG/O=Server/OU=DevOps/CN=node02.server.com"):\n " subj2
read -p "Enter Server 3 -subj (eg: "/C=SG/ST=SG/L=SG/O=Server/OU=DevOps/CN=node03.server.com"):\n " subj3
openssl genrsa -out server/private_key.pem 2048
openssl req -new -key server/private_key.pem -out server/req_01.pem -outform PEM -subj "$subj1" -nodes
openssl req -new -key server/private_key.pem -out server/req_02.pem -outform PEM -subj "$subj2" -nodes
openssl req -new -key server/private_key.pem -out server/req_03.pem -outform PEM -subj "$subj3" -nodes

date

openssl ca -config openssl.cnf -in server/req_01.pem -out  server/server_certificate_01.pem -notext -batch -extensions server_ca_extensions
openssl ca -config openssl.cnf -in server/req_02.pem -out  server/server_certificate_02.pem -notext -batch -extensions server_ca_extensions
openssl ca -config openssl.cnf -in server/req_03.pem -out  server/server_certificate_03.pem -notext -batch -extensions server_ca_extensions

openssl pkcs12 -export -out server/server_certificate_01.p12 -in server/server_certificate_01.pem -inkey server/private_key.pem  -passout pass:password
openssl pkcs12 -export -out server/server_certificate_02.p12 -in server/server_certificate_02.pem -inkey server/private_key.pem  -passout pass:password
openssl pkcs12 -export -out server/server_certificate_03.p12 -in server/server_certificate_03.pem -inkey server/private_key.pem  -passout pass:password

mkdir client

read -p "Enter Client 1 -subj (eg: "/C=SG/ST=SG/L=SG/O=Client/OU=Team/CN=node01.server.com"):\n " subj4
read -p "Enter Client 2 -subj (eg: "/C=SG/ST=SG/L=SG/O=Client/OU=Team/CN=node02.server.com"):\n " subj5
read -p "Enter Client 3 -subj (eg: "/C=SG/ST=SG/L=SG/O=Client/OU=Team/CN=node03.server.com"):\n " subj6
openssl genrsa -out client/private_key.pem 2048
openssl req -new -key client/private_key.pem -out client/req_01.pem -outform PEM -subj "$subj4" -nodes
openssl req -new -key client/private_key.pem -out client/req_02.pem -outform PEM -subj "$subj5" -nodes
openssl req -new -key client/private_key.pem -out client/req_03.pem -outform PEM -subj "$subj6" -nodes

date

openssl ca -config openssl.cnf -in client/req_01.pem -out client/client_certificate_01.pem -notext -batch -extensions client_ca_extensions
openssl ca -config openssl.cnf -in client/req_02.pem -out client/client_certificate_02.pem -notext -batch -extensions client_ca_extensions
openssl ca -config openssl.cnf -in client/req_03.pem -out client/client_certificate_03.pem -notext -batch -extensions client_ca_extensions

openssl pkcs12 -export -out client/client_certificate_01.p12 -in client/client_certificate_01.pem -inkey client/private_key.pem  -passout pass:password
openssl pkcs12 -export -out client/client_certificate_02.p12 -in client/client_certificate_02.pem -inkey client/private_key.pem  -passout pass:password
openssl pkcs12 -export -out client/client_certificate_03.p12 -in client/client_certificate_03.pem -inkey client/private_key.pem  -passout pass:password

echo "Done !!"
