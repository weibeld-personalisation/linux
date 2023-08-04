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
# TODO: pass http_proxy, https_proxy, and no_proxy variables to sudo to make it work from the beginning for systems that use a proxy
run-root() { is-root && run "$*" || run "sudo http_proxy=$http_proxy https_proxy=$https_proxy no_proxy=$no_proxy $*"; }
run-apt() { run-root apt -o Acquire::http::Timeout=5 -o APT::Update::Error-Mode=any -o APT::Get::Assume-Yes=true "$@"; }
input() { read in; __print "$in\n"; }
get-distro-codename() { lsb_release -cs; }
get-arch() { dpkg --print-architecture; }

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
# TODO: split and have different message for both cases
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

# TODO: check internet access with and without sudo (use dpkg or apt which are guaranteed to be installed)

#------------------------------------------------------------------------------#
# Get user password for root access
#------------------------------------------------------------------------------#

msg "Checking root access..."
if ! is-root; then
  if ! has-cached-sudo-password; then
    msg-sub "Please enter your user password:\n"
    sudo true
  else
    msg-sub "Sudo password cached or not needed: "
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
  man
  neovim
  net-tools
  netcat-openbsd
  pipx
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
  # TODO: check if package is already installed, similar to the optional tools: dpkg -l <package> &>/dev/null
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
  run '(cd "$HOME" && bash -c "$(curl -Lks https://bit.ly/get-my-dotfiles)" && rm -rf ~/.dotfiles.backup)'
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

#------------------------------------------------------------------------------#
# Steps to add a new tool to this script:
#   1. Add name of the tool to the 'tools' array
#   2. Add an 'install-*' and 'is-installed-*' function
#      - Suffix must be the result of 'tool-to-id "<Tool Name>"'
#------------------------------------------------------------------------------#

# Available tools
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

# Convert a tool name to a normalised identifier (e.g. "AWS CLI" => "aws-cli")
tool-to-id() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/-/g'
}

# Add a custom Debian repository (including the signing GPG key)
add-debian-repo() {
  key_url=$1
  repo_url=$2
  key_file=$3
  repo_file=$4
  repo_distro=$5
  repo_comp1=$6
  run-pipe curl -fsSL "$key_url" | run-root gpg --yes --dearmor -o "$key_file"
  # See format here: https://wiki.debian.org/DebianRepository/Format
  run-pipe echo "deb [arch=$(get-arch) signed-by=$key_file] $repo_url $repo_distro $repo_comp1" | run-root tee "$repo_file"
}

#------#
# Grip |
#------#
install-grip() {
  # Use pipx to avoid "error: externally-managed-environment" on Debian 12
  run pipx install grip;
  run mkdir -p ~/.config/grip
  run '{ echo "TODO-ADD-GITHUB-PERSONAL-ACCESS-TOKEN-NO-SCOPES" >~/.config/grip/personal-access-token; }'
}
is-installed-grip() { is-installed grip; }

#----#
# Go |
#----#
install-go() { run-apt install golang; }
is-installed-go() { is-installed go; }

#-----------#
# Terraform |
#-----------#
install-terraform() {
  # https://developer.hashicorp.com/terraform/downloads
  add-debian-repo \
    https://apt.releases.hashicorp.com/gpg \
    https://apt.releases.hashicorp.com \
    /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    /etc/apt/sources.list.d/hashicorp.list \
    $(get-distro-codename) \
    main
  run-apt update
  run-apt install terraform
  # Completion: set up by .bashrc in dotfiles
}
is-installed-terraform() { is-installed terraform; }

#--------#
# Docker |
#--------#
install-docker() {
  # https://docs.docker.com/engine/install/ubuntu/
  add-debian-repo \
    https://download.docker.com/linux/ubuntu/gpg \
    https://download.docker.com/linux/ubuntu \
    /etc/apt/keyrings/docker.gpg \
    /etc/apt/sources.list.d/docker.list \
    $(get-distro-codename) \
    stable
  run-apt update
  run-apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Allow current user to use Docker without sudo
  if ! is-root; then
    run-root usermod -aG docker "$USER"
    newgrp docker
  fi
  # Completion: package installation drops script in /usr/share/bash-completion/completions
}
is-installed-docker() { is-installed docker; }

#---------#
# kubectl |
#---------#
install-kubectl() {
  # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
  add-debian-repo \
    https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    https://apt.kubernetes.io/ \
    /etc/apt/keyrings/kubernetes-archive-keyring.gpg \
    /etc/apt/sources.list.d/kubernetes.list \
    kubernetes-xenial \
    main
  run-apt update
  run-apt install kubectl
  # Completion
  run-pipe kubectl completion bash | run-root tee /etc/bash_completion.d/kubectl >/dev/null;
}
is-installed-kubectl() { is-installed kubectl; }

#-----------#
# Azure CLI |
#-----------#
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux
install-azure-cli() {
  add-debian-repo \
    https://packages.microsoft.com/keys/microsoft.asc \
    https://packages.microsoft.com/repos/azure-cli/ \
    /etc/apt/keyrings/microsoft.gpg \
    /etc/apt/sources.list.d/azure-cli.list
    $(get-distro-codename) \
    main
  run-apt update
  run-apt install azure-cli
  # Completion: package installation drops script in /etc/bash_completion.d
}
is-installed-azure-cli() { is-installed az; }

#---------#
# AWS CLI |
#---------#
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
install-aws-cli() {
  run curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
  run unzip -q awscliv2.zip
  run-root ./aws/install
  run rm -rf aws awscliv2.zip
  # Completion: set up by .bashrc in dotfiles
}
is-installed-aws-cli() { is-installed aws; }

#------------------#
# Google Cloud CLI |
#------------------#
# https://cloud.google.com/sdk/docs/install-sdk#linux
install-google-cloud-cli() {
  run curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-440.0.0-linux-x86_64.tar.gz -o ~/google-cloud-cli.tar.gz
  # Creates ~/google-cloud-sdk 
  run tar -xf ~/google-cloud-cli.tar.gz
  run rm ~/google-cloud-cli.tar.gz
  # Completion
  run-root cp ~/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/google-cloud-cli
  # PATH: ~/google-cloud-sdk/bin is added to PATH by .bashrc in dotfiles
}
is-installed-google-cloud-cli() { is-installed gcloud; }

#------------------------------------------------------------------------------#
# Select tools to install
#------------------------------------------------------------------------------#

msg "Select tools to install..."
tool-selection-dialog() {

  # Tools selected for installation
  selected=()

  # Read answers from user
  msg-sub "Select tools: [y]es (default), [n]o, [s]top\n"
  for t in "${tools[@]}"; do
    msg-sub "$t: "
    case "$(input)" in
      y*|Y*|"") selected+=("$t") ;;
      s*|S*) break ;;
      n*|N*|*) ;;
    esac
  done

  # Review selected tools
  msg-sub "Selected tools:"
  if [[ "${#selected[@]}" -gt 0 ]]; then
    msg-bare "\n"
    ((i=1))
    for t in "${selected[@]}"; do
      msg-sub-sub "$i. $t\n"
      ((i++))
    done
  else
    msg-bare " <none>\n"
  fi

  # Proceed to installation or repeat selection
  msg-sub "Proceed to installation? [y]es (default), [n]o: "
  case "$(input)" in
    y*|Y*|"") ;;
    n*|N*|*) tool-selection-dialog ;;
  esac
}

tool-selection-dialog

#------------------------------------------------------------------------------#
# Install selected tools
#------------------------------------------------------------------------------#

msg "Installing selected tools..."

for t in "${selected[@]}"; do
  if ! is-installed-"$(tool-to-id "$t")"; then
    msg-sub "Installing $t: "
    install-"$(tool-to-id "$t")"
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
