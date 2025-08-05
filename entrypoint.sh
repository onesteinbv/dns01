#!/usr/bin/env bash

set -euo pipefail

mode="${DNS01_MODE:-idle}"

case "$mode" in
  idle)
    echo "[entrypoint] starting idle mode"
    tail -f /dev/null
    ;;

  spool)
    echo "[entrypoint] starting spool mode"
    cp -f "$DNS01_PATH/spool.sh" "$DNS01_SPOOL/spool.sh"
    [[ -d "$DNS01_SPOOL/spool" ]] || mkdir "$DNS01_SPOOL/spool"
    exec "$DNS01_SPOOL/spool.sh" daemon
    ;;

  certbot)
    echo "[entrypoint] starting certbot mode"
    exec "$DNS01_PATH/dns01" "$@"
    ;;

  certbot-long)
    echo "[entrypoint] Long-lived certbot mode is not yet implemented"
    exit 2
    ;;

  listen)
    echo "[entrypoint] Listen mode is not yet implemented"
    exit 2
    ;;

  *)
    echo "[entrypoint] Unknown mode '$mode'. Supported: idle, spool, certbot, certbot-long, listen"
    exit 1
    ;;
esac
