#!/usr/bin/env python3
"""Assemble the renewal demo video from out_renewal/: staff scenes cut from raw.mp4 (markers.txt),
the customer's phone recordings (web_*.webm) on a branded background, the AI call built from its
stills with the assistant's own speech, a Gemini-voiced customer and English subtitles, and the
cards; English voiceover and captions per scene -> out_renewal/tasco_renewal_demo.mp4.
Needs GEMINI_API_KEY for the customer's voice and the subtitle translation."""
import base64, json, os, subprocess, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out_renewal")
W, H, FPS = 1280, 720, 25
KEY = os.environ.get("GEMINI_API_KEY", "")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
STYLE = ("FontName=DejaVu Sans,FontSize=17,PrimaryColour=&H00FFFFFF,BackColour=&H90000000,"
         "BorderStyle=3,Outline=6,Shadow=0,MarginV=22,MarginL=60,MarginR=60")
PHONE_TITLES = {"zalo": ("Zalo reminder", "as the customer sees it (preview until the\nZalo OA / VETC gateway is connected)"),
                "renew": ("Private renewal page", "no app, no login: confirm the car,\nthen renew, ask for a call, or stop"),
                "voice": ("AI renewal call", "Vietnamese, permission first,\nhand-over to a person on request")}


def run(*args):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *args], check=True)


def duration(path):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                 "-of", "csv=p=0", path], capture_output=True, text=True).stdout)


def srt_time(s):
    ms = int(s * 1000)
    return f"{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}"


def gemini(model, body):
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={KEY}",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=300))


def tts(text, wav, voice="Puck"):
    if os.path.exists(wav):
        return
    pcm = None
    # short lines sometimes come back empty: try again, then without the style hint
    for prompt in ["Nói tự nhiên, như một khách hàng trên điện thoại: " + text, text, text, "Say: " + text]:
        resp = gemini("gemini-2.5-flash-preview-tts", {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"responseModalities": ["AUDIO"],
                                 "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}}})
        parts = resp.get("candidates", [{}])[0].get("content", {}).get("parts", [])
        audio = next((p for p in parts if "inlineData" in p), None)
        if audio:
            pcm = base64.b64decode(audio["inlineData"]["data"])
            break
    if pcm is None:
        raise Exception("no speech for: " + text)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "s16le", "-ar", "24000", "-ac", "1", "-i", "-", wav],
                   input=pcm, check=True)


def translate(lines):
    cache = os.path.join(OUT, "voice_en.json")
    if os.path.exists(cache):
        return json.load(open(cache))
    resp = gemini("gemini-3.8-flash", {
        "contents": [{"parts": [{"text": "Translate each Vietnamese line to natural English. Answer with a JSON "
                                          "array of strings only, same order:\n" + json.dumps(lines, ensure_ascii=False)}]}],
        "generationConfig": {"responseMimeType": "application/json", "maxOutputTokens": 4096}})
    text = resp["candidates"][0]["content"]["parts"][0]["text"]
    result = json.loads(text)
    json.dump(result, open(cache, "w"), ensure_ascii=False, indent=1)
    return result


def captions(text, talk, srt, start=0.2):
    words, chunks, cur = text.split(), [], []
    for w in words:
        cur.append(w)
        if len(" ".join(cur)) > 70 or w.endswith((".", ":", "?", ",")) and len(" ".join(cur)) > 30:
            chunks.append(" ".join(cur)); cur = []
    if cur:
        chunks.append(" ".join(cur))
    total = sum(len(c) for c in chunks) or 1
    t, lines = start, []
    for n, c in enumerate(chunks, 1):
        d = talk * len(c) / total
        lines.append(f"{n}\n{srt_time(t)} --> {srt_time(t + d)}\n{c}\n")
        t += d
    open(srt, "w").write("\n".join(lines))


def phone_bg(scene):
    """branded background with the scene title on the right, the phone goes on the left"""
    bg = os.path.join(OUT, f"bg_{scene}.png")
    title, sub = PHONE_TITLES[scene]
    sub_file = os.path.join(OUT, f"bg_{scene}.txt")
    open(sub_file, "w").write(sub)
    run("-f", "lavfi", "-i", f"color=c=0x14233B:s={W}x{H}", "-frames:v", "1", "-vf",
        f"drawtext=fontfile={BOLD}:text='{title}':fontcolor=0xF7F5EF:fontsize=44:x=640:y=270,"
        f"drawtext=fontfile={FONT}:textfile={sub_file}:fontcolor=0xC9D6E0:fontsize=26:x=640:y=340:line_spacing=10",
        bg)
    return bg


narration = json.load(open(os.path.join(HERE, "narration_renewal.json")))
text_of = {s["id"]: s["text"] for s in narration}
durations = json.load(open(os.path.join(OUT, "durations.json")))
record_start, starts, ends = None, {}, {}
for line in open(os.path.join(OUT, "markers.txt")):
    p = line.split()
    if p[0] == "RECORD_START":
        record_start = int(p[1])
    elif len(p) >= 3 and p[0] in ("SCENE_START", "SCENE_END"):
        (starts if p[0] == "SCENE_START" else ends)[p[1]] = int(p[2])

order = ["title", "problem", "cockpit", "dialog", "zalo", "renew", "voiceintro", "voice", "telesales", "impact", "close"]
clips = []
for i, sid in enumerate(order):
    clip = os.path.join(OUT, f"clip_{i:02}_{sid}.mp4")
    srt = os.path.join(OUT, f"clip_{i:02}.srt")
    if sid == "voice":
        data = json.load(open(os.path.join(OUT, "voice_turns.json")))
        turns = data["turns"]
        spoken = [t for t in turns if t["role"] in ("customer", "ai")]
        english = translate([t["text"] for t in spoken])
        bg = phone_bg("voice")
        segs, subs, t0 = [], [], 0.0
        for n, t in enumerate(spoken):
            if t["role"] == "customer":
                wav = os.path.join(OUT, f"cust_{n:02}.wav")
                tts(t["text"], wav)
            else:
                audio = [a for a in turns if a["role"] == "audio" and a["text"] == t["text"]]
                if not audio:
                    continue
                wav = os.path.join(OUT, audio[-1]["audio"])
            length = duration(wav) + 0.5
            seg = os.path.join(OUT, f"vseg_{n:02}.mp4")
            run("-loop", "1", "-t", f"{length:.3f}", "-i", bg, "-loop", "1", "-t", f"{length:.3f}",
                "-i", os.path.join(OUT, t["still"]), "-i", wav, "-filter_complex",
                f"[1:v]scale=-2:680[p];[0:v][p]overlay=150:20,fps={FPS},format=yuv420p[v];"
                f"[2:a]apad,atrim=0:{length:.3f},aresample=48000[a]",
                "-map", "[v]", "-map", "[a]", "-t", f"{length:.3f}", "-c:v", "libx264", "-preset", "medium",
                "-crf", "20", "-c:a", "aac", "-ar", "48000", "-ac", "1", seg)
            who = "Customer" if t["role"] == "customer" else "AI"
            subs.append(f"{len(subs) + 1}\n{srt_time(t0 + 0.1)} --> {srt_time(t0 + length - 0.1)}\n{who}: {english[n] if n < len(english) else ''}\n")
            segs.append(seg)
            t0 += length
        listing = os.path.join(OUT, "vsegs.txt")
        open(listing, "w").write("".join(f"file '{s}'\n" for s in segs))
        joined = os.path.join(OUT, "voice_joined.mp4")
        run("-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", joined)
        open(srt, "w").write("\n".join(subs))
        run("-i", joined, "-vf", f"subtitles={srt}:force_style='{STYLE}'", "-c:v", "libx264", "-preset", "medium",
            "-crf", "20", "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "1", clip)
        clips.append(clip)
        print(f"voice: {duration(clip):.1f}s")
        continue
    voice = os.path.join(OUT, f"{sid}.wav")
    length = durations[sid] / 1000 + 0.7
    speed = 1.0
    if sid in ("title", "problem", "voiceintro", "close"):
        video = ["-loop", "1", "-t", f"{length:.3f}", "-i", os.path.join(OUT, f"card_{sid}.png")]
        vf = f"[0:v]fps={FPS},scale={W}:{H}"
    elif sid in ("zalo", "renew"):
        webm = os.path.join(OUT, f"web_{sid}.webm")
        actual = duration(webm)
        speed = min(3.0, max(1.0, actual / (length + 1.5)))
        length = max(length, actual / speed)
        bg = phone_bg(sid)
        video = ["-loop", "1", "-t", f"{length:.3f}", "-i", bg, "-i", webm]
        vf = (f"[1:v]setpts=PTS/{speed:.3f},scale=-2:680,tpad=stop_mode=clone:stop_duration=30[p];"
              f"[0:v][p]overlay=150:20:shortest=0,fps={FPS}")
    else:
        start = (starts[sid] - record_start) / 1000
        actual = (ends[sid] - starts[sid]) / 1000
        speed = min(3.0, max(1.0, actual / (length + 1.5)))
        length = max(length, actual / speed)
        video = ["-ss", f"{start:.3f}", "-t", f"{actual:.3f}", "-i", os.path.join(OUT, "raw.mp4")]
        vf = f"[0:v]setpts=PTS/{speed:.3f},fps={FPS},scale={W}:{H}"
    captions(text_of[sid], durations[sid] / 1000, srt)
    audio_in = len([a for a in video if a == "-i"])
    run(*video, "-i", voice, "-filter_complex",
        f"{vf},subtitles={srt}:force_style='{STYLE}',format=yuv420p[v];"
        f"[{audio_in}:a]adelay=200|200,apad,atrim=0:{length:.3f},aresample=48000[a]",
        "-map", "[v]", "-map", "[a]", "-t", f"{length:.3f}", "-c:v", "libx264", "-preset", "medium",
        "-crf", "20", "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "1", clip)
    clips.append(clip)
    print(f"{sid}: {length:.1f}s x{speed:.1f}")

listing = os.path.join(OUT, "clips.txt")
open(listing, "w").write("".join(f"file '{c}'\n" for c in clips))
final = os.path.join(OUT, "tasco_renewal_demo.mp4")
run("-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", "-movflags", "+faststart", final)
print("wrote", final, f"{duration(final):.0f}s")
