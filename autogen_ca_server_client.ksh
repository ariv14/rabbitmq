#!/usr/bin/ksh

function Create_CA_and_MQ_Server_Certs {

print -n "Please enter RabbitMQ 1st server hostname: "
read server1

print -n "Please enter RabbitMQ 1st server IP: "
read IP1

print -n "Please enter RabbitMQ 2nd server hostname: "
read server2

print -n "Please enter RabbitMQ 2nd server IP: "
read IP2

print -n "Please enter RabbitMQ 3rd server hostname: "
read server3

print -n "Please enter RabbitMQ 3rd server IP: "
read IP3

echo
echo "RabbitMQ server1 hostname = " $server1
echo "RabbitMQ server1 IP = " $IP1
echo "RabbitMQ server2 hostname = " $server2
echo "RabbitMQ server2 IP = " $IP2
echo "RabbitMQ server3 hostname = " $server3
echo "RabbitMQ server3 IP = " $IP3
echo
print -n "Do you want to continue (Y/N): "
read ANSWER
if [[ $ANSWER = 'N' || $ANSWER = 'n' ]]
then
	return
fi

mkdir /root/mqcerts
cd /root/mqcerts
mkdir ca server client

# Creating CA certs for self signing RabbitMQ host certs

openssl genrsa -out ca/ca_key.pem 2048
openssl req -x509 -sha256 -new -nodes -key ca/ca_key.pem -days 3650 -out ca/ca_certificate.pem -subj "/C=SG/L=SH/O=IT/CN=SWATMQ"

# Creating certificate requests for all hosts | Update CN with MQServer fqdn hostnames

openssl genrsa -out server/rabbitmq_key.pem 2048
openssl req -new -key server/rabbitmq_key.pem -out server/rabbitmq_01.csr -subj "/C=SG/L=SH/O=SWAT/CN=$server1"
openssl req -new -key server/rabbitmq_key.pem -out server/rabbitmq_02.csr -subj "/C=SG/L=SH/O=SWAT/CN=$server2"
openssl req -new -key server/rabbitmq_key.pem -out server/rabbitmq_03.csr -subj "/C=SG/L=SH/O=SWAT/CN=$server3"

# Create conf file | Prerequisite for creating self signed RabbitMQ certs

touch rabbitmq.conf

echo "subjectAltName = @alt_names"  > rabbitmq.conf 
echo "[alt_names]"  >> rabbitmq.conf
echo "DNS.1 = localhost"  >> rabbitmq.conf
echo "IP.2 = $IP1"  >> rabbitmq.conf
echo "IP.3 = $IP2"  >> rabbitmq.conf
echo "IP.4 = $IP3"  >> rabbitmq.conf

# Create self signed RabbitMQ certs

openssl x509 -req -in server/rabbitmq_01.csr -CA ca/ca_certificate.pem -CAkey ca/ca_key.pem -CAcreateserial -out server/rabbitmq_certificate_01.pem -days 3650 -sha256 -extfile rabbitmq.conf
openssl x509 -req -in server/rabbitmq_02.csr -CA ca/ca_certificate.pem -CAkey ca/ca_key.pem -CAcreateserial -out server/rabbitmq_certificate_02.pem -days 3650 -sha256 -extfile rabbitmq.conf
openssl x509 -req -in server/rabbitmq_03.csr -CA ca/ca_certificate.pem -CAkey ca/ca_key.pem -CAcreateserial -out server/rabbitmq_certificate_03.pem -days 3650 -sha256 -extfile rabbitmq.conf
chown -R rabbitmq:rabbitmq /root/mqcerts
echo  "Done !!"

}

function Client_certs {

cd /root/mqcerts
mkdir ca server client

print -n "Please enter Client server hostname: "
read client_server1

print -n "Please enter Client server IP: "
read CIP1


echo
echo "Client server1 hostname = " $client_server1
echo "Client server1 IP = " $CIP1
echo
print -n "Do you want to continue (Y/N): "
read ANSWER
if [[ $ANSWER = 'N' || $ANSWER = 'n' ]]
then
        return
fi


# Create self signed Client certs

openssl genrsa -out client/client_key.pem 2048
openssl req -new -key client/client_key.pem -out client/client.csr -subj "/C=SG/L=SH/O=SWAT/CN=mqconsumer"

# Create conf file | Prerequisite for creating self signed Client certs

touch client.conf

echo "subjectAltName = @alt_names"  > client.conf 
echo "[alt_names]"  >> client.conf
echo "DNS.1 = localhost"  >> client.conf
echo "IP.2 = $CIP1"  >> client.conf

openssl x509 -req -in client/client.csr -CA ca/ca_certificate.pem -CAkey ca/ca_key.pem -CAcreateserial -out client/client_certificate.pem -days 3650 -sha256 -extfile client.conf
openssl pkcs12 -export -in client/client_certificate.pem -inkey client/client_key.pem -out client/client.pkcs12 -password pass:password 
keytool -importcert -keystore client/BrokerSslServerTrustStore.jks -storepass password -file ca/ca_certificate.pem -alias mqconsumer -noprompt
chown -R rabbitmq:rabbitmq /root/mqcerts

}

function Start_Menu {

clear

typeset -i ANSWER
let ANSWER=0

while [[  $ANSWER -ne 10 ]]
do

echo "The utility allows to perform the following certificate creations:"
echo "------------------------------------------------------------"
echo "1. Create CA and self signed RabbitMQ Servers certs"
echo "2. Create Client certs and jks"
echo "3. Exit"
echo
echo ------------------------------------------------------------
print -n "Please enter the option: "
read ANSWER
# echo ANSWER = $ANSWER
case $ANSWER in
	1) echo You have selected option:    Create CA and self signed RabbitMQ Servers certs
		Create_CA_and_MQ_Server_Certs		
		;;
	2) echo You have selected option:    Create Client certs and jks
		Client_certs
		;;
	3)echo "You have selected option:    Exit"
		;;
	*) echo The option you have selected is not available.
		;;
esac
done
}

Start_Menu
