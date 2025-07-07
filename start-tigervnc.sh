#!/bin/sh
set -eu

VNC_PASSWD=/etc/vnc/ubuntu/passwd

if [ ! -f "$VNC_PASSWD" ]; then
  if [ "${NO_PASSWORD:-}" = "1" ]; then
    AUTH_ARGS="--I-KNOW-THIS-IS-INSECURE -SecurityTypes None"
  elif [ -z "${NEW_PASSWORD:-}" ]; then
    echo "NEW_PASSWORD must be set unless NO_PASSWORD=1"
    exit 1
  else
    # Not needed, but no harm setting the os passwd anyway
    /etc/xrdp/passwd.expect
    echo "$NEW_PASSWORD" | vncpasswd -f > "$VNC_PASSWD"
    AUTH_ARGS="-PasswordFile $VNC_PASSWD"
  fi
fi

unset NEW_PASSWORD

if [ ! -d /home/ubuntu/Desktop ]; then
  echo "First run, setting up ubuntu"
  rsync /home/ubuntu.orig/ -av --ignore-existing /home/ubuntu/
fi

/usr/bin/tigervncserver :1 -fg -localhost no $AUTH_ARGS -xstartup /usr/local/bin/start-mate.sh
