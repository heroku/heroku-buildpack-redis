#!/usr/bin/env bash
URLS=${REDIS_STUNNEL_URLS:-REDIS_URL `compgen -v HEROKU_REDIS`}
n=1

mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

pid = /app/vendor/stunnel/stunnel4.pid

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
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/([^:]+):([^@]+)@(.*?):(.*?)(\/(.*?)(\\?.*))?$/')
  URI=( $PARTS )
  URI_SCHEME=${URI[0]}
  URI_USER=${URI[1]}
  URI_PASS=${URI[2]}
  URI_HOST=${URI[3]}
  URI_PORT=${URI[4]}
  STUNNEL_PORT=$((URI_PORT + 1))

  echo "Setting ${URL}_STUNNEL config var"
  export ${URL}_STUNNEL=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:637${n}

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[$URL]
client = yes
accept = 127.0.0.1:637${n}
connect = $URI_HOST:$STUNNEL_PORT
retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/stunnel/*
