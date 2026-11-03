#!/bin/bash
# Generates a throw-away SSH key pair for the lab into the shared /keys volume
# (nodes read the public key from there), then keeps the container running.
set -euo pipefail

KEY_DIR=/keys
mkdir -p "$KEY_DIR"

if [[ ! -f "$KEY_DIR/id_ed25519" ]]; then
    echo "[control] generating lab SSH key pair"
    ssh-keygen -t ed25519 -N "" -C "ansible-lab" -f "$KEY_DIR/id_ed25519.tmp" -q
    mv "$KEY_DIR/id_ed25519.tmp.pub" "$KEY_DIR/id_ed25519.pub"
    mv "$KEY_DIR/id_ed25519.tmp" "$KEY_DIR/id_ed25519"
fi

install -m 600 "$KEY_DIR/id_ed25519" /root/.ssh/id_ed25519

exec "$@"
