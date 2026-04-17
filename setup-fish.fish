#!/usr/bin/env fish
#
# Fish shell configuration: completions, PATH, mise hook.
# Standalone: `fish setup-fish.fish`, or auto-run at the end of bootstrap.fish.

echo "🐟 Configuring fish (completions + shell hooks)..."

# Ensure brew is on PATH (in case this is run standalone).
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

# Completions directory.
set -l COMPLETIONS_DIR $HOME/.config/fish/completions
mkdir -p $COMPLETIONS_DIR

# Docker completions.
if command -q docker
    docker completion fish > $COMPLETIONS_DIR/docker.fish
    echo "✅ docker completions installed."
else
    echo "⚠️  docker not on PATH; skipping."
end

# gh completions.
if command -q gh
    gh completion -s fish > $COMPLETIONS_DIR/gh.fish
    echo "✅ gh completions installed."
else
    echo "⚠️  gh not on PATH; skipping."
end

# xcodes completions (swift-argument-parser).
if command -q xcodes
    xcodes --generate-completion-script fish > $COMPLETIONS_DIR/xcodes.fish
    echo "✅ xcodes completions installed."
else
    echo "⚠️  xcodes not on PATH; skipping."
end

# PATH — persist ~/.local/bin for tools like claude.
fish_add_path $HOME/.local/bin

# mise activation — add to config.fish if not already present.
set -l CONFIG_FISH $HOME/.config/fish/config.fish
mkdir -p (dirname $CONFIG_FISH)
touch $CONFIG_FISH
if not grep -q "mise activate fish" $CONFIG_FISH
    echo "" >> $CONFIG_FISH
    echo "# mise (runtime version manager)" >> $CONFIG_FISH
    echo "mise activate fish | source" >> $CONFIG_FISH
    echo "✅ Added mise activation to config.fish."
else
    echo "✅ mise activation already in config.fish."
end

echo "🎉 Fish setup complete."
