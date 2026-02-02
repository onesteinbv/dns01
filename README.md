A toolkit to handle DNS-01 ACME challenges with a focus on Traefik (lego), Openprovider, and Kubernetes deployments.

# Features

## DNS propagation improvements

- adaptive backoff  
- positive streak detection across authoritative DNS servers  
- stabilization window  
- fallback mode for Traefik

## Standalone operation

`dns01` can run alongside certificate brokers such as lego/Traefik, or standalone in custom workflows:

- certificate generation (via certbot)
- creating A/AAAA target records
- hooks for propagation detection

## Reusable components

- lightweight REST client with CLI support  
- portable file-based spooler for cross-container work  

## Docker / K8S deployment

A Dockerfile and image are provided, along with instructions for Traefik/Kubernetes and other uses.

# Quickstart

### Build and run the container

At the root of this repository:
```bash
docker build -t ghcr.io/onesteinbv/dns01:latest .

docker run --rm \
  -u $UID \
  -e REST_USERNAME=<your Openprovider username> \
  -e REST_PASSWORD=<your Openprovider password> \
  -e DNS01_MODE=spool \
  -e DNS01_SPOOL=/spool \
  -v  "$(pwd):/spool" ghcr.io/onesteinbv/dns01:latest
```

The container will start in **spool mode**, watching a `spool/` subdirectory of the current directory for DNS-01 requests.

### Test a DNS-01 challenge

`./spool.sh some.domain.you.own`

The domain should belong in a zone that you own. Challenges will be attempted using the Let's Encrypt staging server.

# Kubernetes deployment

Head to [Documentation -> Set up and deployment](doc/Documentation.md#set-up-and-deployment) for quick instructions.


# License

This project is licensed under the **GNU Lesser General Public License v3.0 (LGPL-3.0)**  or any later version, at your option.

All original code in this repository is © 2025 Onestein B.V.

Users are free to use, modify, and redistribute the software under the conditions outlined in the license.

The license applies to all scripts and source files in this repository and to the Docker image built from them.

All source files include SPDX license identifiers for automated license compliance.

Contributions are welcome and will be accepted under the same license terms.

See the [LICENSE](LICENSE) file in the repository root for the full text.