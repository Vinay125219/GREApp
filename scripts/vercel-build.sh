#!/usr/bin/env bash
set -euo pipefail

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
else
  FLUTTER_HOME="${VERCEL_FLUTTER_HOME:-.vercel/cache/flutter}"
  if [ ! -d "$FLUTTER_HOME/.git" ]; then
    rm -rf "$FLUTTER_HOME"
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$PWD/$FLUTTER_HOME/bin:$PATH"
  FLUTTER_BIN="$PWD/$FLUTTER_HOME/bin/flutter"
fi

"$FLUTTER_BIN" --version
"$FLUTTER_BIN" config --enable-web
"$FLUTTER_BIN" pub get

if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  "$FLUTTER_BIN" build web --release \
    --dart-define="SUPABASE_URL=$SUPABASE_URL" \
    --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
    --no-wasm-dry-run
else
  "$FLUTTER_BIN" build web --release --dart-define-from-file=env.json --no-wasm-dry-run
fi
