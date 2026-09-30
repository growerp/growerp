#!/bin/bash
# Record the scripted demo (integration_test/demo_video_test.dart): Xvfb :99 at 1280x720 (the
# window size of linux/runner), ffmpeg x11grab to out/raw.mp4, scene markers to out/markers.txt.
# Needs: ./tts.sh done (out/durations.json), local backend on :8080 with real AI.
set -euo pipefail
cd "$(dirname "$0")/.."
DEMO="$PWD/demo_video"
OUT="$DEMO/out"
mkdir -p "$OUT"
Xvfb :99 -screen 0 1280x720x24 -nolisten tcp &
XPID=$!
trap 'kill $XPID 2>/dev/null || true' EXIT
sleep 2
export DISPLAY=:99
# a Wayland session would put the window on the desktop instead of Xvfb
unset WAYLAND_DISPLAY
export GDK_BACKEND=x11
# build first, so the recording starts close to the app
flutter build linux --debug --target integration_test/demo_video_test.dart >/dev/null 2>&1 || true
echo "RECORD_START $(date +%s%3N)" > "$OUT/markers.txt"
ffmpeg -loglevel error -y -f x11grab -framerate 25 -video_size 1280x720 -i :99 \
  -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p "$OUT/raw.mp4" &
FPID=$!
set +e
flutter test integration_test/demo_video_test.dart -d linux \
  --dart-define=BACKEND_PORT=8080 --dart-define=DEMO_DIR="$DEMO" 2>&1 \
  | tee "$OUT/test.log" | grep --line-buffered -E "SCENE_(START|END)" >> "$OUT/markers.txt"
set -e
kill -INT $FPID
wait $FPID || true
grep -E "All tests passed|Some tests failed" "$OUT/test.log" | tail -1
echo "scenes: $(grep -c SCENE_END "$OUT/markers.txt")"
