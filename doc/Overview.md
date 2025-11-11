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
- ~~failure modes~~
 - ~~`rest` no credentials: try from env, otherwise TTY? ask, otherwise fail~~
 - ~~`rest` test for expired token~~
 - ~~detect/ignore stale DNS entries from dig by comparing with what's in the openprovider API~~ 
 - ~~Idempotent cleanup + timeout handling~~
 - ~~log -> msg~~
 - ~~err: use log, arrays err and hint, show message, return with code / exit~~
- ~~make wait_propagation fully use `conf[]
- ~~Traefik "exec" provider compatibility (minus raw mode) via spooler~~
- ~~write Dockerfile & minimal entrypoint for certbot modes~~
- ~~spool mode~~
 - ~~entrypoint: initialize spool directory, loop forever (read spool, dispatch dns01, write exit status)~~
 - ~~synchronous spool dispatcher: write id + request + params, wait for id + response, return~~
- ~~push docker image~~
- ~~traefik chart plumbing
- ~~optimize spooler~~

#### priority bucket 1 - initial deliverable
- write initial documentation
- add versioning

- Traefik Helm chart integration
 - document
 - revise values.yaml for hardcoded values

#### priority bucket 2 - improvements + refactor for phase 2
- sanitize logs, redact any sensitive information such as authorization headers
- send relevant env/extra config from traefik via spool
- spooler: handle cleanup, confirmations, better info on send_job, extend failure modes

- improve HTTP error and status messages (preparse at enc or helper in common)
- macro templates + function for record boilerplate
- configurable / default TTLs
- add controls for **time** threshold scale penalization besides streak length
- make `dns01` cache credentials if it has to ask (also check interaction with full certbot mode and other modes)
- allow disabling all propagation checks (or better, be able to choose what functionality: only propagation checks, only record management, etc)

- config support (bart style + curq.sh for parser + overriding sources, begin minimal bashlib)
- rest of bashlib integration: fq, cleanup, iomodes
- complete unit tests

### phase 2 - finish kubernetes plumbing
- Helm chart, ArgoCD app
- CI/CD

- add certbot-long mode with auto rotation
- create canonical certbot dirs if they don't exist (for cronjobs etc)

* add listen mode, support only Traefik's "httpreq" initially
* connect listener to certbot/certbot-long modes

- Argo Event+Workflow supporting all modes
- repo meta: licence, packaging, deps, compatibility notes, full doc

### phase 3 - extensions and integrations
- cert‑manager webhook
- Github Action support
- Terraform provider

- pluggable REST services in `rest`
- pluggable DNS services in `dns01`
- pluggable/chainable propagation strategies

- support lego RAW mode
- retool `rest` as a lightweight shim on top of httpie
- add static binaries for "real" traefik `exec` support