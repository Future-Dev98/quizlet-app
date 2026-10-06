"""Resize the supplied artwork to the existing native launcher icon slots.

Usage: python tool/generate_icons.py [source-image]
Requires Pillow. The original artwork is preserved without cropping.
"""
from pathlib import Path
import json
import sys
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'assets/app_icon.jpg'
image = Image.open(source).convert('RGB')
if image.width != image.height:
    raise ValueError('Launcher artwork must be square')

def png(path, size, maskable=False):
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    if maskable:
        # Keep the complete illustration inside the central safe area.
        resized = Image.new('RGB', (size, size), image.getpixel((0, 0)))
        inset = round(size * .16)
        resized.paste(image.resize((size - inset * 2,) * 2, Image.Resampling.LANCZOS), (inset, inset))
    path.parent.mkdir(parents=True, exist_ok=True)
    resized.save(path)

for density, size in {'mdpi':48, 'hdpi':72, 'xhdpi':96, 'xxhdpi':144, 'xxxhdpi':192}.items():
    png(root / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
for platform in ['ios', 'macos']:
    folder = root / f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((folder / 'Contents.json').read_text())['images']:
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
        png(folder / entry['filename'], size)
for size in [192,512]:
    png(root / f'web/icons/Icon-{size}.png', size)
    png(root / f'web/icons/Icon-maskable-{size}.png', size, maskable=True)
png(root / 'web/favicon.png', 32)
image.save(root / 'windows/runner/resources/app_icon.ico', sizes=[(s,s) for s in [16,24,32,48,64,128,256]])
