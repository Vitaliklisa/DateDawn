#!/bin/sh
set -eu
# Resolve the project root from this script's own location, so the revive path
# works whether the workspace is mounted at /workspace or somewhere else.
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if curl -sf -o /dev/null --max-time 2 http://127.0.0.1:8080/; then
  exit 0
fi
flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  >>/tmp/app-startup.log 2>&1 &
