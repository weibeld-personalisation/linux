# Linux Setup

Linux setup script for customising and setting up a new Linux installation.

## Scope

The script is supposed to work in the following environments:

- Bare-metal Linux machine
- Linux cloud instance
- Linux VM
- WSL 2 on Windows
- Linux Docker container

## Requirements

1. Debian-based Linux distribution (e.g. Debian, Ubuntu, Kali Linux).
   - If the system doesn't have the `/etc/debian_version` file, the script is aborted
1. Root acces
   - _**Either**_ the script is executed as root
   - _**Or**_ `sudo` installed, the user has a password, and this password is known

> As mentioned, the script currently supports only Debian-based Linux distributions, however, support for other types of Linux distributions is planned.
