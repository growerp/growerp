#!/bin/bash
# Voiceover per scene with Gemini TTS -> out/<id>.wav and out/durations.json (ms per scene).
# Needs GEMINI_API_KEY. Voice/model like GeminiAiUtil.callGeminiTts: GEMINI_TTS_VOICE (Kore).
set -euo pipefail
cd "$(dirname "$0")"
MODEL="${GEMINI_TTS_MODEL:-gemini-2.5-flash-preview-tts}"
VOICE="${GEMINI_TTS_VOICE:-Kore}"
mkdir -p out
python3 - "$MODEL" "$VOICE" <<'PY'
import base64, json, os, subprocess, sys, urllib.request
model, voice = sys.argv[1], sys.argv[2]
key = os.environ["GEMINI_API_KEY"]
durations = {}
for scene in json.load(open("narration.json")):
    wav = f"out/{scene['id']}.wav"
    if not os.path.exists(wav):
        body = {"contents": [{"parts": [{"text": "Say in a calm, warm, professional product-demo voice: " + scene["text"]}]}],
                "generationConfig": {"responseModalities": ["AUDIO"],
                    "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}}}
        req = urllib.request.Request(
            f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}",
            data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        resp = json.load(urllib.request.urlopen(req, timeout=300))
        pcm = base64.b64decode(next(p for p in resp["candidates"][0]["content"]["parts"] if "inlineData" in p)["inlineData"]["data"])
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1",
                        "-i", "-", wav], input=pcm, check=True)
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", wav],
                         capture_output=True, text=True, check=True).stdout
    durations[scene["id"]] = int(float(out) * 1000)
    print(scene["id"], durations[scene["id"]], "ms")
json.dump(durations, open("out/durations.json", "w"), indent=2)
print("total", sum(durations.values()) // 1000, "s")
PY
