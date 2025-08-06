#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPOOL_DIR="${DNS01_SPOOL:-$SCRIPT_DIR}/spool"
SPOOL_JOB="${DNS01_PATH:-.}/dns01"
SPOOL_TIMEOUT="${DNS01_TIMEOUT:-1500}"

# synchronous spool client
send_job() {
  CMD="$1"; shift

  JOB_ID="$(date +%s)-$$"
  { echo "$CMD"; for ARG in "$@"; do printf '%s\n' "$ARG"; done; } > "$SPOOL_DIR/$JOB_ID.request"

  RESPONSE="$SPOOL_DIR/$JOB_ID.response"
  i="$SPOOL_TIMEOUT"
  while [ ! -f "$RESPONSE" ]; do
    if [ "$i" -eq 0 ]; then
      echo "[spool] timeout waiting for $RESPONSE" >&2
      return 1
    fi
    sleep 1
    i=$((i - 1))
  done

  RETVAL=$(cat "$RESPONSE")
  rm -f "$RESPONSE"
  return "$RETVAL"
}

# watch the spool, handle job dispatching and request/response traffic
daemon() {
  echo "[spool] daemon started in $SCRIPT_DIR, spool in $SPOOL_DIR"

  while true; do
    set -- "$SPOOL_DIR"/*.request
    [ -e "$1" ] || { sleep 1; continue; }

    for REQUEST in "$SPOOL_DIR"/*.request; do
      [ -e "$REQUEST" ] || continue

      CMD="" ARGS=""
      { read -r CMD && ARGS="$(cat)"; } < "$REQUEST"

      export JOB_ID="$(basename "$REQUEST" .request)"
      echo "[spool] dispatching asynchronous job id=$JOB_ID (command: \"$CMD\")"

      set -- $ARGS
      ( "$SPOOL_JOB" "$CMD" "$@"; echo "$?" > "$SPOOL_DIR/$JOB_ID.response") &
      rm -f "$REQUEST"
    done
  done
}

help() {
  echo "Usage: $0 {present|cleanup|daemon} [args...]"
  exit 2
}

go() {
  COMMAND="$1"
  shift

  case "$COMMAND" in
    present|cleanup) send_job "$COMMAND" "$@" ;;
    daemon) daemon ;;
    *) help ;;
  esac
}

go "$@"
