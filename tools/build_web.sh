#!/bin/sh
# Builds the phone-testable web version: godot web export, then packs the
# engine as gzipped base64 text next to tools/web_shell.html (artifact hosting
# only serves text-like files under 16MB). Usage: tools/build_web.sh path/to/godot
set -e
GODOT=${1:-godot}
mkdir -p export/web
"$GODOT" --headless --path . --export-release "Web" export/web/index.html
cd export/web
gzip -9 -c index.wasm | base64 -w0 > engine.txt
base64 -w0 index.pck > pack.txt
cp ../../tools/web_shell.html kingjump.html
echo "Upload kingjump.html with index.js, index.audio.worklet.js, engine.txt, pack.txt"
