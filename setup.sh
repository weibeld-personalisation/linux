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
msg-sub-sub() { __print "        $1"; }
msg-bare() { __print "$1" "$2"; }
err() { __print "ERROR\n$1\n" red; exit 1; }
is-installed() { which "$1" &>/dev/null; }
is-root() { [[ "$UID" = 0 ]]; }
has-cached-sudo-password() { sudo -n true 2>/dev/null; }
run() { eval "$*" &>>"$LOG" || err "Command \"$*\" failed: see $LOG for details"; }
run-pipe() { eval "$*" | tee -a "$LOG" || err "Command \"$*\" failed: see $LOG for details"; }
run-root() { is-root && run "$*" || run "sudo $*"; }
run-apt() { run-root apt -o Acquire::http::Timeout=5 -o APT::Update::Error-Mode=any -o APT::Get::Assume-Yes=true "$@"; }
get-input() { read in; __print "$in\n"; }

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

msg "Checking root access..."
if ! is-root; then
  if ! has-cached-sudo-password; then
    msg-sub "Please enter your user password:\n"
    sudo true
  else
    msg-sub "Sudo password already cached or not needed: "
    # Extend validity of cached password to prevent expiration in this script
    sudo -v
  fi
else
  msg-sub "User is already root: "
fi
ack-sub

#------------------------------------------------------------------------------#
# Install packages
#------------------------------------------------------------------------------#

msg "Installing packages..."

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

msg-sub "Updating package lists: "
run-apt update
ack-sub
for p in "${packages[@]}"; do
  # TODO: check if package is already installed, similar to the optional tools
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
  file=/etc/sudoers.d/config
  if [[ ! -f "$file" ]]; then
    msg-sub "Creating $file: "
    run 'curl -s https://raw.githubusercontent.com/weibeld/sudoers/main/linux | DATE=$(date -Iseconds) envsubst | sudo tee '$file' >/dev/null'
  else
    msg-sub "$file already exists: "
  fi
else
  msg-sub "User is already root: "
fi
ack-sub

#------------------------------------------------------------------------------#
# Optional tools
#------------------------------------------------------------------------------#

tools=(
  Grip
  Go
  Terraform
  Docker
  kubectl
  "AWS CLI"
  "Azure CLI"
  "Google Cloud CLI"
)

is-tool-installed() {
  case "$1" in
    Grip) is-installed grip ;;
    Go) is-installed go ;;
    Terraform) is-installed terraform ;;
    Docker) is-installed docker ;;
    kubectl) is-installed kubectl ;;
    "AWS CLI") is-installed aws ;;
    "Azure CLI") is-installed az ;;
    "Google Cloud CLI") is-installed gcloud ;;
    *) err "Unknown tool: $1"
  esac
}

# Convert a tool name to a corresponding installation function name
function-name() {
  echo "install-$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/-/g')"
}

__get-distro-codename() { lsb_release -cs; }
__get-arch() { dpkg --print-architecture; }
__add-debian-repo() {
  key_url=$1
  key_file=$2
  repo_url=$3
  repo_file=$4
  repo_distro=$5
  repo_comp1=$6
  run-pipe curl -fsSL "$key_url" | run-root gpg --yes --dearmor -o "$key_file"
  run-pipe echo "deb [arch=$(__get-arch) signed-by=$key_file] $repo_url $repo_distro $repo_comp1" | run-root tee "$repo_file"
}

install-grip() {
  run "pip install grip"
}

install-go() {
  run-apt "install golang"
}

install-terraform() {
  __add-debian-repo \
      https://apt.releases.hashicorp.com/gpg \
      /usr/share/keyrings/hashicorp-archive-keyring.gpg \
      https://apt.releases.hashicorp.com \
      /etc/apt/sources.list.d/hashicorp.list \
      $(__get-distro-codename) \
      main
  run-apt update
  run-apt install terraform
}

install-docker() {
  __add-debian-repo \
      https://download.docker.com/linux/ubuntu/gpg \
      /etc/apt/keyrings/docker.gpg \
      https://download.docker.com/linux/ubuntu \
      /etc/apt/sources.list.d/docker.list \
      $(__get-distro-codename) \
      stable
  run-apt update
  run-apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  if ! is-root; then
    run-root usermod -aG docker "$USER"
    newgrp docker
  fi
}

install-kubectl() {
#  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
#
#  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
#
#  # Install the kubectl package
#  run-apt update
#  run-apt install kubectl
#
#  # Install command completion
#  # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-kubectl-autocompletion
#  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null
}

install-azure-cli() {
#  curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
#  #sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
#
#  # Add the Azure CLI Debian repository
#  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
#
#  # Install the Azure CLI package
#  run-apt update
#  run-apt install azure-cli
}

#------------------------------------------------------------------------------#
# Select optional tools to install
#------------------------------------------------------------------------------#

msg "Select tools to install..."
tool-selection-dialog() {

  # Tools selected for installation
  tools_install=()

  # Read answers from user
  msg-sub "Select tools: [y]es (default), [n]o, [s]top\n"
  for t in "${tools[@]}"; do
    msg-sub "$t: "
    case "$(get-input)" in
      y*|Y*|"") tools_install+=("$t") ;;
      s*|S*) break ;;
      n*|N*|*) ;;
    esac
  done

  # Review selected tools
  msg-sub "Selected tools:"
  if [[ "${#tools_install[@]}" -gt 0 ]]; then
    msg-bare "\n"
    ((i=1))
    for t in "${tools_install[@]}"; do
      msg-sub-sub "$i. $t\n"
      ((i++))
    done
  else
    msg-bare " <none>\n"
  fi

  # Proceed to installation or repeat selection
  msg-sub "Proceed to installation? [y]es (default), [n]o: "
  case "$(get-input)" in
    y*|Y*|"") ;;
    n*|N*|*) tool-selection-dialog ;;
  esac
}

tool-selection-dialog

#------------------------------------------------------------------------------#
# Install selected optional tools
#------------------------------------------------------------------------------#

msg "Installing selected tools..."

for t in "${tools_install[@]}"; do
  if ! is-tool-installed "$t"; then
    msg-sub "Installing $t: "
    eval "$(function-name "$t")"
  else
    msg-sub "$t is already installed: "
  fi
  ack-sub
done

#------------------------------------------------------------------------------#
# End
#------------------------------------------------------------------------------#

msg "Done!"
msg-sub "See logs in $LOG\n"
