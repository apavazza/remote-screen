# Remote Screen 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Secure VNC Access via Temporary SSH Tunnel

## Overview

This script securely exposes a virtual VNC desktop on a Linux host by creating a temporary SSH tunnel user and running a minimal SSH server on a custom port.

Tested on:
- Fedora KDE (Wayland session)
- Wayland-compatible: Works with `krfb-virtualmonitor` on KDE Plasma using Wayland.

## Features

- Creates a limited user for SSH tunneling (no shell access).
- Generates Ed25519 SSH host keys if missing.
- Runs a temporary SSH server on a custom port (default `2222`).
- Starts a virtual monitor VNC session (`1920x1080` by default).
- Cleans up temporary user and SSH server on exit.
- Prints easy-to-follow SSH and VNC connection instructions.

## Important Notes

- **Only open the SSH port (`TMP_SSH_PORT`) in your firewall.**  
  Do **not** expose the VNC port (`VNC_PORT`) externally.
- **Change default passwords** (`VNC_PASSWORD` and `TUNNEL_PASS`) before use.
- Superuser privileges are required to run this script.
- Requires `krfb-virtualmonitor` and SSH server binaries installed.

## Usage

1. Mark the script as executable:
  
    ```bash
    chmod +x remote_screen.sh
    ```

1. Run the script:

    ```bash
    ./remote_screen.sh
    ```

1. Follow the printed instructions to create an SSH tunnel from your client:

    ```bash
    ssh -L 5900:localhost:5900 vncuser@<HOST_IP> -p 2222
    ```

1. Connect your VNC viewer to `localhost:5900` using the VNC password.

## Android Client Support

Use an app like [AVNC](https://github.com/gujjwal00/avnc) to connect via SSH tunnel and access your VNC session on a tablet or phone. This lets you securely use your device as an external monitor.

1. Install AVNC from [F-Droid](https://f-droid.org/packages/com.gaurav.avnc/).
1. Set up the SSH tunnel.
1. Connect to `localhost:5900` with the VNC password.

## Cleanup

The script automatically stops the temporary SSH server and deletes the tunnel user on exit.

## License

This repository is licensed under the [MIT license](LICENSE).
