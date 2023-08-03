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
   - Must have the `/etc/debian_version` file
1. Must be run with Bash 4.0 or newer
   - May be either sourced or executed
1. Must have root acces
   - _**Either**_ the script is executed as root
   - _**Or**_ `sudo` is installed and the user has a known password
1. Executables
   - The following executables must be available:
     - `dpkg`
     - `apt`
     - `sudo` (only if the script is run as non-root)
   - All other required dependencies will be installed by the script

> As mentioned, the script currently supports only Debian-based Linux distributions, however, support for other types of Linux distributions is planned.
