#!/bin/bash
set -e

echo "[INFO] Init container"
echo "127.0.0.1 $HOST" >> /etc/hosts
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
