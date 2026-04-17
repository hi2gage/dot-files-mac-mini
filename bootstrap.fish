#!/usr/bin/env fish
#
# Mac Mini CI/CD bootstrap — stage 2 (fish).
# Runs after setup.sh has installed brew + fish.

echo "🐟 Mac Mini CI/CD setup — stage 2"

# Ensure brew is on PATH inside fish.
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

function brew_install --argument-names pkg
    if brew list --formula $pkg &>/dev/null
        echo "✅ $pkg already installed."
    else
        echo "🔧 Installing $pkg..."
        brew install $pkg
    end
end

function brew_install_cask --argument-names pkg
    if brew list --cask $pkg &>/dev/null
        echo "✅ $pkg (cask) already installed."
    else
        echo "🍺 Installing $pkg (cask)..."
        brew install --cask $pkg
    end
end

# Core CI tools.
brew_install gh
brew_install xcodes
brew_install git
brew_install mise
brew_install lazygit
brew_install tree

# Latest Xcode via xcodes (prompts for Apple ID; large download).
if test (count (xcodes installed 2>/dev/null)) -eq 0
    echo "🧰 Installing latest Xcode (this is slow and needs your Apple ID)..."
    xcodes install --latest --select
else
    echo "✅ Xcode already installed."
end

# Docker Desktop (provides docker CLI + daemon).
brew_install_cask docker

# Claude Code.
if not command -q claude
    echo "🤖 Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "✅ Claude Code already installed."
end

# ~/Dev workspace.
if not test -d $HOME/Dev
    echo "📁 Creating ~/Dev..."
    mkdir $HOME/Dev
else
    echo "✅ ~/Dev already exists."
end

# GitHub Actions self-hosted runner.
set -l RUNNER_DIR "$HOME/actions-runner"
if test -f "$RUNNER_DIR/config.sh"
    echo "✅ actions-runner already downloaded at $RUNNER_DIR."
else
    echo "🏃 Downloading GitHub Actions runner..."
    mkdir -p "$RUNNER_DIR"

    # Detect architecture: osx-arm64 for Apple Silicon, osx-x64 for Intel.
    set -l arch (uname -m)
    set -l runner_arch osx-x64
    if test "$arch" = arm64
        set runner_arch osx-arm64
    end

    # Fetch latest release version via GitHub API.
    set -l latest (curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
        | grep '"tag_name"' | head -n1 | sed -E 's/.*"v([^"]+)".*/\1/')
    if test -z "$latest"
        echo "❌ Could not determine latest actions-runner version."
        exit 1
    end

    set -l tarball "actions-runner-$runner_arch-$latest.tar.gz"
    set -l url "https://github.com/actions/runner/releases/download/v$latest/$tarball"

    echo "   → $url"
    curl -fsSL -o "$RUNNER_DIR/$tarball" "$url"
    tar xzf "$RUNNER_DIR/$tarball" -C "$RUNNER_DIR"
    rm "$RUNNER_DIR/$tarball"
    echo "✅ Runner extracted to $RUNNER_DIR."
end

echo ""
echo "🎉 Stage 2 complete."
echo ""
echo "Next steps (manual, require secrets):"
echo "  1. Register the runner with a repo/org:"
echo "       cd $RUNNER_DIR"
echo "       ./config.sh --url https://github.com/<OWNER>/<REPO> --token <REGISTRATION_TOKEN>"
echo "     Get the token from: https://github.com/<OWNER>/<REPO>/settings/actions/runners/new"
echo ""
echo "  2. Install as a launchd service so it survives reboots:"
echo "       cd $RUNNER_DIR"
echo "       sudo ./svc.sh install"
echo "       sudo ./svc.sh start"
echo ""
echo "  3. Authenticate gh if you want runner management from the CLI:"
echo "       gh auth login"
