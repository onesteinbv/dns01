## Overview

This repository includes tooling to handle DNS01 ACME challenges with a focus on Traefik/Lego support and Openprovider. Support for other clients and providers should be easy to add on top of the current code. 

Some components that can be used independently include a generic CLI utility for REST interfaces similar to httpie.

## Components

## `rest`
a bash script to interact with REST backends from the command line and scripts, intended for CLI or scripting

- requirements: `jq` and `curl`
- authentication credentials from the environment or stdin input

## `dns01`
a bash script to automate DNS01 ACME challenges (initially only openprovider support)

- requirements: `rest` script, `certbot` if using certbot generation
- `certbot` modes: 
  * one-shot: returns certificate and key, stops
  * long-lived: automated renewal with `certbot` cronjobs in a docker image
- extensive compatibility with Traefik/lego
- **TODO** optional HTTP listener supporting cert-manager and traefik APIs
- supports wildcard domains
- optional creation of combo certificates with `--combo` (apex+wildcard)
- optional creation of A/AAAA records (with `--create` and `--address`)
- challenge-only modes (always one-shot, certificate lifecycle managed by clients)

## `spool.sh`

a spool based asynchronous interface for processing ACME registrations 

## `entrypoint.sh`

the entry point script to control operating mode in docker images



## Installation

### Standalone use

The requirements for using the scripts directly are listed in the section **Components**. Add the `dns01` subdirectory of this repo to `PATH` or call the scripts there directly, the code can locate other components by determining its location on each call.

### Docker image

The docker image uses entrypoint.sh to control the operation mode. The mode is selected with the `DNS01_MODE` environment variable. Refer to **Configuration** for a description of all the behaviors controlled via environment variables.

### Traefik plugin

These are instructions intended for Traefik installations using the official Helm chart. The script must be used for now as a Traefik `exec` plugin, until a long-lived listener added which will enable using the `httpreq` plugin. 

#### Set up the spool directory

Add a new volume under `.Values.deployment.additionalVolumes`:

```yaml
additionalVolumes:
 - name: acme-scripts
   mountPath: /acme-scripts
   readOnly: false 
```

Mount the volume on the Traefik container:

```yaml
additionalVolumeMounts:
  - name: acme-scripts
    mountPath: /acme-scripts
    readOnly: false
```

Ensure ownership and permissions for the Traefik process on the volume (example using an init container on `.Values.deployment.initContainers`):

```yaml
initContainers:
  # The "volume-permissions" init container is required if you run into permission issues.
  # Related issue: https://github.com/traefik/traefik-helm-chart/issues/396
  - name: volume-permissions
    image: busybox:latest
    command:
      - sh
      - -c
      - |
        echo "Setting up /acme-scripts..."
        mkdir -p /acme-scripts/spool
        chown -R 65532:65532 /acme-scripts
        chmod -R 700 /acme-scripts
    securityContext:
      runAsNonRoot: false
      runAsUser: 0
      runAsGroup: 0
    volumeMounts:
      - name: acme-scripts
        mountPath: /acme-scripts
```

#### Add the docker image as an additional container 

Add a new entry under `.Values.deployment.additionalContainers`:

```yaml
additionalContainers:
  - name: dns01
    image: ghcr.io/3coma3/dns01:latest
    imagePullPolicy: Always
    volumeMounts:
      - name: acme-scripts
        mountPath: /acme-scripts
        readOnly: false
    env:
    - name: REST_USERNAME
      valueFrom:
        secretKeyRef:
          name: traefik
          key: openprovider_username
    - name: REST_PASSWORD
      valueFrom:
        secretKeyRef:
          name: traefik
          key: openprovider_password
    - name: DNS01_MODE
      value: spool
    - name: DNS01_SPOOL
      value: /acme-scripts
    - name: DNS01_NATIVE
      value: "true" 
```

#### Set up the spool mechanism as a Trafik exec plugin

```yaml
env:
  - name: EXEC_PATH
    value: /acme-scripts/spool.sh
    
certificatesResolvers:
  dns01:
    acme:
      email: acme-challenge@onestein.nl
      storage: /data/acme.json
      tlsChallenge: false
      httpChallenge: false
      dnsChallenge:
        provider: exec
        disablePropagationCheck: true
```



## Configuration

### Internal configuration

### Environment variables

|         Variable         |             Controls             |      `conf[]` entry      |                            Values                            |
| :----------------------: | :------------------------------: | :----------------------: | :----------------------------------------------------------: |
|      `DNS01_STREAK`      |     Adaptive streak tracking     |      `dns01_streak`      |                      `true` or `false`                       |
| `DNS01_STREAK_THRESHOLD` |     Adaptive streak tracking     | `dns01_streak_threshold` | `<integer value>`: set `conf[]` value<br>`<any other value>`: use `conf[]` value |
|  `DNS01_STREAK_PENALTY`  |     Adaptive streak tracking     | `dns01_streak__penalty`  | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|    `DNS01_STREAK_MOD`    |     Adaptive streak tracking     |    `dns01_streak_mod`    | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|     `DNS01_TIMEOUT`      |  Propagation detection timeout   |     `dns01_timeout`      | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|     `DNS01_BACKOFF`      | Adaptive backoff - initial value |     `dns01_backoff`      | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|   `DNS01_BACKOFF_MIN`    |  Adaptive backoff - lower bound  |   `dns01_backoff_min`    | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|   `DNS01_BACKOFF_MAX`    |  Adaptive backoff - upper bound  |   `dns01_backoff_max`    | `<integer value>`: set `conf[]` value<br/>`<any other value>`: use `conf[]` value |
|      `DNS01_NATIVE`      |   Native propagation detection   |      `dns01_native`      | `true`: fully disable lego semantics<br>`false`: fully enable lego semantics (can't be overriden)<br>`fallback`: try `false` behavior first otherwise `true` behavior<br/>(`DNS_*` variables can override)<br>`<any other value>`: enable lego semantics<br/>(`DNS_*` variables can override) |

### Command line switches



## Propagation detection

### Adaptive propagation detection
DNS data planes can return flaky results (e.g. from anycast clusters with unpredictable zone updates), so we can't trust a single successful test, even with all authoritative servers having answered correctly.

If we greenlight the challenge propagation only to have LetsEncrypt fail in the face of a flapped NXDOMAIN or stale record, we're in no better position as having had no propagation checks at all.

Thus, the detection logic in the `wait_propagation` function actively tries to detect these worst cases, working with inconsistent data planes to minimize the chance of false positives.

Upon a successful response by all authoritative servers, the process enters a **stabilization phase** where it searchs for *sustained streaks* of success until a stable time threshold is reached. The longer it takes reaching a stabilization phase, the less the data plane is trusted, and the function "penalizes" it with higher time threshold values.

Streak lengths must also meet their own threshold: each time a stabilization phase *breaks* by a failed test, the next one might have to sustain a longer success streak. How often this penalization occurs is controlled via `conf[streak_penalty_mod]`.

There is a bounded backoff time that slows down on falling trends and speeds up as we tend to better results.

Ultimately, success depends on either:
1) both time and streak thresholds being met, or
2) the time threshold being surpassed by 200%

Timing out before 1) or 2) becomes a failure. This might be configurable later, but for now a strict policy is the best defense line against false positives.

### Performance and reliability
`dns01` is designed to handle DNS data planes that exhibit delayed or inconsistent propagation, but it cannot speed up the underlying DNS provider.

In environments such as OpenProvider, propagation delays and record flapping can occur when multiple TXT records for the same `_acme-challenge` name are created close together, whether from:

- Using the `--combo` option (multiple names in one certificate request)
- Multiple concurrent or closely timed DNS-01 challenges for the same domain from different certificate requests

This is a property of the provider’s backend DNS servers that `dns01` can't avoid. The script’s propagation checker (`wait_propagation`) is designed to maximize the chance of success in poor conditions, but it may extend validation times significantly (10-20 minutes per record in extreme cases).

Possible mitigation routes for faster resolution:
- Avoid `--combo` for automation
- Avoid concurrent or near-concurrent certificate requests for the same domain  
- Use `conf[dns01_timeout]` and related configuration controls to set acceptable timeouts and backoff/streak behavior for your environment

### Traefik/lego propagation detection
In Traefik mode, the [lego library "exec" provider](https://go-acme.github.io/lego/dns/exec/) sets two environment variables with default values, or configuration from Traefik:

- `EXEC_POLLING_INTERVAL` - Time between DNS propagation check in seconds (Default: 3)
- `EXEC_PROPAGATION_TIMEOUT` - Maximum waiting time for DNS propagation in seconds (Default: 60)

These variables conform to a simpler propagation logic than that of `wait_propagation`. It uses fixed timeout and polling interval, with the first positive challenge resolution considered successful propagation.

The lego variables map to native configuration like this:

|   Traefik/Lego variable    |                        `conf[]` entry                        |                            Notes                             |
| :------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
| `EXEC_PROPAGATION_TIMEOUT` |                       `dns01_timeout`                        |                         1:1 mapping                          |
|  `EXEC_POLLING_INTERVAL`   | `dns01_backoff`<br>`dns01_backoff_min`<br>`dns01_backoff_max` | The `backoff` variable in `wait_propagation` moves in the range, or can be set to a fixed interval |
|             -              | `dns01_streak_threshold`<br>`dns01_streak_penalty`<br>`dns01_streak_mod`<br>`dns01_streak` | Dynamic time/length based streak tracking have no equivalent in Traefik. To follow its semantics `dns01_streak` should be set to `false`. |

When called by Traefik, `dns01` strictly follows the lego model:

- `dns01_timeout` is set to `EXEC_PROPAGATION_TIMEOUT`
- `dns01_backoff`, `dns01_backoff_min` and `dns01_backoff_max` are fixed to `EXEC_POLLING_INTERVAL`
- adaptive streak tracking is disabled

The environment variables `DNS01_STREAK`, `DNS01_TIMEOUT`, `DNS01_BACKOFF_MIN` and `DNS01_BACKOFF_MAX`, when set, allow overriding the lego configuration and propagation semantics with their own as described in [Configuration](#configuration).

Additionally, the variable `DNS01_NATIVE` provides a shortcut to fully use lego or native mode:

- When undefined or set to another value than `true` or `false`, the above rules apply
- When set to `true`, drop lego compatibility and use the native propagation detection, honoring any `DNS01_*` variables
- When set to `false`, ignore all `DNS01_*` variables, force strict mapping and full lego propagation detection
- When set to `fallback`, attempt first the behaviors as if `false` were specified, and if that fails, behave as if `true` was specified

**Note:** when using the lego detection but allowing backoff scaling, the scaling can only be **positive** (ie increased each time we poll negatively for propagation). There won't ever be a negative scaling, as the lego algorithm totally succeeds on the first positive reply.
