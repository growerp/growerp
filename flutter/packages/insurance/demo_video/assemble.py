#!/usr/bin/env python3
"""Cut out/raw.mp4 into the narrated scenes (out/markers.txt), add the verify page still, the
voiceover (out/<id>.wav) and burned-in captions, and join them into out/tasco_demo.mp4."""
import json, os, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
W, H, FPS = 1280, 720, 25


def run(*args):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *args], check=True)


def srt_time(s):
    ms = int(s * 1000)
    return f"{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}"


narration = json.load(open(os.path.join(HERE, "narration.json")))
durations = json.load(open(os.path.join(OUT, "durations.json")))
record_start, starts, ends = None, {}, {}
for line in open(os.path.join(OUT, "markers.txt")):
    parts = line.split()
    if parts[0] == "RECORD_START":
        record_start = int(parts[1])
    elif len(parts) >= 3 and parts[0] in ("SCENE_START", "SCENE_END"):
        (starts if parts[0] == "SCENE_START" else ends)[parts[1]] = int(parts[2])

# the public verify page, as a phone would show it after scanning the QR code
url = open(os.path.join(OUT, "verify_url.txt")).read().strip()
shot = os.path.join(OUT, "verify.png")
subprocess.run(["google-chrome", "--headless=new", "--disable-gpu", "--hide-scrollbars",
                f"--screenshot={shot}", "--window-size=390,760", "--force-device-scale-factor=1",
                url], check=True, capture_output=True)

style = ("FontName=DejaVu Sans,FontSize=17,PrimaryColour=&H00FFFFFF,BackColour=&H90000000,"
         "BorderStyle=3,Outline=6,Shadow=0,MarginV=22,MarginL=60,MarginR=60")
clips = []
for i, scene in enumerate(narration):
    sid = scene["id"]
    voice = os.path.join(OUT, f"{sid}.wav")
    clip = os.path.join(OUT, f"clip_{i:02}_{sid}.mp4")
    srt = os.path.join(OUT, f"clip_{i:02}.srt")
    length = durations[sid] / 1000 + 0.7
    speed = 1.0
    if sid in starts and sid in ends:
        start = (starts[sid] - record_start) / 1000
        actual = (ends[sid] - starts[sid]) / 1000
        # a scene that takes longer than its voiceover (typing, AI answers) runs faster,
        # at most 3x, so the video keeps the pace of the narration
        speed = min(3.0, max(1.0, actual / (length + 1.5)))
        length = max(length, actual / speed)
        video = ["-ss", f"{start:.3f}", "-t", f"{actual:.3f}", "-i", os.path.join(OUT, "raw.mp4")]
    elif sid == "verify":
        video = ["-loop", "1", "-t", f"{length:.3f}", "-i", shot]
    else:
        print("skipped, no markers:", sid)
        continue
    # captions: the narration in sentence-sized pieces over the scene
    words = scene["text"].split()
    chunks, cur = [], []
    for w in words:
        cur.append(w)
        if len(" ".join(cur)) > 70 or w.endswith((".", ":", "?")):
            chunks.append(" ".join(cur)); cur = []
    if cur:
        chunks.append(" ".join(cur))
    talk = durations[sid] / 1000
    total_chars = sum(len(c) for c in chunks)
    t, lines = 0.2, []
    for n, c in enumerate(chunks, 1):
        d = talk * len(c) / total_chars
        lines.append(f"{n}\n{srt_time(t)} --> {srt_time(t + d)}\n{c}\n")
        t += d
    open(srt, "w").write("\n".join(lines))
    if sid == "verify":
        vf = (f"color=c=0x1c2733:s={W}x{H}:d={length:.3f}[bg];[0:v]scale=-2:{H - 90}[phone];"
              f"[bg][phone]overlay=(W-w)/2:24,fps={FPS},subtitles={srt}:force_style='{style}'[v]")
    else:
        vf = (f"[0:v]setpts=PTS/{speed:.3f},fps={FPS},scale={W}:{H},"
              f"subtitles={srt}:force_style='{style}'[v]")
    run(*video, "-i", voice,
        "-filter_complex", f"{vf};[1:a]adelay=200|200,apad,atrim=0:{length:.3f}[a]",
        "-map", "[v]", "-map", "[a]", "-t", f"{length:.3f}",
        "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "160k", "-ar", "48000", clip)
    clips.append(clip)
    print(f"{sid}: {length:.1f}s x{speed:.1f}")

listing = os.path.join(OUT, "clips.txt")
open(listing, "w").write("".join(f"file '{c}'\n" for c in clips))
final = os.path.join(OUT, "tasco_demo.mp4")
run("-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", "-movflags", "+faststart", final)
dur = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                      final], capture_output=True, text=True).stdout.strip()
print("wrote", final, f"{float(dur):.0f}s")
