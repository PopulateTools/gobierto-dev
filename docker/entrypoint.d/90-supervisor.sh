#!/bin/sh
set -e

echo "[INFO] Start supervisord..."
/usr/bin/supervisord -c /docker/conf/supervisord.conf