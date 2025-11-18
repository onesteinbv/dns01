#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPOOL_JOB="${SPOOL_JOB:-/bin/false}"
SPOOL_DIR="${SPOOL_DIR:-$SCRIPT_DIR/spool}"
SPOOL_TIMEOUT="${SPOOL_TIMEOUT:-1500}"

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
  echo "[spool] daemon started from $SCRIPT_DIR, watching spool in $SPOOL_DIR"

  while :; do
    set -- "$SPOOL_DIR"/*.request
    [ -e "$1" ] || { sleep 1; continue; }

    for REQUEST in "$SPOOL_DIR"/*.request; do
      [ -e "$REQUEST" ] || continue

      CMD= ARGS=
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
  cat <<EOF
Usage:
  $0 help
      Show this help.

  $0 daemon
      Start the long-lived spool process.

  $0 <job command> [job args...]
      Synchronously enqueue a job and return its exit status.
EOF
  exit 2
}

go() {
  if [ $# -eq 0 ]; then help
  fi

  COMMAND="$1"
  shift

  if [ "$COMMAND" = "help" ]; then help
  fi

  if [ ! -d "$SPOOL_DIR" ]; then
    echo "fatal: spool directory \"$SPOOL_DIR\" is not present" >&2
    exit 1
  fi

  if [ "$COMMAND" = "daemon" ]; then daemon
  else send_job "$COMMAND" "$@"
  fi
}

go "$@"
