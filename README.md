# Nile Quran Community — Infrastructure

Infrastructure-as-code, GitOps, and cluster manifests for the [Nile Quran Community](https://nile-quran-community.com) platform.

Everything in this repository is declarative: the host is provisioned with Ansible, the cluster is driven by Argo CD, and changes land on `main` through pull requests.

## Architecture

```mermaid
flowchart TB
    users["nile-quran-community.com / argo.nile-quran-community.com"]
    gw[Traefik Gateway] -->|Gateway API| k3s
    users --> gw
    k3s[k3s single node — Hostinger VPS]
    argocd[Argo CD] --> k3s
    k3s --> fe[Frontend / Next.js]
    k3s --> be[Backend / Django]
    be --> db[(SQLite PVC, 20 Gi)]
```

- A single [Hostinger](https://www.hostinger.com/eg) VPS (2 vCPU, 8 GiB RAM) runs a single-node [k3s](https://k3s.io) cluster (`v1.36.2+k3s1`) with Traefik enabled.
- Traffic is routed through the Gateway API: a Traefik `Gateway` named `main` terminates TLS and routes `HTTPRoute`s to the services.
- [cert-manager](https://cert-manager.io) issues Let's Encrypt certificates for different domains.
- [Argo CD](https://argoproj.github.io/cd/) (at `argo.nile-quran-community.com`) is the GitOps engine. It watches this repository and reconciles the cluster.

## Components

| Component              | Description                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| `nile-quran-community` | The website: Next.js frontend + Django backend with a SQLite PVC.           |
| `argocd`               | Argo CD server, root `Application`, RBAC, HTTPRoute.                        |
| `cert-manager`         | Let's Encrypt issuer with Gateway API HTTP-01 solver.                       |
| `sealed-secrets`       | Encrypts Kubernetes secrets so they can live in git.                        |
| `traefik`              | The `main` Gateway and HTTP→HTTPS redirect (Traefik itself ships with k3s). |

The ApplicationSet under `cluster/appset.yml` generates one Argo CD Application per directory in `cluster/apps/*` — each app is deployed into the namespace matching its directory name.

## Repository layout

```
.
├── ansible/                  # Host provisioning (Ansible)
│   ├── 0-setup.yml           # Create admin users + SSH keys
│   ├── 1-k3s.yml             # Bootstrap k3s (k3s-ansible collection)
│   ├── inventory/            # Host inventory, group/host vars, ansible-vault
│   └── requirements.yml      # k3s-ansible collection (v1.2.1)
└── cluster/                  # GitOps (Argo CD)
    ├── appset.yml            # ApplicationSet → one app per cluster/apps/* dir
    └── apps/
        ├── argocd/               # Argo CD + root Application + HTTPRoute
        ├── cert-manager/         # cert-manager + letsencrypt ClusterIssuer
        ├── sealed-secrets/       # Bitnami Sealed Secrets
        ├── traefik/              # main Gateway + HTTP→HTTPS redirect
        └── nile-quran-community/ # Website frontend/backend resources
```

## Domains

| Domain                          | Purpose                               |
| ------------------------------- | ------------------------------------- |
| `nile-quran-community.com`      | Main website (HTTP → HTTPS redirect). |
| `argo.nile-quran-community.com` | Argo CD UI.                           |

## Local development

The toolchain is managed with [mise](https://mise.jdx.dev). Install the tools and pre-commit hooks with:

```sh
mise --locked run install
pre-commit install
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

## Bootstrap a new host

These playbooks were used to build the current VPS and can be re-run against a fresh host:

1. `ansible-playbook 0-setup.yml` — creates the admin users (`ibrahim`, `youssef`) and installs their SSH keys.
2. `ansible-playbook 1-k3s.yml` — bootstraps k3s via the `k3s.orchestration` collection (`k3s-ansible`), including Traefik.
3. Install Argo CD into the cluster (`cluster/apps/argocd`), which then takes over as the GitOps engine and reconciles everything else from `main`.

## Security notes

- Kubernetes secrets are committed as [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) (`kubeseal`) and can only be decrypted by the controller in the cluster.
