## Important

This fork focuses on keeping Restic and the Docker image up to date. The Go code is only touched when required for dependencies or maintenance, and pull requests are welcome.

## Bivac

Bivac is a Backup Interface for Volumes Attached to Containers. It backs up Docker, Kubernetes, and legacy Cattle/Rancher volumes with Restic.

Website: [https://camptocamp.github.io/bivac](https://camptocamp.github.io/bivac)

![Bivac](img/bivac_small.png)

## Getting Started

Bivac runs a manager process that watches volumes and exposes an API. When a backup or restore runs, the manager starts a temporary agent container or Kubernetes pod that runs Restic against the selected volume.

You need three values before starting:

| Name | Required | Description |
| ---- | -------- | ----------- |
| `BIVAC_TARGET_URL` | yes | Restic repository target prefix, for example `s3:my-bucket/bivac` or `/backup`. |
| `RESTIC_PASSWORD` | yes | Password used by Restic to encrypt the repository. Keep it safe; backups cannot be restored without it. |
| `BIVAC_SERVER_PSK` | recommended | Pre-shared key for the manager API and CLI commands. |

### Docker Compose with S3

Create a Compose file like this:

```yaml
services:
  bivac:
    image: ghcr.io/jusito/bivac:latest
    command: manager
    ports:
      - "8182:8182"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      BIVAC_ORCHESTRATOR: docker
      BIVAC_TARGET_URL: s3:my-bucket/bivac
      RESTIC_PASSWORD: change-me
      BIVAC_SERVER_PSK: change-me-too
      AWS_ACCESS_KEY_ID: your-access-key
      AWS_SECRET_ACCESS_KEY: your-secret-key
```

Then start it:

```sh
docker compose up -d
```

For a fuller commented Docker Compose reference, see [contrib/examples/docker-compose/docker-compose.full.yml](contrib/examples/docker-compose/docker-compose.full.yml). Monitoring examples with Prometheus and Grafana remain in [contrib/examples/docker-compose/docker-compose.yml](contrib/examples/docker-compose/docker-compose.yml).

### Docker Compose with a Local Repository

Restic local targets work when the target directory is mounted into the Bivac manager. Docker agents inherit the manager container mounts, so the same `/backup` path is available when the temporary agent runs.

```yaml
services:
  bivac:
    image: ghcr.io/jusito/bivac:latest
    command: manager
    ports:
      - "8182:8182"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./backups:/backup
    environment:
      BIVAC_ORCHESTRATOR: docker
      BIVAC_TARGET_URL: /backup
      RESTIC_PASSWORD: change-me
      BIVAC_SERVER_PSK: change-me-too
```

### Helm

Set the required chart values and any backend credentials:

```sh
helm install bivac ./contrib/charts/bivac \
  --set targetURL=s3:my-bucket/bivac \
  --set resticPassword=change-me \
  --set serverPSK=change-me-too \
  --set extraEnv[0].name=AWS_ACCESS_KEY_ID \
  --set extraEnv[0].value=your-access-key \
  --set extraEnv[1].name=AWS_SECRET_ACCESS_KEY \
  --set extraEnv[1].value=your-secret-key
```

The chart sets `BIVAC_ORCHESTRATOR=kubernetes` and `KUBERNETES_ALL_NAMESPACES=true` by default. See [contrib/charts/bivac/README.md](contrib/charts/bivac/README.md) for chart values and the `extraEnv` format.

## Backup and Restore

List volumes through the manager API:

```sh
bivac volumes --remote.address http://127.0.0.1:8182 --server.psk change-me-too
```

Run a backup by volume ID:

```sh
bivac backup <volume-id> --remote.address http://127.0.0.1:8182 --server.psk change-me-too
```

Restore the latest snapshot:

```sh
bivac restore <volume-id> --snapshot latest --remote.address http://127.0.0.1:8182 --server.psk change-me-too
```

`--force` is available on `backup` and `restore`. It passes `--force` to the agent, which removes Restic locks before running the operation. Use it only when you are sure no other Restic process is using the repository.

`BIVAC_REMOTE_ADDRESS` and `BIVAC_SERVER_PSK` can also provide the CLI defaults, so repeated commands can be shorter:

```sh
export BIVAC_REMOTE_ADDRESS=http://127.0.0.1:8182
export BIVAC_SERVER_PSK=change-me-too
bivac volumes
```

## How Backups Work

Bivac does not normally stop application containers. For provider-aware backups, it detects a provider by running `detect_cmd` inside containers or pods that mount the volume. It then runs `pre_cmd` before Restic and `post_cmd` after Restic in one of those existing containers or pods.

The actual Restic operation runs in a temporary agent container or Kubernetes pod. The manager passes its environment to the agent, including Restic backend credentials such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and other provider-specific variables supported by Restic or rclone.

For databases, the default provider configuration creates dump files in the volume before backup and removes them afterward. If your application needs quiescing, define suitable `pre_cmd`, `post_cmd`, `restore_pre_cmd`, or `restore_post_cmd` commands.

## Volume Selection

Bivac skips some volumes automatically:

| Rule | Applies to | Description |
| ---- | ---------- | ----------- |
| `bivac.ignore=true` | Docker volumes, Kubernetes PVCs | Excludes the volume or PVC. |
| 64-character volume names | Docker, Kubernetes | Treats unnamed generated volumes as unmanaged. |
| Empty names | Kubernetes | Skipped as unnamed. |
| Names containing `/` | Kubernetes | Skipped as path-like names. |
| `lost+found` | Docker and manager filtering | Skipped. |

You can also filter by name:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `BIVAC_WHITELIST` | empty | Comma-separated volume names to include. When set, only these names are backed up. |
| `BIVAC_VOLUMES_WHITELIST` | empty | Alias for `BIVAC_WHITELIST`. |
| `BIVAC_BLACKLIST` | empty | Comma-separated volume names to exclude. |
| `BIVAC_VOLUMES_BLACKLIST` | empty | Alias for `BIVAC_BLACKLIST`. |

Whitelist takes precedence over blacklist. If a whitelist is configured, every non-whitelisted volume is excluded before blacklist rules matter.

For Kubernetes, the PVC annotation `bivac.backup=false` excludes a claim. With `BIVAC_WHITELIST_ANNOTATION=true`, a PVC that has the `bivac.backup` annotation must set it to `true`; in the current code, PVCs without that annotation are still considered for backup.

## Provider Configuration

The default provider file is [providers-config.default.toml](providers-config.default.toml). It defines database-aware backups for MySQL, PostgreSQL, OpenLDAP, and MongoDB.

Each provider supports these TOML keys:

| Key | Description |
| --- | ----------- |
| `detect_cmd` | Shell command run in containers or pods mounting the volume. If it succeeds, this provider is selected. `$volume` is replaced with the mount path inside that container or pod. |
| `pre_cmd` | Optional shell command run before Restic backup. Commonly creates a dump in the volume. |
| `post_cmd` | Optional shell command run after Restic backup. Commonly removes temporary dump files. |
| `backup_dir` | Subdirectory inside the mounted volume that Restic backs up. |
| `restore_pre_cmd` | Optional shell command run before Restic restore. |
| `restore_post_cmd` | Optional shell command run after Restic restore. |

Use `BIVAC_PROVIDERS_CONFIG` to point the manager at a custom file. The binary default is `/providers-config.default.toml`.

## Environment Variables

### Core

| Name | Default | Description |
| ---- | ------- | ----------- |
| `BIVAC_ORCHESTRATOR` | empty | Orchestrator to use, usually `docker`, `kubernetes`, or legacy `cattle`. |
| `BIVAC_TARGET_URL` | empty | Restic repository target prefix. Required for useful backups. |
| `RESTIC_PASSWORD` | empty | Restic repository encryption password. Read by Restic in the agent. |
| `BIVAC_SERVER_PSK` | empty | Pre-shared key for the manager API and CLI. |
| `BIVAC_SERVER_ADDRESS` | `0.0.0.0:8182` | Address the manager API binds to. |
| `BIVAC_REMOTE_ADDRESS` | `http://127.0.0.1:8182` | Default manager URL for CLI commands. |
| `BIVAC_VERBOSE` | `false` | Enables verbose CLI output. |

### Docker

| Name | Default | Description |
| ---- | ------- | ----------- |
| `BIVAC_DOCKER_ENDPOINT` | `unix:///var/run/docker.sock` | Docker API endpoint used by the manager. |
| `BIVAC_DOCKER_NETWORK` | `bridge` | Docker network used for temporary agent containers. |

### Kubernetes

| Name | Default | Description |
| ---- | ------- | ----------- |
| `KUBERNETES_NAMESPACE` | empty | Namespace where Bivac runs or watches when not watching all namespaces. |
| `KUBERNETES_ALL_NAMESPACES` | `false` in the binary, `true` in the Helm chart | Watch PVCs across all namespaces. |
| `KUBERNETES_KUBECONFIG` | empty | Path to kubeconfig when running outside a cluster. |
| `KUBERNETES_AGENT_SERVICE_ACCOUNT` | empty | Service account for temporary agent pods. |
| `KUBERNETES_AGENT_LABELS` | `app=bivac` | Comma-separated labels added to agent pods. |
| `KUBERNETES_AGENT_ANNOTATIONS` | empty | Comma-separated annotations added to agent pods. |

### Backup Behavior

| Name | Default | Description |
| ---- | ------- | ----------- |
| `BIVAC_RETRY_COUNT` | `0` | Retry count when Bivac itself fails to back up a volume. |
| `BIVAC_PARALLEL_COUNT` | `2` | Number of agents that can run in parallel. |
| `BIVAC_REFRESH_RATE` | `10m` | Volume list refresh interval. |
| `BIVAC_BACKUP_INTERVAL` | `23h` | Minimum interval between automatic backups of one volume. |
| `RESTIC_FORGET_ARGS` | `--group-by host --keep-daily 15 --prune` | Arguments used for Restic forget/prune. |
| `BIVAC_LOG_SERVER` | empty | Manager URL agents use to send logs back. Helm sets this to the in-cluster service URL. |
| `BIVAC_AGENT_IMAGE` | computed from manager version | Agent image for temporary Docker containers or Kubernetes pods. |
| `BIVAC_PROVIDERS_CONFIG` | `/providers-config.default.toml` | Provider TOML configuration path. |

### Volume Filters

| Name | Default | Description |
| ---- | ------- | ----------- |
| `BIVAC_WHITELIST` | empty | Comma-separated names to include. |
| `BIVAC_VOLUMES_WHITELIST` | empty | Alias for `BIVAC_WHITELIST`. |
| `BIVAC_BLACKLIST` | empty | Comma-separated names to exclude. |
| `BIVAC_VOLUMES_BLACKLIST` | empty | Alias for `BIVAC_BLACKLIST`. |
| `BIVAC_WHITELIST_ANNOTATION` | `false` | Kubernetes-only behavior for the `bivac.backup` PVC annotation. |

### Backend Credentials

From this point on, variables are Restic or backend-specific environment variables. Bivac does not interpret them; it passes the manager process environment to the temporary agent with `os.Environ()`, so variables required by Restic or rclone backends are available to the agent.

See the Restic repository/backend documentation for the variables and URL formats supported by each backend: [Preparing a new repository](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html).

For S3 this commonly includes `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, or endpoint-specific variables.

## More Documentation

The original project wiki remains useful for background details:

* [Overview](https://github.com/camptocamp/bivac/wiki/Home)
* [Installation](https://github.com/camptocamp/bivac/wiki/Installation)
* [Usage](https://github.com/camptocamp/bivac/wiki/Usage)
* [API](https://github.com/camptocamp/bivac/wiki/API)
