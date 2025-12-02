These are tools to handle DNS-01 ACME challenges with a focus on Traefik (Lego), OpenProvider, and Kubernetes deployments.

# Features

## DNS propagation improvements

- adaptive backoff  
- positive streak detection across authoritative DNS servers  
- stabilization window  
- fallback mode for Traefik

## Standalone operation

`dns01` can run alongside certificate brokers such as Lego/Traefik, or operate standalone in custom workflows:

- certificate generation (via certbot)
- creating A/AAAA target records
- hooks for propagation detection

## Reusable components

- lightweight REST client with CLI support  
- portable file-based spooler for cross-container work  

## Docker / K8S deployment

A Dockerfile and image are provided, along with instructions for Traefik/Kubernetes and other uses.

# How to set up and use this code

Please head to the [documentation section](doc/Documentation.md#set-up-and-deployment) for quick installation instructions.

# License

This project is licensed under the **GNU Lesser General Public License v3.0 (LGPL-3.0)**  or any later version, at your option.

All original code in this repository is © 2025 Onestein B.V.

Users are free to use, modify, and redistribute the software under the conditions outlined in the license.

The license applies to all scripts and source files in this repository and to the Docker image built from them.

All source files include SPDX license identifiers for automated license compliance.

Contributions are welcome and will be accepted under the same license terms.

See the [LICENSE](LICENSE) file in the repository root for the full text.