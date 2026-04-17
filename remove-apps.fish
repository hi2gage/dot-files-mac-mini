#!/usr/bin/env fish
#
# Remove Apple's bundled apps that aren't useful on a CI box.
# Run separately from bootstrap.fish (requires sudo).
#
#   fish remove-apps.fish

set -l apps \
    "GarageBand" \
    "iMovie" \
    "Keynote" \
    "Numbers" \
    "Pages"

echo "🗑  Removing Apple bundled apps (sudo required)..."

for app in $apps
    set -l path "/Applications/$app.app"
    if test -d $path
        echo "   → $path"
        sudo rm -rf $path
    else
        echo "   ✓ $app already removed."
    end
end

echo "✅ Done."
