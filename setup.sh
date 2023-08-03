#!/usr/bin/env bash

# Exit on first error
#set -e

#------------------------------------------------------------------------------#
# Log file
#------------------------------------------------------------------------------#

LOG=log-$(date '+%Y%m%d%H%M%S')-setup.log
echo "# Source: https://github.com/weibeld/linux-setup" >>"$LOG"
echo -e "# Created on: $(date -Iseconds)\n" >>"$LOG"

#------------------------------------------------------------------------------#
# Functions
#------------------------------------------------------------------------------#

# Print an optionally coloured string to both stdout and the log file.
# Usage:
#   __print str [col]
# Args:
#   str:  the string to print
#   col:  an optional colour, accepted values are: 'red', 'green', 'cyan'
# Notes:
#   - If the 'col' argument is omitted, then no colour is applied
#   - The colour is only applied to text printed to stdout, not the log file
#   - No newline at the end of the string is applied. If the printed string
#     should end in a newline, it must be explicitly specified with '\n'
#   - All common special characters (e.g. '\n', '\t') are recognised
__print() {
  local str=$1
  local col_name=$2
  case "$col_name" in
    red) local col_code=$(echo -e '\e[1;31m') ;;
    green) local col_code=$(echo -e '\e[1;32m') ;;
    cyan) local col_code=$(echo -e '\e[1;36m') ;;
    *) unset col_name ;;
  esac
  printf -- "$str" >>"$LOG"
  if [[ -n "$col_name" ]]; then
    printf -- "$col_code$str\e[0m"
  else
    printf -- "$str"
  fi
}

msg() { __print "\n==> $1\n" cyan; }
ack() { __print "    OK\n" green; }
msg-sub() { __print "    - $1"; }
ack-sub() { __print "OK\n" green; }
msg-bare() { __print "$1" "$2"; }
err() { __print "ERROR\n$1\n" red; exit 1; }
is-installed() { which "$1" &>/dev/null; }
is-root() { [[ "$UID" = 0 ]]; }
run() { eval "$*" &>>"$LOG" || err "Command \"$*\" failed: see $LOG for details"; }
run-root() { is-root && run "$*" || run "sudo $*"; }
run-apt() { run-root apt -o Acquire::http::Timeout=5 -o APT::Update::Error-Mode=any -o APT::Get::Assume-Yes=true "$@"; }

#------------------------------------------------------------------------------#
# Banner
#------------------------------------------------------------------------------#

msg-bare "+------------------------------------+\n" cyan
msg-bare "| Welcome to the Linux setup script! |\n" cyan
msg-bare "+------------------------------------+\n" cyan

#------------------------------------------------------------------------------#
# Check requirements
#------------------------------------------------------------------------------#

msg "Checking requirements..."

# Must be a Debian-based Linux distribution
msg-sub "Is a Debian-based system: "
if [[ ! -f /etc/debian_version ]]; then
  err "Linux distribution is not Debian-based"
fi
ack-sub

# Must be run with Bash and Bash version must be at least 4.0
msg-sub "Is executed with Bash >= 4.0: "
shell=$(readlink /proc/"$$"/exe)
if [[ ! "$shell" =~ /bash$ ]]; then
  err "This script must be executeed with Bash (currently being executed with $shell)"
elif [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  err "Bash version must be 4.0 or newer (current Bash version is $BASH_VERSION)"
fi
ack-sub

# Must have root access
msg-sub "Has 'sudo' installed or is root: "
if ! is-installed sudo && ! is-root; then
  err "The 'sudo' command is not installed and the script is not run as root: can't provide root access"
fi
ack-sub

# Must have dpkg and apt installed
msg-sub "Has 'dpkg' and 'apt' installed: "
if ! is-installed dpkg; then
  err "The 'dpkg' command is not installed"
elif ! is-installed apt; then
  err "The 'apt' command is not installed"
fi
ack-sub

#------------------------------------------------------------------------------#
# Get user password for root access
#------------------------------------------------------------------------------#

msg "Enabling root access..."
if ! is-root; then
  msg-sub "Please enter your user password:\n"
  run-root -k echo -n
  ack-sub
else
  msg-sub "User is already root: "
  ack-sub
fi

#------------------------------------------------------------------------------#
# Install packages
#------------------------------------------------------------------------------#

packages=(
curl
dos2unix
fzf
gettext
gifsicle
git
imagemagick
iproute2
iputils-ping
jq
lsb-release
neovim
net-tools
netcat
python-is-python3
python3
python3-pip
ripgrep
traceroute
tree
unzip
vim
wget
)

msg "Installing packages..."

msg-sub "Updating package lists: "
run-apt update
ack-sub
for p in "${packages[@]}"; do
  msg-sub "Installing '$p': "
  run-apt install "$p"
  ack-sub
done
msg-sub "Cleaning packages: "
run-apt autoremove
ack-sub
msg-sub "Upgrading packages: "
run-apt upgrade
ack-sub

#------------------------------------------------------------------------------#
# Install dotfiles
#------------------------------------------------------------------------------#

msg "Installing dotfiles (https://github.com/weibeld/dotfiles)..."
if [[ ! -d ~/.dotfiles ]]; then
  msg-sub "Running install script: "
  # TODO: improve installation script to work from any directory
  run '(cd "$HOME" && bash -c "$(curl -Ls https://bit.ly/get-my-dotfiles)")'
  # TODO: delete backup directory
else
  msg-sub "Dotfiles already installed: "
fi
ack-sub

#------------------------------------------------------------------------------#
# Install custom sudoers file
#------------------------------------------------------------------------------#

msg "Installing custom sudoers file..."
if ! is-root; then
  msg-sub "Creating /etc/sudoers.d/config: "
  run 'curl -s https://raw.githubusercontent.com/weibeld/sudoers/main/linux | DATE=$(date -Iseconds) envsubst | sudo tee /etc/sudoers.d/config >/dev/null'
else
  msg-sub "User is already root: "
fi
ack-sub

#------------------------------------------------------------------------------#
# Install optional specialised tools
#------------------------------------------------------------------------------#

# TODO: start loop asking whether to install each tool
# Tools:
# - Go
# - Terraform
# - Docker
# - kubectl
# - AWS CLI
# - Azure CLI
# - Google Cloud CLI
# - Grip

msg "Done!"
msg-sub "Logs in $LOG: "
ack-sub
