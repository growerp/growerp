---
name: verify
description: Build, run and screenshot the GrowERP admin Flutter app headless to verify UI changes at runtime.
---

# Verify GrowERP Flutter changes (admin app, Linux desktop, headless)

## Prereqs
- Backend must run on :8080 (`pgrep -f moqui.war`); REST probe: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/rest/s1/growerp/100/Authenticate?classificationId=AppAdmin` → 403 = alive.
- Login account `test@example.com` / `qqqqqq9!` (AppAdmin, GROWERP owner). The desktop app
  restores the last session from the user's home dir, so it usually lands on the dashboard
  already logged in — no UI login driving needed.

## Build + run + screenshot
```bash
cd flutter/packages/admin
flutter build linux --debug          # ~40s incremental
Xvfb :99 -screen 0 1280x800x24 &
env -u WAYLAND_DISPLAY GDK_BACKEND=x11 DISPLAY=:99 \
  build/linux/x64/debug/bundle/admin > /tmp/app.log 2>&1 &
sleep 15   # app boot + login restore + dashboard REST loads
DISPLAY=:99 ffmpeg -y -loglevel error -f x11grab -video_size 1280x800 -i :99 \
  -frames:v 1 shot.png
# crop a tile: ffmpeg -i shot.png -vf "crop=W:H:X:Y" tile.png
```

## Gotchas
- **Must unset WAYLAND_DISPLAY + set GDK_BACKEND=x11**, else the window opens on the
  user's live Wayland session instead of the Xvfb display.
- **`pkill -f 'bundle/admin'` kills your own shell** (pattern matches the bash -c command
  line; exit 144). Use `pkill -x admin`.
- **Phone layout is NOT verifiable headless here**: no window manager is installed, so
  GTK ignores xdotool resizes (window clips, Flutter never relayouts) and does not clamp
  to a small Xvfb screen. Phone (412px) rendering is only covered by CI integration tests
  or a real emulator.
- `convert`/`import`/`scrot` are not installed; use ffmpeg x11grab for screenshots.
- Runner default window is 1280x720 (`linux/runner/my_application.cc`).
- Drive input with `xdotool` (installed); `xdotool search --class admin` finds the window.
