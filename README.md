# dot-files-mac-mini

Automated setup for a Mac Mini acting as a self-hosted CI/CD runner.

## One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/hi2gage/dot-files-mac-mini/main/setup.sh | bash
```

## What it does

**Stage 1 — `setup.sh`** (bash, runs on a fresh macOS):

- Installs Xcode Command Line Tools
- Installs Homebrew
- Installs fish and registers it in `/etc/shells`
- Hands off to stage 2

**Stage 2 — `bootstrap.fish`** (fish):

- Installs CLI tooling: `gh`, `xcodes`, `git`, `mise`, `lazygit`, `tree`
- Installs Docker Desktop (cask)
- Downloads the latest GitHub Actions runner into `~/actions-runner` (arch-aware)

Idempotent — safe to re-run.

## Manual follow-up

The runner registration needs a secret token, so it's left for you to run:

```fish
cd ~/actions-runner
./config.sh --url https://github.com/<OWNER>/<REPO> --token <REGISTRATION_TOKEN>
sudo ./svc.sh install
sudo ./svc.sh start
```

Get the token from `https://github.com/<OWNER>/<REPO>/settings/actions/runners/new`.
