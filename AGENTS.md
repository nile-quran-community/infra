# AGENTS.md

## Dev environment tips

- This is the IaC + GitOps repo for `nile-quran-community.com`, hosted on a single Hostinger VPS (2 vCPU / 8 GiB) running single-node k3s; Argo CD auto-syncs `main` with prune + self-heal.
- Use `mise run --locked i` to install all tools (opentofu, ansible-core, kubectl, helm, argocd, kubeseal, tflint, prek) and pre-commit hooks — never assume a global install.
- Ansible lives in `ansible/` (`0-setup.yml` for admin users/SSH, `1-k3s.yml` for the k3s bootstrap via k3s-ansible v1.2.1); the k3s version lives in `ansible/inventory/group_vars/k3s_cluster.yml`.
- GitOps manifests live in `cluster/`; the ApplicationSet (`cluster/appset.yml`) generates one Argo CD application per directory in `cluster/apps/*`, deployed into the namespace named after the directory.
- Prefer reading existing apps (e.g. `cluster/apps/traefik`, `cluster/apps/nile-quran-community`) as templates before writing new manifests.
- Ingress is Gateway API: attach services to the Traefik `Gateway` named `main` in the `traefik` namespace via `HTTPRoute`s that set `parentRefs` (with a `sectionName` for the listener).
- The frontend/backend Deployments reference `:latest` images, but the real tags come from the `images:` directive in the app `kustomization.yaml` — keep versions pinned.
- Never write plaintext secrets: Kubernetes uses `SealedSecret`s (kubeseal), Ansible uses `ansible-vault`. `ansible/.vaultpass` and `mise.local.toml` are gitignored.

## Testing instructions

- There are no unit tests; correctness is verified by rendering manifests, passing pre-commit, and observing Argo CD sync after merge.
- Run `prek run --all-files` to run every check (terraform fmt/validate/tflint, tombi, oxfmt).
- Render an app's manifests with `kubectl kustomize cluster/apps/<app>` or `kubectl apply --dry-run=client -k cluster/apps/<app>`.
- After editing Ansible, remember the inventory is `ansible/inventory/main.yml` before running playbooks.

## PR instructions

- PRs to `main` are required and Argo CD auto-syncs the merge.
- Commit messages follow Conventional Commits with scopes like `cluster/apps`, `cluster/nqc`, `cluster/traefik`, `cluster/argocd`, `cluster/cert-manager`, `ansible`; breaking changes use `!`.
- Always run `prek run --all-files` before committing.
- Keep changes focused on one area per PR.
