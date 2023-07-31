#!/usr/bin/env bash

# For now, only Debian-based distributions are supported
if [[ ! -f /etc/debian_version ]]; then
  echo "Error: Linux distribution is not Debian-based"
  exit 1
fi
