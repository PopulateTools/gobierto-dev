#!/bin/sh
set -e

echo "[INFO] Exec entrypoint.d"
export PATH="$HOME/.rbenv/bin:$PATH"

chown ${USER_ID}:${GROUP_ID} -R /docker/entrypoint.d/*
chmod +x -R /docker/entrypoint.d/*
chown ${USER_ID}:${GROUP_ID} -R /docker/executable/sh/*
chmod +x -R /docker/executable/sh/*
run-parts --regex="^[a-zA-Z0-9._-]+$" --report /docker/entrypoint.d