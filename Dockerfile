# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2025 Onestein B.V.

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y bash curl jq dnsutils certbot \
  && rm -rf /var/lib/apt/lists/*

ENV DNS01_PATH="/opt/dns01"
ENV PATH="$DNS01_PATH:$PATH"

COPY dns01 "$DNS01_PATH"
COPY spool.sh "$DNS01_PATH"
RUN chmod -R 755 "$DNS01_PATH"

COPY entrypoint /
RUN chmod 755 /entrypoint
ENTRYPOINT ["/entrypoint"]
