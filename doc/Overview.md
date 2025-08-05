Support for github actions, gitlab hooks, terraform or any other platform should be easy to implement by users with this base

# Components

## `rest`
a bash script to interact with REST backends from the command line and scripts, intended for CLI or scripting

- requirements: `jq` and `curl`
- authentication credentials from the environment or stdin input
- can set the authentication token variable and detect token expiration (TODO)
- pluggable backend configurations

## `dns01`
a bash script to automate DNS01 ACME challenges with DNS servers (initially only openprovider support)

- requirements: `rest` script, `certbot` if using certbot generation
- `certbot` modes: 
  * one-shot: returns certificate and key, stops
  * long-lived: automated renewal with `certbot` cronjobs in a docker image
- optional HTTP listener supporting two payload formats: cert-manager and traefik
- supports wildcard domains
- optional creation of combo certificates with `--combo` (apex+wildcard)
- optional creation of A/AAAA records (with `--create` and `--address`)
- challenge-only modes (always one-shot, cert lifecycle managed by clients)

## k8s apps (helm/ArgoCD)
- traefik "manual" provider
- traefik "httpreq" provider
- Argo Event wrapper (same-ish functionality as the optional HTTP listener, actually it could also talk to it)
- Argo Workflow with support for certbot modes
- daemonset (synchronized cron jobs?)


# TODO
### phase 1 - finish production core

#### done
- ~~`--combo` takes a lot of time (due to openprovider flapping)~~
- ~~incorrect path for cert/key at the end of `dns01/go()`~~
- ~~Failure modes~~
 - ~~`rest` no credentials: try from env, otherwise TTY? ask, otherwise fail~~
 - ~~`rest` test for expired token~~
 - ~~detect/ignore stale DNS entries from dig by comparing with what's in the openprovider API~~ 
 - ~~Idempotent cleanup + timeout handling~~
 - ~~log -> msg~~
 - ~~err: use log, arrays err and hint, show message, return with code / exit~~
- ~~make wait_propagation fully use `conf[]
- ~~Traefik "exec" provider compatibility (minus raw mode)~~
- write Dockerfile & minimal entrypoint for certbot modes~~
- ~~spool mode~~
 - ~~entrypoint: initialize spool directory, loop forever (read spool, dispatch dns01, write exit status)~~
 - ~~synchronous spool dispatcher: write id + request + params, wait for id + response, return~~
 - ~~push docker image~~
 - ~~traefik chart plumbing

#### priority bucket 1 - initial deliverable
- write initial documentation
- add versioning
- publish image and chart

#### priority bucket 2 - spooler + traefik k8s deployment
- optimize spooler
- send env/extra config from traefik to spool mode
- allow disabling all propagation checks

- Traefik Helm chart integration
 - document
 - revise values that shouldn't be in the main values.yaml, params from CD

#### priority bucket 3 - easy improvements + testing
- improve HTTP error messages (preparse at enc or helper in common)
- sanitize logs, redact any sensitive information such as authorization headers
- configurable / default TTLs
- complete unit tests

#### priority bucket 4 - other improvements + refactor for phase 2
- make `dns01` cache credentials if it has to ask (also check interaction with full certbot mode and other modes)
- macro templates + function for record boilerplate
- configuration support (integrate curq.sh and bart for parser + overriding sources, begin minimal bashlib)
- add controls for **time** threshold scale penalization
- rest of bashlib integration: fq, cleanup, iomodes

### phase 2 - finish kubernetes plumbing
- Helm chart, ArgoCD app
- CI/CD
- create canonical certbot dirs if they don't exist (for cronjobs etc)
- add long-lived certbot mode (cronjob)
* add lightweight HTTP listener, support traefik's "httpreq" POST only initially
* connect listener to spool, certbot, certbot-long modes
- Argo Event+Workflow supporting all modes
- rdepo meta: licence, packaging, deps, compatibility notes, full doc

### phase 3 - extensions and integrations
- cert‑manager webhook
- GitHub Action wrapper
- Terraform provider using the same REST DSL

- pluggable REST services in the rest script (using $conf exports or a layered input like in the Bart script - this is going to be integrated in bashlib)
- pluggable DNS services in the dns01 script (using $conf exports or a layered input like in the Bart script - this is going to be integrated in bashlib)
- pluggable/chainable propagation strategies
- support lego RAW mode

- retool `rest` as a lightweight shim on top of httpie
- add static binaries for "real" traefik exec support