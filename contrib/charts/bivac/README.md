# Helm chart for Bivac

> Backup Interface for Volumes Attached to Containers

## Configuration

The following tables list the configurable parameters of the Bivac chart and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `image.repository` | Repository for the Bivac image. | `ghcr.io/jusito/bivac` |
| `image.tag` | Tag of the Bivac image. | `latest` |
| `image.pullPolicy` | Pull policy for the Bivac image. | `IfNotPresent` |
| `annotations` | Annotations added to the Deployment and manager pod template. | `{ foo: bar }` |
| `labels` | Labels added to the Deployment and manager pod template. | `{}` |
| `orchestrator` | Orchestrator Bivac will run on. | `kubernetes` |
| `watchAllNamespaces` | Let Bivac backup volumes from all namespaces. | `true` |
| `targetURL` | URL where Restic should push the backups. This field is required. | `""` |
| `resticPassword` | Password used by Restic to encrypt the backups. If left empty, a generated one will be used. | `""` |
| `serverPSK` | Pre-shared key that protects the Bivac server. If left empty, a generated one will be used. | `""` |
| `extraEnv` | Additional environment variables. | `[]` |
| `service.type` | Bivac server type. | `ClusterIP` |
| `service.port` | Port to expose Bivac. | `8182` |
| `resources` | Resource limits for Bivac. | `{}` |
| `nodeSelector` | Define which Nodes the Pods are scheduled on. | `{}` |
| `tolerations` | If specified, the pod's tolerations. | `[]` |
| `affinity` | Assign custom affinity rules. | `{}` |

## Environment

The chart exposes the common Bivac settings as values and writes them as manager environment variables:

| Value | Environment variable |
| ----- | -------------------- |
| `orchestrator` | `BIVAC_ORCHESTRATOR` |
| `watchAllNamespaces` | `KUBERNETES_ALL_NAMESPACES` |
| `targetURL` | `BIVAC_TARGET_URL` |
| `resticPassword` | `RESTIC_PASSWORD` |
| `serverPSK` | `BIVAC_SERVER_PSK` |
| `service.port` | Used in the default `BIVAC_LOG_SERVER` service URL. |

Use `extraEnv` for backend credentials and manager variables that are not exposed as chart values, such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `BIVAC_BACKUP_INTERVAL`, `BIVAC_PARALLEL_COUNT`, `KUBERNETES_AGENT_LABELS`, or `BIVAC_PROVIDERS_CONFIG`.

Example:

```yaml
targetURL: s3:my-bucket/bivac
resticPassword: change-me
serverPSK: change-me-too
extraEnv:
  - name: AWS_ACCESS_KEY_ID
    value: your-access-key
  - name: AWS_SECRET_ACCESS_KEY
    value: your-secret-key
  - name: BIVAC_BACKUP_INTERVAL
    value: 23h
```

## Provider Configuration

The chart mounts its provider ConfigMap at `/etc/bivac/providers-config.toml`. The Bivac binary default is `/providers-config.default.toml`, so set this environment variable when you want the manager to use the chart-mounted provider file or a custom file mounted at the same path:

```yaml
extraEnv:
  - name: BIVAC_PROVIDERS_CONFIG
    value: /etc/bivac/providers-config.toml
```

Without that setting, the manager uses the provider configuration baked into the image.
