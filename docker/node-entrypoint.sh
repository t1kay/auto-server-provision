#!/bin/bash
# Waits for the control node to publish the lab public key, authorizes it
# for the Ansible user, then runs sshd in the foreground.
set -euo pipefail

PUB_KEY=/keys/id_ed25519.pub
SSH_DIR="/home/${LAB_USER}/.ssh"

for _ in $(seq 1 30); do
    [[ -f "$PUB_KEY" ]] && break
    echo "[node] waiting for ${PUB_KEY}..."
    sleep 1
done
[[ -f "$PUB_KEY" ]] || { echo "[node] public key not found" >&2; exit 1; }

install -d -m 700 -o "$LAB_USER" -g "$LAB_USER" "$SSH_DIR"
install -m 600 -o "$LAB_USER" -g "$LAB_USER" "$PUB_KEY" "$SSH_DIR/authorized_keys"

exec /usr/sbin/sshd -D -e
