#!/bin/sh

# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2025 Onestein B.V.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SPOOL_JOB="${SPOOL_JOB:-/bin/false}"
SPOOL_DIR="${SPOOL_DIR:-$SCRIPT_DIR/spool}"
SPOOL_TIMEOUT="${SPOOL_TIMEOUT:-1500}"

# synchronous spool client
send_job() {
  REQUEST="$(mktemp "$SPOOL_DIR/$$-XXXXXXXX.request_tmp")" || return 1
  JOB_ID="$(basename "$REQUEST" .request_tmp)"
  {
    for ARG in "$@"; do
      printf '%s' "$ARG" | base64 | tr -d '\n'
      echo
    done
  } > "$REQUEST" && {
    mv "$REQUEST" "${REQUEST%_tmp}" || {
      rm -f "$REQUEST"
      return 1
    }
  }

  RESPONSE="$SPOOL_DIR/$JOB_ID.response"
  i="$SPOOL_TIMEOUT"
  while [ ! -f "$RESPONSE" ]; do
    if [ "$i" -eq 0 ]; then
      echo "[spool] timeout waiting for $RESPONSE" >&2
      return 1
    fi
    i=$((i - 1))

    sleep 1
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
      [ -e "$REQUEST" ] && {
        CLAIM="$(mktemp "${REQUEST%.request}.$$-claimed.XXXXXXXX")" \
        && {
          mv "$REQUEST" "$CLAIM" 2>/dev/null || {
            rm -f "$CLAIM"
            continue
          }
        }
      } || continue

      JOB_ID="$(basename "$CLAIM")"
      JOB_ID="${JOB_ID%%.*}"

      set --
      {
        while IFS= read -r ARG; do
          set -- "$@" "$(printf '%s' "$ARG" | base64 -d)"
        done
      } < "$CLAIM"

      echo "[spool] dispatching asynchronous job id=$JOB_ID (command: $SPOOL_JOB $*)"

      (
        RESPONSE="$SPOOL_DIR/$JOB_ID.response"
        "$SPOOL_JOB" "$@"
        echo $? > "${RESPONSE}_$$" && {
          mv "${RESPONSE}_$$" "$RESPONSE" || rm -f "${RESPONSE}_$$"
        }
      ) &

      rm -f "$CLAIM"
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

  if [ "$COMMAND" = "daemon" ]; then daemon
  else send_job "$COMMAND" "$@"
  fi
}

go "$@"
