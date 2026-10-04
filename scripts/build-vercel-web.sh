#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/.flutter-version")"
FLUTTER_SHA256="f1631b9c2c8b3529323db412b0d1beacf4a748f8783b0d7cf599a8fd5f461675"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.cache/flutter/$FLUTTER_VERSION}"
FLUTTER_ARCHIVE="$HOME/.cache/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Vercel's restored Flutter cache can be owned by a different build user.
# Trust only this SDK checkout, without changing the machine's global Git config.
GIT_CONFIG_INDEX="${GIT_CONFIG_COUNT:-0}"
export "GIT_CONFIG_KEY_${GIT_CONFIG_INDEX}=safe.directory"
export "GIT_CONFIG_VALUE_${GIT_CONFIG_INDEX}=$FLUTTER_HOME"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_INDEX + 1))

if ! command -v flutter >/dev/null 2>&1 ||
  ! flutter --version --machine |
    grep -Eq "\"frameworkVersion\"[[:space:]]*:[[:space:]]*\"$FLUTTER_VERSION\""; then
  mkdir -p "$(dirname "$FLUTTER_HOME")" "$HOME/.cache"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    curl --fail --location --retry 3 "$FLUTTER_URL" --output "$FLUTTER_ARCHIVE"
    echo "$FLUTTER_SHA256  $FLUTTER_ARCHIVE" | sha256sum --check --status
    mkdir -p "$FLUTTER_HOME"
    tar -xJf "$FLUTTER_ARCHIVE" --strip-components=1 -C "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

cd "$ROOT_DIR"
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release --base-href /
