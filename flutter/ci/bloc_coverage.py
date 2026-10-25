#!/usr/bin/env python3
"""Line coverage of every bloc (lib/**/*_bloc.dart) by the unit tests.

Reads <package>/coverage/lcov.info written by `melos test_unit`
(flutter test --coverage). A bloc no test loaded is not in lcov.info: it is
listed as 'no tests' and left out of the line percentage, which covers the
tested blocs only (lcov has no line count for files it never loaded).

Usage: python3 ci/bloc_coverage.py [--json out.json] [--markdown out.md]
Run from flutter/. Prints the markdown table when no output is given.
"""
import argparse
import glob
import json
import os


def lcov_lines(path):
    """{source file: (lines found, lines hit)} from an lcov.info file."""
    result, sf, found, hit = {}, None, 0, 0
    try:
        lines = open(path).read().splitlines()
    except OSError:
        return result
    for line in lines:
        if line.startswith('SF:'):
            sf, found, hit = line[3:], 0, 0
        elif line.startswith('DA:'):
            found += 1
            if int(line[3:].split(',')[1]) > 0:
                hit += 1
        elif line == 'end_of_record' and sf:
            result[sf] = (found, hit)
    return result


def collect(root='packages'):
    blocs = []
    for pkg_dir in sorted(glob.glob(f'{root}/*/')):
        pkg = os.path.basename(pkg_dir.rstrip('/'))
        files = sorted(glob.glob(f'{pkg_dir}lib/**/*_bloc.dart', recursive=True))
        if not files:
            continue
        cov = lcov_lines(f'{pkg_dir}coverage/lcov.info')
        for f in files:
            rel = os.path.relpath(f, pkg_dir)  # lcov SF paths: lib/src/...
            found, hit = cov.get(rel, (0, 0))
            blocs.append({'package': pkg, 'file': rel, 'lines': found, 'hit': hit,
                          'tested': rel in cov})
    lines = sum(b['lines'] for b in blocs if b['tested'])
    hit = sum(b['hit'] for b in blocs if b['tested'])
    return {
        'blocs': blocs,
        'total_blocs': len(blocs),
        'tested_blocs': sum(1 for b in blocs if b['tested']),
        'lines': lines,
        'hit': hit,
        'percent': round(100 * hit / lines, 1) if lines else 0.0,
    }


def pct(b):
    return round(100 * b['hit'] / b['lines'], 1) if b['lines'] else 0.0


def markdown(data):
    out = [f"Blocs with tests: {data['tested_blocs']}/{data['total_blocs']}, "
           f"line coverage of the tested blocs: {data['percent']}% "
           f"({data['hit']}/{data['lines']})", '',
           '| Package | Bloc | Coverage | Lines |', '|---|---|---:|---:|']
    for b in sorted(data['blocs'], key=lambda b: (b['package'], b['file'])):
        cov, lines = ((f"{pct(b)}%", f"{b['hit']}/{b['lines']}") if b['tested']
                      else ('no tests', ''))
        out.append(f"| {b['package']} | {os.path.basename(b['file'])} | {cov} | {lines} |")
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--json')
    ap.add_argument('--markdown')
    args = ap.parse_args()
    data = collect()
    if args.json:
        with open(args.json, 'w') as f:
            json.dump(data, f)
    if args.markdown:
        with open(args.markdown, 'w') as f:
            f.write(markdown(data))
    if not args.json and not args.markdown:
        print(markdown(data), end='')
