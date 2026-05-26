#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Token Cat"
SOURCE_APP="$ROOT_DIR/.build/$APP_NAME.app"
INSTALL_DIR="/Applications"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"

"$ROOT_DIR/scripts/build-app.sh"

if pgrep -x TokenCatApp >/dev/null 2>&1; then
    killall TokenCatApp
fi

rm -rf "$INSTALLED_APP"
cp -R "$SOURCE_APP" "$INSTALL_DIR/"
xattr -dr com.apple.quarantine "$INSTALLED_APP" 2>/dev/null || true

if open "$INSTALLED_APP"; then
    echo "Installed and opened $INSTALLED_APP"
else
    echo "Installed $INSTALLED_APP"
    echo "Open it with: open \"$INSTALLED_APP\""
fi
