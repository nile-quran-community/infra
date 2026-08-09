## Overview

This repository manages the infrastructure and GitOps deployment for the Nile Quran Community platform. The live site is at `nile-quran-community.com` and the Argo CD dashboard is at `argo.nile-quran-community.com`.

## Architecture

- **Host**: Single Hostinger VPS (`srv1871728.hstgr.cloud`) with 2 vCPU / 8 GiB RAM.
- **Cluster**: Single-node k3s (`v1.36.2+k3s1`) with Traefik enabled.
- **Ingress**: Gateway API via a Traefik `Gateway` named `main` in the `traefik` namespace.
  - Listener `http` on port 80 (redirects to HTTPS).
  - Listener `https` on port 443 for `nile-quran-community.com`.
  - Listener `https-argocd` on port 443 for `argo.nile-quran-community.com` (restricted to the `argocd` namespace via label selector).
- **TLS**: cert-manager with Let's Encrypt ACME HTTP-01 solver via the Gateway.
  - ClusterIssuer: `letsencrypt`, email `nuqurancommunity@outlook.com`.
  - Certificate secrets: `nile-quran-community-cert` and `argo-nile-quran-community-cert`.
- **GitOps**: Argo CD auto-syncs the `main` branch with `prune: true` and `selfHeal: true`.
  - Root Application at `cluster/apps/argocd/custom-resources/applications/root.yml` watches `cluster/appset.yml`.
  - ApplicationSet at `cluster/appset.yml` generates one Application per directory in `cluster/apps/*`.
- **Apps deployed**:
  - `argocd` — Argo CD itself (Helm chart + root Application + HTTPRoute).
  - `cert-manager` — cert-manager Helm chart + `letsencrypt` ClusterIssuer.
  - `sealed-secrets` — Bitnami Sealed Secrets Helm chart.
  - `traefik` — `main` Gateway + HTTP→HTTPS redirect (Traefik ships with k3s; this app only manages Gateway API resources).
  - `nile-quran-community` — Next.js frontend + Django backend with SQLite PVC.
- **Secrets**: Kubernetes secrets are `SealedSecret`s (Bitnami). Ansible secrets are `ansible-vault` encrypted. Never commit plaintext secrets.

## Dev environment setup

- All tools are pinned in `mise.toml` and installed via `mise`. Never assume a global install.
- Run `mise run --locked i` to install all tools and pre-commit hooks.
  - Installs: `opentofu`, `ansible-core`, `kubectl`, `helm`, `argocd`, `kubeseal`, `tflint`, `prek`.
- `mise.local.toml` and `ansible/.vaultpass` are gitignored. Do not commit them.
- The pre-commit manager is `prek`, not the Python `pre-commit` package.

## Repo structure and conventions

```
.
├── ansible/                  # Host provisioning
│   ├── 0-setup.yml           # Admin users + SSH keys
│   ├── 1-k3s.yml             # Imports k3s.orchestration.site playbook
│   ├── inventory/
│   │   ├── main.yml                      # Host: k3s-server
│   │   ├── group_vars/k3s_cluster.yml    # k3s_version: v1.36.2+k3s1
│   │   └── host_vars/k3s-server/
│   │       └── vault.yml                 # ansible-vault encrypted
│   └── requirements.yml                  # k3s-ansible collection v1.2.1
│
└── cluster/                  # GitOps manifests
    ├── appset.yml            # ApplicationSet: one app per cluster/apps/*
    └── apps/
        ├── argocd/
        ├── cert-manager/
        ├── sealed-secrets/
        ├── traefik/
        └── nile-quran-community/
```

### Adding a new cluster app

Each app lives in `cluster/apps/<app>/` with this structure:

```text
cluster/apps/<app>/
├── kustomization.yaml      # Helm chart (optional) + custom resources list
├── values.yml              # Helm values (optional)
└── custom-resources/       # Plain manifests (deployments, services, httproutes, ...)
```

The ApplicationSet auto-discovers the directory and creates an Argo CD Application.
By default the app deploys into a namespace matching the directory name.
The `nile-quran-community` app is an exception: its `kustomization.yaml` explicitly sets `namespace: default`.

### Image versioning

Frontend and backend Deployments reference `:latest` in their manifest `image` fields.
The actual pinned tags are set via the `images:` section in the app's `kustomization.yaml`.
When bumping a version, edit the `newTag` in `cluster/apps/nile-quran-community/kustomization.yaml`, not the Deployment manifest.

### Ingress (Gateway API)

Do not use classic `Ingress` resources. Attach services to the Traefik `Gateway` `main` in the `traefik` namespace via `HTTPRoute`s. Set `parentRefs` to the Gateway and include a `sectionName` matching the listener (`https` or `https-argocd`).

## Testing and validation

- There are no unit tests. Correctness is verified by rendering manifests, passing pre-commit, and observing Argo CD sync after merge.
- Run `prek run --all-files` to run every check (terraform fmt/validate/tflint, tombi format/lint, oxfmt).
- Render an app's manifests:

```sh
kubectl kustomize cluster/apps/<app>
kubectl apply --dry-run=client -k cluster/apps/<app>
```

- After editing Ansible, remember the inventory is `ansible/inventory/main.yml`.

## Ansible workflow

- `0-setup.yml`: creates admin users and installs SSH authorized keys.
- `1-k3s.yml`: imports `k3s.orchestration.site` from the k3s-ansible collection (v1.2.1).
- Install collection dependencies:

```sh
ansible-galaxy collection install -r ansible/requirements.yml
```

- The k3s version is pinned in `ansible/inventory/group_vars/k3s_cluster.yml`.

## Secrets handling

- **Kubernetes**: Create a `Secret`, encrypt it with `kubeseal`, and commit the resulting `SealedSecret`.

```sh
kubectl create secret generic <name> \
  --from-literal KEY=value --dry-run=client -o yaml \
  | kubeseal --format yaml -w custom-resources/.../sealed-secret.yml
```

- **Ansible**: Use `ansible-vault encrypt` for host/group vars. The vault password file (`ansible/.vaultpass`) is gitignored.
- Never commit `mise.local.toml` or any plaintext credential files.

## Git workflow

- **Remote**: Named `github` (points to `git@github.com:NU-Quran-Community/infra.git`).
- **Branch**: `main` is the only branch that Argo CD watches. All changes must go through PRs.
- **Commits**: Follow [Conventional Commits](https://www.conventionalcommits.org/) with scopes:
  - `cluster/nqc`, `cluster/traefik`, `cluster/argocd`, `cluster/cert-manager`, `cluster/apps`
  - `ansible`
  - Breaking changes use `!` (e.g., `refactor(cluster/apps)!: use new org name`)
- **PR process**:
  1. Make focused changes in one area.
  2. Run `prek run --all-files`.
  3. Render affected manifests with `kubectl kustomize`.
  4. Open a PR against `main`.
  5. After merge, verify sync in Argo CD (`argocd app list`).

## Common gotchas

- Do not modify `.ansible/collections` (gitignored, managed by `ansible-galaxy`).
- The ApplicationSet's `templatePatch` supports per-app `config.yml` overrides (`autoSync`, `ignoreDifferences`), but no app currently uses them.
- `CreateNamespace=true` in Argo CD creates namespaces automatically; for `nile-quran-community` the namespace is `default` due to the kustomization override.
- The Argo CD server runs with `--insecure` (TLS is terminated at the Gateway, not at Argo CD itself).
