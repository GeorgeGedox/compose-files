#!/bin/bash
set -e

export NAME="${NAME:-p4depot}"

bash /usr/local/bin/setup.sh

sleep 2

exec /usr/bin/tail --pid=$(cat /var/run/p4d.$NAME.pid) -F "/data/$NAME/logs/log"
