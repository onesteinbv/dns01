#!/usr/bin/env bash
set -euo pipefail

mode="${MODE:-idle}"

case "$mode" in
  idle)
    echo "[entrypoint] Idle mode: waiting indefinitely"
    tail -f /dev/null
    ;;

  certbot)
    echo "[entrypoint] Running certbot with dns01 hooks"
    exec /opt/dns01/dns01 "$@"
    ;;

  certbot-long)
    echo "[entrypoint] Long-lived certbot mode is not yet implemented"
    exit 2
    ;;

  webhook)
    echo "[entrypoint] Webhook mode is not yet implemented."
    exit 2
    ;;

  *)
    echo "[entrypoint] Unknown MODE='$mode'. Supported: idle, certbot, certbot-long, webhook"
    exit 1
    ;;
esac
