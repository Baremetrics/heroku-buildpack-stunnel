#!/usr/bin/env bash
URLS=${STUNNEL_URLS}
n=1

mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

pid = /app/vendor/stunnel/stunnel4.pid

socket = r:TCP_NODELAY=1
options = NO_SSLv3
TIMEOUTidle = 86400
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
debug = ${STUNNEL_LOGLEVEL:-notice}
EOFEOF
for URL in $URLS
do
  eval URL_VALUE=\$$URL
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/([^:]+):([^@]+)@(.*?):(.*?)\/([^?]+)\?(.*)$/')
  if [ -z "$PARTS" ]
  then
    PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/:([^@]+)@(.*?):(.*?)\/([^?]+)\?(.*)$/')
    WITHOUT_USERNAME=true
  fi
  URI=( $PARTS )


  if [ "$WITHOUT_USERNAME" = true ] ; then
    URI_SCHEME=${URI[0]}
    URI_PASS=${URI[1]}
    URI_HOST=${URI[2]}
    URI_PORT=${URI[3]}
    STUNNEL_PORT=$URI_PORT
    URI_DB_NAME=${URI[4]}
    QUERY_PARAMS=${URI[5]}

    echo "Setting ${URL} config var"
    export $URL=$URI_SCHEME://:$URI_PASS@127.0.0.1:4342${n}/$URI_DB_NAME?$QUERY_PARAMS

  else
    URI_SCHEME=${URI[0]}
    URI_USER=${URI[1]}
    URI_PASS=${URI[2]}
    URI_HOST=${URI[3]}
    URI_PORT=${URI[4]}
    STUNNEL_PORT=$URI_PORT
    URI_DB_NAME=${URI[5]}
    QUERY_PARAMS=${URI[6]}

    echo "Setting ${URL} config var"
    export $URL=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:4342${n}/$URI_DB_NAME?$QUERY_PARAMS
  fi

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[$URL]
client = yes
accept = 127.0.0.1:4342${n}
connect = $URI_HOST:$STUNNEL_PORT
retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/stunnel/*