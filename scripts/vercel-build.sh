#!/usr/bin/env bash
set -euo pipefail

IS_VERCEL_BUILD=0
if [ "${VERCEL:-}" = "1" ] || [ -n "${VERCEL_ENV:-}" ] || [ -n "${VERCEL_GIT_COMMIT_SHA:-}" ] || [[ "$PWD" == /vercel/* ]]; then
  IS_VERCEL_BUILD=1
fi

if [ "$IS_VERCEL_BUILD" = "1" ]; then
  echo "Detected Vercel build environment; using Vercel Supabase environment variables."

  if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
    echo "ERROR: Vercel production build requires non-empty SUPABASE_URL and SUPABASE_ANON_KEY environment variables."
    echo "Set them in Vercel Project Settings -> Environment Variables, then redeploy."
    exit 1
  fi
else
  echo "Using local env.json for Flutter web build."
fi

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

if [ "$IS_VERCEL_BUILD" = "1" ]; then
  "$FLUTTER_BIN" build web --release \
    --dart-define="SUPABASE_URL=$SUPABASE_URL" \
    --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
    --no-wasm-dry-run
else
  "$FLUTTER_BIN" build web --release --dart-define-from-file=env.json --no-wasm-dry-run
fi
