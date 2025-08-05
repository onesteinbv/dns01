FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    dnsutils \
    certbot \
 && rm -rf /var/lib/apt/lists/*

ENV DNS01_PATH="/opt/dns01"
ENV PATH="$DNS01_PATH:$PATH"

COPY dns01 "$DNS01_PATH"
COPY spool.sh "$DNS01_PATH/spool.sh"
COPY entrypoint.sh /entrypoint.sh

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
