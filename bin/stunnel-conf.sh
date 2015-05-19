#!/usr/bin/env bash

URLS=${REDIS_URLS:-REDIS_URL}

mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

for URL in $URLS
do
  eval URL_VALUE=\$$URL
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+)::\/\/([^:]+):([^@]+)@(.*?):(.*?)\/(.*?)(\\?.*)?$/')
  URI=( $PARTS )
  SCHEME=${URI[0]}
  USER=${URI[1]}
  PASS=${URI[2]}
  HOST=${URI[3]}
  PORT=${URI[4]}
  PATH=${URI[5]}

  echo "Setting ${URL}_STUNNEL config var"
  export ${URL}_STUNNEL=$SCHEME://$USER:$PASS@127.0.0.1:$PORT/$PATH

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
  [$URL]
  client = yes
  accept = 127.0.0.1:$PORT
  connect = $HOST:$PORT
  retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
  EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/stunnel/*
