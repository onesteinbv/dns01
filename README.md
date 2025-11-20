Here you'll find tools to handle DNS01 ACME challenges with a focus on Traefik/Lego, Openprovider and K8S deployments. 

Standalone use is supported, and support for pluggable clients and providers is planned for future releases.

# Features

## DNS propagation improvements

Exhaustive DNS propagation heuristics improving on the Lego timeout-based detection:

- adaptive backoff 
- positive streak detection for authoritative DNS  
- stabilization window  
- fallback mode for Traefik  

## Standalone operation

`dns01` can work alongside certificate brokers such as Lego or independently, enabling custom workflows:

- certificate generation via certbot
- supports on the fly creation of the target DNS records
- plugable hooks for propagation detection requests

## Reusable components
- lightweight REST client with CLI support
- portable file-based **spooler** (`spool.sh`) for cross-container work

## Docker / K8S deployments

A dockerfile is provided along with instructions to use this code with Traefik. Please refer to Documentation.md for full details.