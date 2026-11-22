"""Build Website/index.html from src/index.template.html.

Run from anywhere:  python3 -I "Website/src/build.py"

Photos are NOT embedded any more: the page links to files in Website/assets,
which GitHub Pages serves next to index.html. This keeps the page small and fast.
To preview locally, serve the Website folder (e.g. python3 -m http.server)
rather than opening index.html straight from Finder.
"""
import pathlib

SITE = pathlib.Path(__file__).resolve().parent.parent
template = (SITE / "src" / "index.template.html").read_text(encoding="utf-8")

missing = []
for ref in sorted(set(__import__("re").findall(r"assets/[\w.-]+\.(?:jpg|png|webp)", template))):
    if not (SITE / ref).is_file():
        missing.append(ref)

out = template.replace("/*IMAGES*/", "")
(SITE / "index.html").write_text(out, encoding="utf-8")
print(f"Built index.html, {len(out) / 1e3:.0f} KB (images linked from assets/)")
if missing:
    print("WARNING, missing images:", ", ".join(missing))
