#!/usr/bin/env python3
"""Merge the versions a run already shipped into the files at the branch tip.

A publish/staging run computes an app version early, ships it (store upload,
docker tag), then commits it much later. By then another workflow may have
rewritten the same `version:` line, so replaying the original diff conflicts.
Instead this rewrites each file at the tip to the element-wise max of the tip's
version and the shipped one: never below what was shipped, never a rollback of
whatever landed meanwhile.

Usage: merge_pubspec_versions.py <versions-file>
Each line of <versions-file> is `target=X.Y.Z+B`, where target is either an app
name (-> flutter/packages/<app>/pubspec.yaml) or a path to backend/component.xml.
"""
import re
import sys

VERSION_RE = re.compile(r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$')
PUBSPEC_RE = re.compile(r'^version:\s*(\S+)', re.MULTILINE)
COMPONENT_RE = re.compile(r'(name="growerp"\s+version=")([^"]*)(")')


def parse(version):
    m = VERSION_RE.match(version.strip())
    if not m:
        raise SystemExit(f'::error::unparsable version: {version!r}')
    major, minor, patch, build = (int(x) for x in m.groups())
    return (major, minor, patch), build


def merge(tip, shipped):
    tip_triple, tip_build = parse(tip)
    ship_triple, ship_build = parse(shipped)
    major, minor, patch = max(tip_triple, ship_triple)
    return f'{major}.{minor}.{patch}+{max(tip_build, ship_build)}'


def resolve(target):
    """(path, pattern, version group, rewrite) for an app name or component.xml."""
    if target.endswith('.xml'):
        return target, COMPONENT_RE, 2, lambda c, v: COMPONENT_RE.sub(
            lambda m: f'{m.group(1)}{v}{m.group(3)}', c, count=1)
    path = f'flutter/packages/{target}/pubspec.yaml'
    return path, PUBSPEC_RE, 1, lambda c, v: PUBSPEC_RE.sub(
        f'version: {v}', c, count=1)


def main(versions_file):
    with open(versions_file) as f:
        entries = [line.strip() for line in f if line.strip()]

    for entry in entries:
        target, _, shipped = entry.partition('=')
        path, read_re, group, write = resolve(target)
        with open(path) as f:
            content = f.read()

        m = read_re.search(content)
        if not m:
            raise SystemExit(f'::error::No version found in {path}')
        tip = m.group(group)

        merged = merge(tip, shipped)
        print(f'{path}: tip={tip}  shipped={shipped}  -> {merged}')
        if merged == tip:
            continue

        with open(path, 'w') as f:
            f.write(write(content, merged))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(f'usage: {sys.argv[0]} <versions-file>')
    main(sys.argv[1])
