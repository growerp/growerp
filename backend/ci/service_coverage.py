#!/usr/bin/env python3
"""Coverage of the growerp.100.* services by the backend Spock tests.

Two measures per service file (service/growerp/100/*Services100.xml):
- called: services the specs called / services defined. Calls come from
  build/service-hits.json, written by ServiceCoverageExtension during
  `./gradlew :runtime:component:growerp:test`.
- code: share of the code blocks (JaCoCo probes) of the called services that
  ran. Moqui compiles service actions at runtime into classes named after the
  service (growerp.100.X.get#Y -> growerp_100_X_get_Y) and their code sits in a
  run() that Groovy marks @Generated, which the JaCoCo report leaves out; the
  jacocoProbes gradle task reads the probes from the execution data into
  build/jacoco/probes.json. A service never called is never compiled and has no
  blocks.
The service/*.groovy scripts are reported by blocks the same way, compiled
src/main Groovy by lines (JaCoCo report).

Usage: python3 ci/service_coverage.py [--json out.json] [--markdown out.md]
Run from backend/. Prints the terminal report when no output is given.
"""
import argparse
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET


def clean(name):
    """StringUtilities.cleanStringForJavaName: non identifier chars -> '_'."""
    return re.sub(r'[^A-Za-z0-9_]', '_', name)


def services(root='service/growerp/100'):
    """{file stem: [service name]} from the service definition files."""
    result = {}
    for path in sorted(glob.glob(f'{root}/*.xml')):
        stem = os.path.splitext(os.path.basename(path))[0]
        names = []
        for node in ET.parse(path).getroot().iter('service'):
            verb, noun = node.get('verb'), node.get('noun')
            names.append(f"growerp.100.{stem}.{verb}#{noun}" if noun else f"growerp.100.{stem}.{verb}")
        result[stem] = names
    return result


def jacoco_lines(path):
    """{source file: (missed, covered)} lines per class of the JaCoCo report (src/main)."""
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError):
        return {}
    result = {}
    for cls in root.iter('class'):
        for c in cls.findall('counter'):
            if c.get('type') == 'LINE':
                source = cls.get('sourcefilename') or cls.get('name')
                old = result.get(source, (0, 0))
                result[source] = (old[0] + int(c.get('missed')), old[1] + int(c.get('covered')))
    return result


def collect(hits_path='build/service-hits.json', probes_path='build/jacoco/probes.json',
            jacoco_path='build/reports/jacoco/test/jacocoTestReport.xml'):
    try:
        with open(hits_path) as f:
            hits = set(json.load(f)['services'])
    except (OSError, ValueError, KeyError):
        hits = set()
    try:
        with open(probes_path) as f:
            probes = json.load(f)  # {class name: [hit, total]}, closures are classes of their own
    except (OSError, ValueError):
        probes = {}

    def blocks(prefix):
        hit = total = 0
        for name, (h, t) in probes.items():
            if name.startswith(prefix):
                hit, total = hit + h, total + t
        return hit, total

    files = []
    for stem, names in services().items():
        hit, total = blocks(clean(f'growerp.100.{stem}.'))
        called = sorted(n for n in names if n in hits)
        files.append({'file': stem, 'services': len(names), 'called': len(called),
                      'code': total, 'code_hit': hit,
                      'uncalled': sorted(set(names) - set(called))})

    scripts = []
    for path in sorted(glob.glob('service/*.groovy')):
        hit, total = blocks(clean(f'component://growerp/{path}'))
        scripts.append({'file': os.path.basename(path), 'code': total, 'code_hit': hit})

    groovy = jacoco_lines(jacoco_path)
    total = sum(f['services'] for f in files)
    called = sum(f['called'] for f in files)
    code = sum(f['code'] for f in files)
    code_hit = sum(f['code_hit'] for f in files)
    lines = sum(m + c for m, c in groovy.values())
    lines_hit = sum(c for _, c in groovy.values())
    return {
        'files': files,
        'total_services': total,
        'called_services': called,
        'percent': round(100 * called / total, 1) if total else 0.0,
        'code': code,
        'code_hit': code_hit,
        'code_percent': round(100 * code_hit / code, 1) if code else 0.0,
        'scripts': scripts,
        'groovy': [{'file': s, 'lines': m + c, 'hit': c} for s, (m, c) in sorted(groovy.items())],
        'groovy_lines': lines,
        'groovy_hit': lines_hit,
        'groovy_percent': round(100 * lines_hit / lines, 1) if lines else 0.0,
    }


def pct(hit, total):
    return round(100 * hit / total, 1) if total else 0.0


def markdown(data):
    out = [f"Services called: {data['called_services']}/{data['total_services']} "
           f"({data['percent']}%), code blocks run in the called services: "
           f"{data['code_percent']}% ({data['code_hit']}/{data['code']}), "
           f"src/main Groovy lines: {data['groovy_percent']}% "
           f"({data['groovy_hit']}/{data['groovy_lines']})", '',
           '| Service file | Called | Services | Code |', '|---|---:|---:|---:|']
    for f in sorted(data['files'], key=lambda f: f['file']):
        code = f"{pct(f['code_hit'], f['code'])}%" if f['code'] else ''
        out.append(f"| {f['file']} | {pct(f['called'], f['services'])}% | "
                   f"{f['called']}/{f['services']} | {code} |")
    return '\n'.join(out) + '\n'


GOOD, FAIR = 85, 70  # percent: green from GOOD, yellow from FAIR, red below


def terminal(data, color=True):
    """Aligned report per service file, with bars and coloured percentages."""
    def paint(text, code):
        return f'\033[{code}m{text}\033[0m' if color else text

    def percent_text(p):
        code = '32' if p >= GOOD else '33' if p >= FAIR else '31'
        return paint(f'{p:5.1f}%', code)

    def bar(p, width=20):
        filled = round(p / 100 * width)
        return paint('█' * filled, '32' if p >= GOOD else '33' if p >= FAIR else '31') + \
            paint('░' * (width - filled), '2')

    width = max(len(f['file']) for f in data['files'] + data['scripts'])
    out = ['', paint('Backend service coverage', '1'),
           f"{data['called_services']}/{data['total_services']} services called "
           f"({percent_text(data['percent']).strip()}), "
           f"{percent_text(data['code_percent']).strip()} of their code blocks ran, "
           f"src/main Groovy lines {percent_text(data['groovy_percent']).strip()}", '',
           f"{'service file'.ljust(width)}  {'called':>6}  {'':20}  {'':>9}  code"]
    for f in sorted(data['files'], key=lambda f: f['file']):
        p = pct(f['called'], f['services'])
        code = percent_text(pct(f['code_hit'], f['code'])) if f['code'] else ''
        out.append(f"{f['file'].ljust(width)}  {percent_text(p)}  {bar(p)}  "
                   f"{f['called']:>4}/{f['services']:<4}  {code}")
    out += ['', paint('Scripts (code blocks)', '1')]
    for g in data['scripts']:
        p = pct(g['code_hit'], g['code'])
        out.append(f"{g['file'].ljust(width)}  {percent_text(p)}  {bar(p)}  "
                   f"{g['code_hit']:>4}/{g['code']:<4}" if g['code'] else
                   f"{g['file'].ljust(width)}  {paint('not run', '31')}")
    if data['groovy']:
        out += ['', paint('src/main Groovy (lines)', '1')]
        for g in data['groovy']:
            p = pct(g['hit'], g['lines'])
            out.append(f"{g['file'].ljust(width)}  {percent_text(p)}  {bar(p)}  "
                       f"{g['hit']:>4}/{g['lines']:<4}")
    out.append(f"Green from {GOOD}%, yellow from {FAIR}%. Uncalled services: --json; "
               'JaCoCo detail: build/reports/jacoco/test/html/index.html')
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
