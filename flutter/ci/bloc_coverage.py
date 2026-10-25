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
import sys


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
        # only real blocs: website/lib/widgets/text_bloc.dart is a widget
        files = sorted(f for f in glob.glob(f'{pkg_dir}lib/**/*_bloc.dart', recursive=True)
                       if 'extends Bloc<' in open(f).read())
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


GOOD, FAIR = 85, 70  # percent: green from GOOD, yellow from FAIR, red below


def terminal(data, color=True):
    """Aligned report grouped by package, with bars and coloured percentages."""
    def paint(text, code):
        return f'\033[{code}m{text}\033[0m' if color else text

    def percent_text(p):
        code = '32' if p >= GOOD else '33' if p >= FAIR else '31'
        return paint(f'{p:5.1f}%', code)

    def bar(p, width=20):
        filled = round(p / 100 * width)
        return paint('█' * filled, '32' if p >= GOOD else '33' if p >= FAIR else '31') + \
            paint('░' * (width - filled), '2')

    by_package = {}
    for b in data['blocs']:
        by_package.setdefault(b['package'], []).append(b)
    name_width = max(
        [len(p) for p in by_package] +
        [len(os.path.basename(b['file'])) + 2 for b in data['blocs']])

    out = ['', paint('Bloc test coverage', '1'),
           f"{data['tested_blocs']}/{data['total_blocs']} blocs have tests, "
           f"they cover {percent_text(data['percent']).strip()} of their lines "
           f"({data['hit']}/{data['lines']})", '']
    for package in sorted(by_package):
        blocs = sorted(by_package[package], key=lambda b: b['file'])
        tested = [b for b in blocs if b['tested']]
        lines = sum(b['lines'] for b in tested)
        hit = sum(b['hit'] for b in tested)
        p = 100 * hit / lines if lines else 0.0
        out.append(f"{paint(package.ljust(name_width), '1')}  {percent_text(p)}  "
                   f"{bar(p)}  {hit:>5}/{lines:<5}")
        for b in blocs:
            name = ('  ' + os.path.basename(b['file'])).ljust(name_width)
            if b['tested']:
                out.append(f"{name}  {percent_text(pct(b))}  {bar(pct(b))}  "
                           f"{b['hit']:>5}/{b['lines']:<5}")
            else:
                out.append(f"{name}  {paint('no tests', '31')}")
    lowest = sorted((b for b in data['blocs'] if b['tested']), key=pct)[:5]
    if lowest:
        out += ['', 'Lowest: ' + ', '.join(
            f"{os.path.basename(b['file'])} {pct(b)}%" for b in lowest)]
    out.append(f"Green from {GOOD}%, yellow from {FAIR}%. "
               'Line detail: genhtml packages/<pkg>/coverage/lcov.info -o /tmp/cov')
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--json')
    ap.add_argument('--markdown')
    ap.add_argument('--no-color', action='store_true')
    args = ap.parse_args()
    data = collect()
    if args.json:
        with open(args.json, 'w') as f:
            json.dump(data, f)
    if args.markdown:
        with open(args.markdown, 'w') as f:
            f.write(markdown(data))
    if not args.json and not args.markdown:
        color = (sys.stdout.isatty() and not args.no_color
                 and 'NO_COLOR' not in os.environ)
        print(terminal(data, color=color), end='')
