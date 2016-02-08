#!/usr/bin/env bash
n=1
set -e
mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
pid = /app/vendor/stunnel/stunnel4.pid
foreground = yes
options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
sslVersion = TLSv1
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

for STUNNEL_URL in $STUNNEL_URLS; do
  eval STUNNEL_URL_VALUE=\$$STUNNEL_URL
  eval "VAR_NAME=${STUNNEL_URL}_STUNNEL"
  if [[ $STUNNEL_URL_VALUE == "redis://"* ]]; then
    DB=$(echo $STUNNEL_URL_VALUE | perl -lne 'print "$1 $2 $3 $4" if /^redis:\/\/([^:]+):([^@]+)@(.*?):(.*?)$/')
    DB_URI=( $DB )
    DB_USER="${DB_URI[0]}"
    DB_PASS="${DB_URI[1]}"
    DB_HOST="${DB_URI[2]}"
    DB_PORT="$(( DB_URI[3] + 1 )) "
    eval STUNNEL_URL_VALUE="$DB_HOST:$DB_PORT"
    eval "export ${STUNNEL_URL}_STUNNEL=redis://${DB_USER}:${DB_PASS}@127.0.0.1:600${n}"
  else
    eval "export ${STUNNEL_URL}_STUNNEL=127.0.0.1:600${n}"
  fi
  eval echo "Setting $VAR_NAME config var to listen on ${STUNNEL_URL_VALUE}"
  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[$STUNNEL_URL_VALUE]
client = yes
accept = 127.0.0.1:600${n}
connect = $STUNNEL_URL_VALUE
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/stunnel/*
