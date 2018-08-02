#!/bin/bash

## Log Start date
echo "----------------------------------------------------------------------------------------------------"
echo "Start date: "`date`
echo "----------------------------------------"
echo ""

## Set Locale
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

## Preconditions
if [ "$EUID" -eq 0 ]; then

## Define dehydrated and le-godaddy-dns path
LETSENCRYPT_BASEPATH="/data/letsencrypt"
CONFIG_FILE="/data/letsencrypt/renew_certificates.conf"

## Copy the domains to dehydrated config 
cat $CONFIG_FILE > dehydrated/domains.txt

## Generate the certificates
echo "INFO: BEGIN certificate renew..."
$LETSENCRYPT_BASEPATH/dehydrated/dehydrated --challenge dns-01 -k $LETSENCRYPT_BASEPATH/le-godaddy-dns/godaddy.py -c
echo "INFO: DONE certificate renew!"

## Move the certificates to the /etc/ssl/certs/ and /etc/ssl/private/
echo "INFO: BEGIN to move the certificates and keys to /etc/ssl ..."

while read d; do

	DOMAIN=${d%% *}
	CERT_FILE=$LETSENCRYPT_BASEPATH"/dehydrated/certs/"$DOMAIN"/fullchain.pem"
	KEY_FILE=$LETSENCRYPT_BASEPATH"/dehydrated/certs/"$DOMAIN"/privkey.pem"

	if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]
	then
		echo "INFO: Certificate: "$CERT_FILE" and privatekey: "$KEY_FILE" FOUND! Move to /etc/ssl/"

		cp "$CERT_FILE" "/data/certs/$DOMAIN.crt"

        cp "$KEY_FILE" "/data/keys/$DOMAIN.key"

		expirationDate=$(openssl x509 -enddate -noout -in $CERT_FILE)
		expirationDate=${expirationDate#*=}

	else
		echo "WARN: Cannot find Certificate: "$CERT_FILE" or privatekey: "$KEY_FILE"!!!"
	fi
done <$CONFIG_FILE
echo "INFO: DONE to move the certificates and keys to /data/certs and /data/keys !"

echo "INFO: DONE with certificate renew!"

else
  echo "ERROR: Please run script as root!"
fi

## Log End date
echo ""
echo "----------------------------------------"
echo "End date: "`date`
echo "----------------------------------------------------------------------------------------------------"
echo ""
