# Linux Setup

Interactive Linux setup script for setting up a new Linux installation.

> Currently, only Debian-based Linux distributions are supported (e.g. Debian, Ubuntu).

## Target platforms

The script is intended to be used on the following types of platforms:

1. Bare-metal machines
1. Cloud instances
1. VMs
1. WSL on Windows
1. Containers

## Features

The script performs the following setup:

1. **Install basic packages**
   - See `packages` array in [`setup.sh`](setup.sh)
1. **Install dotfiles**
   - See [dotfiles](https://github.com/weibeld/dotfiles) repository
1. **Configure sudoers**
   - See [sudoers](https://github.com/weibeld/sudoers) repository
1. **Install optional tools**
   - [Grip](https://github.com/joeyespo/grip)
   - [Go](https://go.dev/)
   - [Terraform](https://www.terraform.io/)
   - [Docker](https://www.docker.com/)
   - [kubectl](https://kubernetes.io/docs/reference/kubectl/)
   - [AWS CLI](https://aws.amazon.com/cli/)
   - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
   - [Google Cloud CLI](https://cloud.google.com/cli)

## Usage

Simply download and execute the `setup.sh` script:

```bash
wget https://raw.githubusercontent.com/weibeld/linux-setup/main/setup.sh
chmod +x setup.sh
./setup.sh
```

Sourcing the script does also work, however it will set or overwrite some variables in the current environment, thus execution is preferred.

> **CAUTION:** do not try to run the script with `curl https://... | bash` as it will break the interactive part of the script and the script will fail.

## Requirements

The following requirements must be met by the environment for the script to run successfully:

| # | Requirement                               | Notes                                                                                                                                 |
|---|:------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| 1 | Must be a Debian-based Linux distribution | Other Linux distribution families (e.g. Red Hat) are currently not supported.                                                          |
| 2 | Must be executed with Bash                | Other shells like Zsh are not supported.                                                                                               |
| 3 | Must have root acces                      | Either `sudo` must be installed or the script must be executed as root (see note about [execution as root](#execution-as-root) below) |
| 4 | Must have `dpkg` and `apt` installed      | These are the only two binaries that the script initially depends on.                                                                 |
| 5 | Must have internet access                 | For example, if there's a proxy, the corresponding proxy variables (e.g. `http_proxy`) must be set before running the script.         |

## Notes

### Execution as root

If the script is executed as root, then no setup for non-root users will be done. For example, the sudoers configuration will be skipped entirely.

### Bash version

There's no clear minimum version of Bash that is required to run the script. However, the script has been tested to work down to Bash 4.0, thus, the script should work with literally all Bash versions in use on current Linux systems (considering that Bash 4.0 is from 2009).

## Support

The script has so far been verified to work on the following systems:

| System | Versions |
|--------|----------|
| Ubuntu | 22.04    |
| Debian | 12       |
