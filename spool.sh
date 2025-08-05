#!/bin/sh
# spool.sh — job spooler for dns01

# Mode: present|cleanup => client mode; daemon => worker
MODE="$1"; shift

# Derive script directory and default spool directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPOOL_DIR="${DNS01_SPOOL:-$SCRIPT_DIR}/spool"
SPOOL_TIMEOUT=30
SPOOL_JOB="$DNS01_PATH/dns01"

# dispatch request, block until response or timeout
send_job() {
  CMD="$1"; shift

  # timestamp+PID
  JOB_ID="$(date +%s)-$$"
  REQUEST="$SPOOL_DIR/$JOB_ID.request"
  RESPONSE="$SPOOL_DIR/$JOB_ID.response"

  mkdir -p "$SPOOL_DIR"
  # write command and args, one per line
  {
    echo "$CMD"
    for ARG in "$@"; do printf '%s\n' "$ARG"; done
  } > "$REQUEST"

  # wait for a response
  i=0
  while [ ! -f "$RESPONSE" ]; do
    if [ "$i" -ge "$SPOOL_TIMEOUT" ]; then
      echo "[spool] timeout waiting for $RESPONSE" >&2
      return 1
    fi
    sleep 1
    i=$((i + 1))
  done

  # read the response, clean up, and return it
  RETVAL=$(cat "$RESPONSE")
  rm -f "$RESPONSE"
  return "$RETVAL"
}

# daemon mode: watch the spool, handle job dispatching and request/response traffic
daemon() {
  echo "[spool] daemon started in $SPOOL_DIR"
  mkdir -p "$SPOOL_DIR"

  while true; do
    set -- "$SPOOL_DIR"/*.request
    [ -e "$1" ] || { sleep 1; continue; }

    for REQUEST in "$SPOOL_DIR"/*.request; do
      [ -e "$REQUEST" ] || continue
      export JOB_ID="$(basename "$REQUEST" .request)"
      RESPONSE="$SPOOL_DIR/$JOB_ID.response"

      # read command and args line-by-line
      CMD_LINE=""
      JOB_ARGS=""
      # read first line as CMD, remaining lines as args
      { read -r CMD_LINE && JOB_CMD="$CMD_LINE" && JOB_ARGS="$(sed '1d' "$REQUEST")"; } < "$REQUEST"

      echo "[spool] dispatching job id=$JOB_ID (command: \"$JOB_CMD\")"
      set -- $JOB_ARGS
      ( "$SPOOL_JOB" "$JOB_CMD" "$@"; echo "$?" > "$RESPONSE") &
      rm -fv "$REQUEST"
    done
  done
}

help() {
  echo "Usage: $0 {present|cleanup|daemon} [args...]"
  exit 2
}

case "$MODE" in
  present|cleanup) send_job "$MODE" "$@" ;;
  daemon) daemon ;;
  *) help ;;
esac
