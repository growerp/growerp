#!/bin/bash
# Record the renewal demo video: the staff scenes (integration_test/renewal_video_test.dart)
# under Xvfb with ffmpeg, and meanwhile the customer side with Playwright (record_web.js).
# Needs: NARRATION=narration_renewal.json OUT=out_renewal ./tts.sh done, a local backend with
# real AI on :8080, and playwright (npm i playwright; PLAYWRIGHT_NODE_PATH = its node_modules).
set -euo pipefail
cd "$(dirname "$0")/.."
DEMO="$PWD/demo_video"
OUT="$DEMO/out_renewal"
rm -f "$OUT/links.json" "$OUT/web_done" "$OUT"/voice_*.png "$OUT"/voice_bot_*.wav "$OUT"/web_*.webm
mkdir -p "$OUT"
Xvfb :99 -screen 0 1280x720x24 -nolisten tcp &
XPID=$!
trap 'kill $XPID 2>/dev/null || true' EXIT
sleep 2
export DISPLAY=:99
# a Wayland session would put the window on the desktop instead of Xvfb
unset WAYLAND_DISPLAY
export GDK_BACKEND=x11
NODE_PATH="${PLAYWRIGHT_NODE_PATH:-}" node "$DEMO/record_web.js" "$OUT" > "$OUT/web.log" 2>&1 &
WPID=$!
echo "RECORD_START $(date +%s%3N)" > "$OUT/markers.txt"
ffmpeg -loglevel error -y -f x11grab -framerate 25 -video_size 1280x720 -i :99 \
  -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p "$OUT/raw.mp4" &
FPID=$!
set +e
flutter test integration_test/renewal_video_test.dart -d linux \
  --dart-define=BACKEND_PORT=8080 --dart-define=DEMO_DIR="$DEMO" 2>&1 \
  | tee "$OUT/test.log" | grep --line-buffered -E "SCENE_(START|END)" >> "$OUT/markers.txt"
set -e
kill -INT $FPID
wait $FPID || true
# a failed staff test never writes the links: do not wait for the web side then
if [ -f "$OUT/links.json" ]; then wait $WPID || true; else kill $WPID 2>/dev/null || true; fi
grep -E "All tests passed|Some tests failed" "$OUT/test.log" | tail -1
echo "scenes: $(grep -c SCENE_END "$OUT/markers.txt")"
tail -2 "$OUT/web.log"
