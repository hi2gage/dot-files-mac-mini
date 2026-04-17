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
brew_install git
brew_install mise
brew_install lazygit
brew_install tree
brew_install tmux

# xcodes — custom build from hi2gage/xcodes#add_LibFido2Swift (FIDO2/hardware
# security key auth support). PR: https://github.com/XcodesOrg/xcodes/pull/387
if brew list --formula xcodes &>/dev/null
    echo "🧹 Removing brew xcodes (switching to FIDO2 build)..."
    brew uninstall xcodes
end

set -l XCODES_SRC $HOME/Dev/xcodes
set -l XCODES_BIN /opt/homebrew/bin/xcodes
if not test -d $XCODES_SRC
    echo "📥 Cloning hi2gage/xcodes (add_LibFido2Swift)..."
    git clone -b add_LibFido2Swift https://github.com/hi2gage/xcodes.git $XCODES_SRC
else
    echo "🔄 Updating xcodes source..."
    git -C $XCODES_SRC fetch origin add_LibFido2Swift
    git -C $XCODES_SRC checkout add_LibFido2Swift
    git -C $XCODES_SRC pull --ff-only
end

echo "🧰 Building xcodes (swift build -c release)..."
swift build --package-path $XCODES_SRC -c release
sudo cp -f $XCODES_SRC/.build/release/xcodes $XCODES_BIN
echo "✅ xcodes installed at $XCODES_BIN"

# Docker Desktop (provides docker CLI + daemon).
brew_install_cask docker

# Tailscale (remote access).
brew_install_cask tailscale

# Claude Code — installs to ~/.local/bin/claude, which isn't on fish's PATH
# by default, so check the binary path directly instead of `command -q`.
set -l CLAUDE_BIN $HOME/.local/bin/claude
if not test -x $CLAUDE_BIN
    echo "🤖 Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "✅ Claude Code already installed."
end

# Persist ~/.local/bin on fish PATH (universal variable — survives new shells).
fish_add_path $HOME/.local/bin

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
echo "  1. Register the runner. The token expires in 1 hour, so grab it"
echo "     right before running config.sh:"
echo "       https://github.com/<OWNER>/<REPO>/settings/actions/runners/new   (repo)"
echo "       https://github.com/organizations/<ORG>/settings/actions/runners/new  (org)"
echo ""
echo "       cd $RUNNER_DIR"
echo "       ./config.sh --url https://github.com/<OWNER>/<REPO> --token <TOKEN>"
echo ""
echo "  2. Install as a LaunchAgent (no sudo — needs a GUI login session"
echo "     so simulator/UI tests can reach the window server):"
echo "       cd $RUNNER_DIR"
echo "       ./svc.sh install"
echo "       ./svc.sh start"
echo ""
echo "  3. Authenticate gh if you want runner management from the CLI:"
echo "       gh auth login"
echo ""
echo "  4. Install the latest Xcode (interactive — FIDO2 key supported):"
echo "       xcodes install --latest --select"
