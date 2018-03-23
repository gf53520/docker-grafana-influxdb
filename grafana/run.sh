#!/bin/bash

set -m

CONFIG_FILE="/etc/grafana/config.ini"

echo "=> Starting Grafana ..."
exec /usr/sbin/grafana-server --homepath=/usr/share/grafana --config=${CONFIG_FILE} cfg:default.paths.data=/var/lib/grafana cfg:default.paths.logs=/var/log/grafana
