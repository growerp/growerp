#!/usr/bin/env python3
"""Illustrative claim photos for the demo video, made once with the Gemini image API.
Needs GEMINI_API_KEY; model GEMINI_IMAGE_MODEL (default gemini-3.1-flash-image)."""
import base64, json, os, sys, urllib.request

MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3.1-flash-image")
KEY = os.environ["GEMINI_API_KEY"]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "photos")
STYLE = ("Realistic smartphone photo taken by a driver right after a minor accident on a street "
         "in Ho Chi Minh City, daylight, slightly imperfect framing, no people's faces, no text overlays.")
PHOTOS = {
    "1_plate": "Close-up of the rear licence plate of a grey Toyota Corolla Cross, a Vietnamese white plate reading 51K-238.46, rear bumper dented.",
    "2_overview": "Rear three-quarter view of the same grey Toyota Corolla Cross stopped at a traffic light, rear bumper dented, Vietnamese white plate reading 51K-238.46 clearly legible.",
    "3_damage": "Tight close-up of only the dented rear bumper corner and a cracked left tail light of a grey Toyota Corolla Cross; the licence plate is outside the frame and not visible.",
    "4_other": "Front of a silver sedan right behind a grey SUV at a traffic light, small scratch on the sedan's front bumper, the sedan's plate blurred.",
}
for name, subject in PHOTOS.items():
    path = os.path.join(OUT, name + ".jpg")
    if os.path.exists(path):
        continue
    body = {"contents": [{"parts": [{"text": subject + " " + STYLE}]}],
            "generationConfig": {"responseModalities": ["IMAGE"]}}
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={KEY}",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    resp = json.load(urllib.request.urlopen(req, timeout=180))
    part = next(p for p in resp["candidates"][0]["content"]["parts"] if "inlineData" in p)
    open(path, "wb").write(base64.b64decode(part["inlineData"]["data"]))
    print("wrote", path, part["inlineData"].get("mimeType"))
