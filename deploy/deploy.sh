#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

KUBECTL="${KUBECTL:-~/.local/bin/kubectl}"
NAMESPACE="dev"
DEPLOY_NAME="moonxi-board"

echo "=== Building JS ==="
~/.moon/bin/moon build --target js

echo "=== Preparing deploy dir ==="
TMPDIR=$(mktemp -d)
cp web/index.html "$TMPDIR/"
cp _build/js/debug/build/src/main/main.js "$TMPDIR/src.js"

echo "=== Getting pod name ==="
POD=$($KUBECTL get pods -n "$NAMESPACE" -l "app=$DEPLOY_NAME" -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo "=== Copying files ==="
$KUBECTL cp "$TMPDIR/index.html" "$NAMESPACE/$POD:/usr/share/nginx/html/index.html"
$KUBECTL cp "$TMPDIR/src.js" "$NAMESPACE/$POD:/usr/share/nginx/html/src.js"

rm -rf "$TMPDIR"
echo "=== Done ==="
