#!/bin/bash
#
# Mac Mini CI/CD bootstrap — stage 1.
# Installs Xcode Command Line Tools, Homebrew, and fish, then hands off
# to bootstrap.fish for the rest of the setup.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/hi2gage/dot-files-mac-mini/main/setup.sh | bash

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/hi2gage/dot-files-mac-mini/main"

echo "🤖 Mac Mini CI/CD setup — stage 1"

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "🛠  Installing Xcode Command Line Tools (GUI prompt will appear)..."
  xcode-select --install || true
  # Wait for the user to finish the GUI install.
  until xcode-select -p &>/dev/null; do
    echo "   …waiting for Xcode CLT to finish installing"
    sleep 10
  done
  echo "✅ Xcode CLT installed."
else
  echo "✅ Xcode CLT already installed."
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew already installed."
fi

# Make brew available in this shell (Apple Silicon vs Intel).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# fish
if ! command -v fish &>/dev/null; then
  echo "🐟 Installing fish..."
  brew install fish
else
  echo "✅ fish already installed."
fi

FISH_BIN="$(command -v fish)"

# Register fish in /etc/shells so it can be used as a login shell.
if ! grep -qxF "$FISH_BIN" /etc/shells; then
  echo "➕ Adding $FISH_BIN to /etc/shells (sudo)..."
  echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
fi

# Make fish the default login shell for this user.
# Use `sudo dscl` instead of `chsh` — chsh tries to prompt on stdin, which
# doesn't work when this script is run via `curl | bash`.
CURRENT_SHELL="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$CURRENT_SHELL" != "$FISH_BIN" ]; then
  echo "🐟 Setting fish as default login shell (sudo)..."
  sudo dscl . -create "$HOME" UserShell "$FISH_BIN"
  NEW_SHELL="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
  if [ "$NEW_SHELL" = "$FISH_BIN" ]; then
    echo "✅ Login shell is now $FISH_BIN (takes effect on next login)."
  else
    echo "⚠️  Login shell still $NEW_SHELL — try manually: sudo chsh -s $FISH_BIN $USER"
  fi
else
  echo "✅ fish already the default login shell."
fi

# Hand off to the fish stage. Always fetch fresh so updates propagate.
FISH_BOOTSTRAP="$HOME/bootstrap.fish"
echo "⬇️  Fetching bootstrap.fish..."
curl -fsSL "$REPO_RAW/bootstrap.fish" -o "$FISH_BOOTSTRAP"
chmod +x "$FISH_BOOTSTRAP"

echo "➡️  Handing off to bootstrap.fish"
exec "$FISH_BIN" "$FISH_BOOTSTRAP"
