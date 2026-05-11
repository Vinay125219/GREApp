#!/usr/bin/env bash
set -euo pipefail

validate_supabase_url() {
  local url="${1%/}"
  local host

  if [[ ! "$url" =~ ^https://[a-z0-9-]+\.supabase\.co$ ]]; then
    echo "ERROR: SUPABASE_URL must look like https://PROJECT_REF.supabase.co"
    echo "Current SUPABASE_URL host is not a valid Supabase project API host."
    exit 1
  fi

  host="${url#https://}"

  if command -v getent >/dev/null 2>&1; then
    getent hosts "$host" >/dev/null || {
      echo "ERROR: SUPABASE_URL host does not resolve: $host"
      echo "Check the active Supabase project URL in Supabase Dashboard -> Project Settings -> API."
      exit 1
    }
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$host" >/dev/null || {
      echo "ERROR: SUPABASE_URL host does not resolve: $host"
      echo "Check the active Supabase project URL in Supabase Dashboard -> Project Settings -> API."
      exit 1
    }
  elif command -v node >/dev/null 2>&1; then
    node -e "require('dns').lookup(process.argv[1], error => process.exit(error ? 1 : 0))" "$host" || {
      echo "ERROR: SUPABASE_URL host does not resolve: $host"
      echo "Check the active Supabase project URL in Supabase Dashboard -> Project Settings -> API."
      exit 1
    }
  else
    echo "WARNING: Unable to validate Supabase host DNS; no resolver command is available."
  fi

  echo "Verified Supabase host resolves: $host"
}

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

  validate_supabase_url "$SUPABASE_URL"
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
  rm -f build/web/assets/env.json
else
  "$FLUTTER_BIN" build web --release --dart-define-from-file=env.json --no-wasm-dry-run
fi
