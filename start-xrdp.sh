#!/bin/sh
set -eu

mkdir -p ~/.xrdp

if [ ! -f ~/.xrdp/key.pem -o ! -f ~/.xrdp/cert.pem ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -keyout ~/.xrdp/key.pem -out ~/.xrdp/cert.pem -subj "/CN=xrdp" -days 3653
fi

if [ ! -f ~/.xrdp/xrdp.ini ]; then
  if [ -z "${NEW_PASSWORD:-}" ]; then
    export NEW_PASSWORD=$(openssl rand -base64 33)
  fi
  /etc/xrdp/passwd.expect
  USERNAME=$(id -un)
  sed -e "s/username=ask/username=$USERNAME/" -e "s/password=ask/password=$NEW_PASSWORD/" /etc/xrdp/xrdp.ini > ~/.xrdp/xrdp.ini
fi

DISPLAY=:10 xrdp-sesman --nodaemon --config /etc/xrdp/sesman.ini &
exec xrdp --nodaemon --config ~/.xrdp/xrdp.ini
