"""Build Website/index.html from src/index.template.html with all photos embedded.

Run from anywhere:  python3 -I "Website/src/build.py"
Embeds every .jpg and .png in Website/assets (not subfolders), so index.html
shows them anywhere: opened as a file, in a preview, or on GitHub Pages.

People photos: drop files named people-sweet-1.jpg, people-sweet-2.jpg,
people-spicy-1.jpg, people-spicy-2.jpg into Website/assets and rebuild.
Until then the site shows styled placeholders in their place.
"""
import base64
import json
import pathlib

SITE = pathlib.Path(__file__).resolve().parent.parent
template = (SITE / "src" / "index.template.html").read_text(encoding="utf-8")
MIME = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}

images = {}
for f in sorted((SITE / "assets").iterdir()):
    if f.is_file() and f.suffix.lower() in MIME:
        data = base64.b64encode(f.read_bytes()).decode("ascii")
        images[f"assets/{f.name}"] = f"data:{MIME[f.suffix.lower()]};base64,{data}"

entries = ",\n".join(f"{json.dumps(k)}:{json.dumps(v)}" for k, v in images.items())
out = template.replace("/*IMAGES*/", entries)
(SITE / "index.html").write_text(out, encoding="utf-8")
print(f"Built index.html with {len(images)} images, {len(out) / 1e6:.1f} MB")
