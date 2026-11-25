#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP=build/LKK.app
TARGET="$HOME/Library/Input Methods/LKK.app"
[[ -d "$APP" ]] || { echo 'Build the app first.' >&2; exit 1; }
[[ ! -e "$TARGET" && ! -L "$TARGET" ]] || { echo 'An LKK installation already exists; refusing to replace it.' >&2; exit 1; }
codesign --verify --strict "$APP"
mkdir -p "$HOME/Library/Input Methods"
ditto "$APP" "$TARGET"
echo 'Installed LKK for the current user. Add LKK in Keyboard settings; a new login session may be required.'
