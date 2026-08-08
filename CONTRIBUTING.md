# Contributing to the Infrastructure Repo

Thanks for contributing to the Nile Quran Community infrastructure. This is a **private, team-only** repository; changes land on `main` through pull requests, and Argo CD automatically rolls them out to the cluster.

## Development setup

Tools are pinned and installed with [mise](https://mise.jdx.dev):

```sh
mise run --locked install
```

If you add tools, update `mise.toml`.

Pre-commit hooks format and lint changed files automatically:

```sh
prek run --all-files
```

## Before you start

- The cluster only trusts `main`. Test your manifests locally first.
- Never commit secrets. Use Sealed Secrets for Kubernetes and `ansible-vault` for Ansible. `mise.local.toml` and `ansible/.vaultpass` are gitignored — keep it that way.
- `kubectl` against the production cluster is a direct change of a live system. Prefer `kubectl kustomize` / `kubectl apply --dry-run=client -k` for verification.

## Branching and commits

- Open a topic branch, push it, and open a pull request against `main`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  - `feat(cluster/nuqc): bump backend image to 1.1.0`
  - `fix(cluster/traefik): allow routes from all namespaces`
  - `refactor(cluster/apps)!: use new org name`

## Pull request workflow

1. Make focused changes in one area per PR.
2. Verify locally: `prek run --all-files` and render manifests with `kubectl kustomize cluster/apps/<app>`.
3. Push your branch and open a PR against `main` with a short description of the intended change.
4. Request a review from another maintainer. Once merged, Argo CD syncs the change automatically (prune + self-heal are enabled).
5. After a deploy, check `argocd app list` and the app status to confirm the sync succeeded.

## Adding a new application

Each app lives in its own directory and namespace:

```text
cluster/apps/<app>/
├── kustomization.yaml      # Helm chart (if any) + custom resources
├── values.yml              # Helm values (optional)
└── custom-resources/       # Plain manifests (deployments, services, ...)
```

The ApplicationSet (`cluster/appset.yml`) auto-discovers the directory and creates an Application named after it, targeting the namespace with the same name.

For most apps you only need to:

1. Add `cluster/apps/<app>/kustomization.yaml` (and `values.yml` / manifests).
2. Render it: `kubectl kustomize cluster/apps/<app>`.
3. Merge via PR. Argo CD creates the namespace and deploys the app.

> [!NOTE]
> The frontend and backend Deployments reference `:latest` images; the actual pinned tags are set via the `images:` section in their `kustomization.yaml`.

## Handling secrets

- **Kubernetes**: create a `Secret`, encrypt it with `kubeseal`, and commit the resulting `SealedSecret`:

```sh
kubectl create secret generic <name> \
  --from-literal KEY=value --dry-run=client -o yaml \
  | kubeseal --format yaml -w custom-resources/.../sealed-secret.yml
```

- **Ansible**: `ansible-vault encrypt` host/group vars; the password file stays out of the repo.

## Ansible changes

- Playbooks: `ansible/0-setup.yml` (users/SSH keys) and `ansible/1-k3s.yml` (k3s bootstrap via `k3s-ansible`).
- Install the collection dependency with `ansible-galaxy collection install -r ansible/requirements.yml` (stored under `ansible/collections`, gitignored).
- Run playbooks against the host defined in `ansible/inventory/main.yml`.
- The k3s version is pinned in `ansible/inventory/group_vars/k3s_cluster.yml`.
