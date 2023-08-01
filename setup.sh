#!/usr/bin/env bash

# Exit on first error
set -e

# Log file for all output
LOG=~/setup.log

#------------------------------------------------------------------------------#
# Functions
#------------------------------------------------------------------------------#

msg() {
  echo
  echo "==> $1" | tee -a "$LOG"
}

msg-sub() {
  echo "--> $1" | tee -a "$LOG"
}

msg-bare() {
  echo "$1" | tee -a "$LOG"
}

ack() {
  echo OK | tee -a "$LOG"
}

err() {
  echo "Error: $1" | tee -a "$LOG"
  exit 1
}

is-installed() {
  which "$1" &>/dev/null
}


#------------------------------------------------------------------------------#
# Entry gate
#------------------------------------------------------------------------------#

if [[ ! -f /etc/debian_version ]]; then
  err "Linux distribution is not Debian-based"
fi

#------------------------------------------------------------------------------#
# Preliminary checks and setup
#------------------------------------------------------------------------------#

# Request password for all subsequent sudo commands
msg-bare WELCOME
msg-bare "Please enter your user password:"
sudo msg-bare Thanks!

# Check internet connection
msg "Checking internet connection..."
if ! ping -c 1 google.com &>>"$LOG"; then
  err "No internet connection detected"
fi
ack

# Update Debian package lists
msg "Updating package lists..."
sudo apt update &>>"$LOG"
ack

#------------------------------------------------------------------------------#
# Install dotfiles
#------------------------------------------------------------------------------#

# See https://github.com/weibeld/dotfiles
msg "Installing dotfiles..."
if ! is-installed git; then
  msg-sub "Installing Git dependency..."
  sudo apt install git &>>"$LOG"
  ack
fi
if ! is-installed wget; then
  msg-sub "Installing wget dependency..."
  sudo apt install wget &>>"$LOG"
  ack
fi

# TODO: make idempotent (check for ~/.dotfiles)
wget -q -O - http://bit.ly/get-my-dotfiles | bash >>"$LOG"
. ~/.bash_profile
ack

#------------------------------------------------------------------------------#
# Configure sudo
#------------------------------------------------------------------------------#

msg "Configuring sudo..."
cat <<EOF | sudo tee /etc/sudoers.d/settings >/dev/null
Defaults:$USER !authenticate
Defaults !secure_path
Defaults env_keep += HOME
Defaults env_keep += EDITOR
Defaults env_keep += "http_proxy https_proxy no_proxy"
EOF
ack
