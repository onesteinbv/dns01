#!/bin/sh

# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2025 Onestein B.V.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPOOL_JOB="${SPOOL_JOB:-/bin/false}"
SPOOL_DIR="${SPOOL_DIR:-$SCRIPT_DIR/spool}"
SPOOL_TIMEOUT="${SPOOL_TIMEOUT:-1500}"
SPOOL_WORKERS="${SPOOL_WORKERS:-1}"

# synchronous spool client
send_job() {
  JOB_ID="$(date +%s)-$$"
  {
    for ARG in "$@"; do
      printf '%s' "$ARG" | base64 | tr -d '\n'
      echo
    done
  } > "$SPOOL_DIR/$JOB_ID.request"

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

      export JOB_ID="$(basename "$REQUEST" .request)"

      set --
      {
        while IFS= read -r ARG; do
          set -- "$@" "$(printf '%s' "$ARG" | base64 -d)"
        done
      } < "$REQUEST"

      echo "[spool] dispatching asynchronous job id=$JOB_ID (command: $SPOOL_JOB $*)"

      ( "$SPOOL_JOB" "$@"; echo "$?" > "$SPOOL_DIR/$JOB_ID.response") &
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

  $0 [job args...]
    Synchronously enqueue a job forwarding any arguments, and return its exit status.
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

  if [ "$COMMAND" = "daemon" ]; then
    for _ in $(seq 1 "$SPOOL_WORKERS"); do
     daemon &
    done
    wait
  else send_job "$COMMAND" "$@"
  fi
}

go "$@"
