#!/bin/sh

# Check for curl, attempt to install it if it doesn't exist:
if ! which curl &>/dev/null; then

  echo "gluetun-delay: curl not found, checking for recognized package installers..."

  # Check for apk, apt, dnf, yum, or pacman package managers:
  if which apk &>/dev/null; then
    echo "gluetun-delay: apk found, attempting curl install."
    apk add curl
  fi

  if which apt &>/dev/null; then
    echo "gluetun-delay: apt found, attempting curl install."
    apt install -y curl
  fi

  if which dnf &>/dev/null; then
    echo "gluetun-delay: dnf found, attempting curl install."
    dnf install -y curl
  fi

  if which yum &>/dev/null; then
    echo "gluetun-delay: yum found, attempting curl install."
    yum install -y curl
  fi

  if which pacman &>/dev/null; then
    echo "gluetun-delay: pacman found, attempting curl install."
    pacman -Syu curl
  fi

  # Check again if curl is available:
  if ! which curl &>/dev/null; then
    echo "gluetun-delay: Couldn't install curl, sleeping to prevent container start."
    sleep infinity
  fi

fi

vpn_is_ready=false

echo "gluetun-delay: Checking VPN for readiness."
while [ "$vpn_is_ready" != true ]; do

  if [ "$(curl -s 127.0.0.1:8000/v1/publicip/ip)" != '' ] && [ "$(curl -s 127.0.0.1:8000/v1/publicip/ip)" != '{"public_ip":""}' ]; then
    echo "gluetun-delay: VPN check has succeeded, continuing."
    vpn_is_ready=true
  else
    echo "gluetun-delay: VPN not seen as ready yet, waiting 5 seconds..."
    sleep 5s
  fi

done