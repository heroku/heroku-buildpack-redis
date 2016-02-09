#!/usr/bin/env bash
n=1
set -e

mkdir -p /app/vendor/ssh


cat > /app/vendor/ssh/ssh_config << EOFEOF
ForwardAgent no
IdentityFile /app/tmp/bastion.pem

Host bastion
     User ubuntu
     HostName 52.91.193.157
     BatchMode yes
     ExitOnForwardFailure yes
     StrictHostKeyChecking no
EOFEOF

for SSH_URL in $SSH_URLS; do
  eval SSH_URL_VALUE=\$$SSH_URL
  eval "VAR_NAME=${SSH_URL}_SSHTUNNEL"
  if [[ $SSH_URL_VALUE == "redis://"* ]]; then
    DB=$(echo $SSH_URL_VALUE | perl -lne 'print "$1 $2 $3 $4" if /^redis:\/\/([^:]+):([^@]+)@(.*?):(.*?)$/')
    DB_URI=( $DB )
    DB_USER="${DB_URI[0]}"
    DB_PASS="${DB_URI[1]}"
    DB_HOST="${DB_URI[2]}"
    DB_PORT="$(( DB_URI[3] + 1 )) "
    eval SSH_URL_VALUE="$DB_HOST:$DB_PORT"
    eval "export ${SSH_URL}_SSHTUNNEL=redis://${DB_USER}:${DB_PASS}@127.0.0.1:600${n}"
  else
    eval "export ${SSH_URL}_SSHTUNNEL=127.0.0.1:600${n}"
  fi
  eval echo "Setting $VAR_NAME config var to listen on ${SSH_URL_VALUE}"
  cat >> /app/vendor/ssh/ssh_config << EOFEOF
     LocalForward 600${n} $SSH_URL_VALUE
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/ssh/*
