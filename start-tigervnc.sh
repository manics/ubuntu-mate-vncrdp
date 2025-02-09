#!/bin/sh
set -eu

LOCALHOST_ARGS="-localhost no --I-KNOW-THIS-IS-INSECURE"

if [ ! -d /home/ubuntu/Desktop ]; then
  echo "First run, setting up ubuntu"
  rsync /home/ubuntu.orig/ -av --ignore-existing /home/ubuntu/
fi

/usr/bin/tigervncserver :1 -fg $LOCALHOST_ARGS -SecurityTypes None -xstartup /usr/local/bin/start-mate.sh
