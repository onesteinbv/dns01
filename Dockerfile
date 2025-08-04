FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    dnsutils \
    certbot \
 && rm -rf /var/lib/apt/lists/*

COPY dns01 rest common /opt/dns01/
COPY entrypoint.sh /entrypoint.sh

ENV PATH="/opt/dns01:$PATH"
WORKDIR /opt/dns01/

ENTRYPOINT ["/entrypoint.sh"]
