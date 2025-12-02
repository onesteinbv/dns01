# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2025 Onestein B.V.

FROM debian:bullseye-slim

# OCI image metadata
LABEL org.opencontainers.image.title="dns01"
LABEL org.opencontainers.image.description="Adaptive DNS-01 propagation checks with Openprovider, Traefik integration"
LABEL org.opencontainers.image.url="https://github.com/onesteinbv/dns01"
LABEL org.opencontainers.image.source="https://github.com/onesteinbv/dns01"
LABEL org.opencontainers.image.documentation="https://github.com/onesteinbv/dns01/blob/main/Documentation.md"
LABEL org.opencontainers.image.vendor="Onestein B.V."
LABEL org.opencontainers.image.licenses="LGPL-3.0-or-later"


# Filled dynamically at build time
ARG VERSION="dev"
ARG REVISION="unknown"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${REVISION}"

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
