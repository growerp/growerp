#!/usr/bin/env python3
"""Windows Store listing (text + screenshots) for a Partner Center submission.

Shared by publish-metadata.yml (listing only) and publish-binary.yml (the binary
submission carries the listing, so a later metadata run has nothing to replace).

CLI (for PowerShell):
  windows_listing.py <app> <framed_dir> <sub_in.json> <sub_out.json> <files_out.txt>
writes the updated submission and the screenshot files to put in the upload zip.
"""
import json
import sys
from pathlib import Path


def metadata_dir(app_name):
    return Path(f'flutter/packages/{app_name}/windows/fastlane/metadata/en-US')


def prepare_screenshots(app_name, framed_dir):
    """Framed windows-<app>-*_framed.png (dashboard first, max 9) padded with white
    to 1920x1080 as screenshots/screenshot_N.png. No framed screenshots: none, and
    the store keeps its current images."""
    from PIL import Image

    out = metadata_dir(app_name) / 'screenshots'
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob('*.png'):
        old.unlink()
    framed = Path(framed_dir)
    dashboard = framed / f'windows-{app_name}-dashboard_framed.png'
    sources = [dashboard] if dashboard.is_file() else []
    sources += [p for p in sorted(framed.glob(f'windows-{app_name}-*_framed.png'))
                if p != dashboard]
    for count, src in enumerate(sources[:9], start=1):
        img = Image.open(src).convert('RGBA')
        img.thumbnail((1920, 1080))
        canvas = Image.new('RGB', (1920, 1080), 'white')
        canvas.paste(img, ((1920 - img.width) // 2, (1080 - img.height) // 2), img)
        dest = out / f'screenshot_{count}.png'
        canvas.save(dest)
        print(f'  → {dest}')
    print(f'Extracted {min(len(sources), 9)} Windows screenshots')


def apply_listing(sub, app_name):
    """Writes the listing of the app into the submission; returns the screenshot
    files the upload zip must contain (entry name = file name)."""
    md = metadata_dir(app_name)

    def read_field(name):
        f = md / name
        return f.read_text().strip() if f.exists() else ''

    # Partner Center takes at most 7 search terms of 30 characters each.
    keywords = [k.strip() for k in read_field('keywords.txt').split(',') if k.strip()]
    keywords = [k for k in keywords if len(k) <= 30][:7]

    screenshots = sorted((md / 'screenshots').glob('screenshot_*.png'))
    print(f'Found {len(screenshots)} screenshots')

    # The submission API keeps listing text under listings[lang].baseListing —
    # fields written at the listing root are silently ignored.
    listings = sub.get('listings') or {}
    base_listing = listings.setdefault('en-us', {}).setdefault('baseListing', {})
    base_listing.update({
        'description': read_field('description.txt'),
        'shortDescription': read_field('short_description.txt'),
        'releaseNotes': read_field('release_notes.txt'),
        'keywords': keywords,
    })
    if screenshots:
        # Preserve non-screenshot images (like StoreLogo)
        images = [i for i in base_listing.get('images', []) if i.get('imageType') != 'Screenshot']
        images += [{'fileStatus': 'PendingUpload', 'fileName': p.name, 'imageType': 'Screenshot'}
                   for p in screenshots]
        base_listing['images'] = images
    sub['listings'] = listings

    # A never-published app clones a submission with applicationCategory
    # 'NotSet', which the update rejects (400 InvalidParameterValue).
    # Fill it from category.txt (e.g. Education, Business_AccountingAndFinance);
    # an existing category set in Partner Center is left untouched.
    category = read_field('category.txt')
    if category and sub.get('applicationCategory') in (None, '', 'NotSet'):
        sub['applicationCategory'] = category

    # A cloned submission from an app whose baseline never set this returns
    # 400 InvalidParameterValue on update. GrowERP ships a Desktop MSIX, so
    # default Desktop=True and leave the other families as-is/False.
    aff = sub.get('allowTargetFutureDeviceFamilies') or {}
    for fam in ('Desktop', 'Mobile', 'Xbox', 'Holographic'):
        aff.setdefault(fam, fam == 'Desktop')
    sub['allowTargetFutureDeviceFamilies'] = aff
    return screenshots


if __name__ == '__main__':
    if len(sys.argv) != 6:
        sys.exit(__doc__)
    app, framed_dir, sub_in, sub_out, files_out = sys.argv[1:]
    prepare_screenshots(app, framed_dir)
    sub = json.loads(Path(sub_in).read_text(encoding='utf-8-sig'))
    files = apply_listing(sub, app)
    Path(sub_out).write_text(json.dumps(sub), encoding='utf-8')
    Path(files_out).write_text(''.join(f'{p.resolve()}\n' for p in files), encoding='utf-8')
