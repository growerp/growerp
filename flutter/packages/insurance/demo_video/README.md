# Tasco demo video

Scripted, narrated run of the insurance app for the Tasco "AI for Insurance" submission.

1. `GEMINI_API_KEY=... ./tts.sh`: voiceover per scene from `narration.json` → `out/*.wav`, `out/durations.json`.
2. The local backend must run on :8080 **without** `GROWERP_TEST_MODE`, and with a Gemini key, so
   the explanation, the photo triage and the assistant are real AI.
3. `./record.sh`: Xvfb + ffmpeg record of `integration_test/demo_video_test.dart` → `out/raw.mp4`, `out/markers.txt`.
4. `./assemble.py`: cuts the scenes, adds the verify-page still, voice and captions → `out/tasco_demo.mp4`.

`photos/` are illustrative claim photos made with the Gemini image API (`gen_photos.py`). The
test feeds them to the claim wizard through a fake file picker.
