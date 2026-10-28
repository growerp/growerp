#!/usr/bin/env python3
"""Scan the GrowERP programs for the entities they use and classify them for the
owner data backup / transfer (OwnerDataServices100).

Starting from every service and Groovy file of the GrowERP components, it follows
service calls (and the service/entity ECAs they trigger) into mantle and moqui,
collecting each entity read or written on the way. Each used entity is classified:

  tenant    holds owner data: has an ownerPartyId field or a type="one" relationship
            chain to mantle.party.Party; exported and imported with new ids
  global    seed / configuration shared by all owners (types, enums, status, geo, ...),
            present on every system, not exported
  excluded  owner related but not worth transferring (logs, history, sessions, jobs)

Writes backend/service/ownerDataEntities.json (read by OwnerDataTransfer.groovy). With --check it only compares the scan
with that file and fails when an entity is used that the file does not classify.

Run from the repo root (moqui must be set up, see setup-backend.sh):
    python3 backend/ci/owner_data_entities.py [--check]
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
COMPONENTS = os.path.join(ROOT, 'moqui', 'runtime', 'component')
FRAMEWORK = os.path.join(ROOT, 'moqui', 'framework')
OUT = os.path.join(ROOT, 'backend', 'service', 'ownerDataEntities.json')
# components whose code is the GrowERP program
GROWERP_COMPONENTS = ['growerp', 'moqui-adk', 'moqui-mcp', 'PopRestStore', 'mantle-stripe']

# owner related entities that are not transferred: activity logs, history, sessions,
# caches and job state, all rebuilt or meaningless on another system
EXCLUDED_PATTERNS = [r'History$', r'Hit$', r'HitBin$', r'Log$', r'LogEntry$', r'Visit$',
                     r'^moqui\.server\.', r'^moqui\.service\.job\.', r'Session$', r'Sessions?Message',
                     r'^moqui\.security\.UserLoginKey$', r'^moqui\.security\.UserPasswordHistory$',
                     r'^moqui\.security\.UserLoginHistory$', r'^moqui\.entity\.document\.',
                     r'^moqui\.entity\.feed\.', r'^moqui\.entity\.EntityAuditLog$',
                     r'^moqui\.resource\.DbResource', r'^moqui\.resource\.wiki\.WikiPageHistory$',
                     r'^growerp\.general\.OwnerDataTransfer$', r'^moqui\.service\.message\.',
                     r'^moqui\.adk\.AdkKnowledgeImport$', r'^moqui\.adk\.AdkAgentRun',
                     r'^moqui\.adk\.AdkKnowledgeChunk$']
# entities without owner link whose rows a tenant creates and references (its own GL
# accounts): exported when a selected row points at them, also listed under tenant
PULL_IN = ['mantle.ledger.account.GlAccount', 'moqui.resource.wiki.WikiSpace']
# entities keyed by the owner's partyId without a relationship (emailServerId = ownerPartyId)
OWNER_KEYED = {'moqui.basic.email.EmailServer': 'emailServerId'}
# DbResource rows are transferred as files (files/ in the zip), see OwnerDataTransfer.groovy;
# SequenceValueItem rows '<owner>-<name>' keep the owner's pseudoId sequences going
SPECIAL = {'moqui.entity.SequenceValueItem': 'owner sequences <ownerPartyId>-<name>'}


def xml_files(base, sub):
    for dirpath, _, files in os.walk(os.path.join(base, sub), followlinks=True):
        if '/build/' in dirpath + '/':
            continue
        for f in files:
            if f.endswith('.xml'):
                yield os.path.join(dirpath, f)


def component_dirs():
    yield 'framework', FRAMEWORK
    for name in sorted(os.listdir(COMPONENTS)):
        path = os.path.join(COMPONENTS, name)
        if os.path.isdir(path):
            yield name, path


def parse(path):
    try:
        return ET.parse(path).getroot()
    except ET.ParseError:
        return None


# ---------------------------------------------------------------- entity definitions
def load_entities():
    entities, views, extends = {}, set(), []
    for _, comp in component_dirs():
        for path in xml_files(comp, 'entity'):
            root = parse(path)
            if root is None:
                continue
            for el in root:
                tag = el.tag
                if tag == 'entity':
                    full = el.get('package') + '.' + el.get('entity-name')
                    entities[full] = {'fields': {}, 'pks': [], 'rels': []}
                    add_members(entities[full], el)
                elif tag == 'view-entity':
                    views.add(el.get('package') + '.' + el.get('entity-name'))
                elif tag == 'extend-entity':
                    extends.append(el)
    short = {}
    for full in list(entities) + list(views):
        short.setdefault(full.rsplit('.', 1)[1], []).append(full)
    for el in extends:
        name = el.get('entity-name')
        full = (el.get('package') + '.' + name) if el.get('package') else resolve(name, short)
        if full in entities:
            add_members(entities[full], el)
    for e in entities.values():
        for r in e['rels']:
            r['related'] = resolve(r['related'], short)
    return entities, views, short


def add_members(e, el):
    for f in el.findall('field'):
        e['fields'][f.get('name')] = f.get('type')
        if f.get('is-pk') == 'true':
            e['pks'].append(f.get('name'))
    for r in el.findall('relationship'):
        if r.get('type') not in ('one', 'one-nofk'):
            continue
        keys = {k.get('field-name'): k.get('related') or k.get('field-name') for k in r.findall('key-map')}
        e['rels'].append({'related': r.get('related') or r.get('related-entity-name'),
                          'title': r.get('title'), 'keys': keys})


def resolve(name, short):
    if not name:
        return None
    if '.' in name:
        return name
    full = short.get(name)
    return full[0] if full and len(full) == 1 else (full[0] if full else name)


# ---------------------------------------------------------------- services and code
ENTITY_ATTR = re.compile(r'entity-name="([A-Za-z0-9_.]+)"')
SERVICE_CALL = re.compile(r'(?:service-call\s+name|name\()\s*=?\s*["\']([A-Za-z0-9_.]+#[A-Za-z0-9_.]+)["\']')
GROOVY_ENTITY = re.compile(r'(?:find|makeValue|makeFind|getEntityDefinition|isEntityDefined)\(\s*["\']([A-Za-z0-9_.]+)["\']')
ENTITY_AUTO = re.compile(r'^(create|update|store|delete)#([A-Za-z0-9_.]+)$')


def code_refs(text):
    ents = set(ENTITY_ATTR.findall(text)) | set(GROOVY_ENTITY.findall(text))
    calls = set(SERVICE_CALL.findall(text))
    calls |= set(re.findall(r'name\(\s*["\']([A-Za-z0-9_.]+#[A-Za-z0-9_.]+)["\']', text))
    return ents, calls


def load_services():
    """service name -> (entities, calls); ECA trigger -> calls; GrowERP roots."""
    services, triggers, roots = {}, {}, []
    for comp_name, comp in component_dirs():
        service_dir = os.path.join(comp, 'service')
        for path in xml_files(comp, 'service') if os.path.isdir(service_dir) else []:
            rel = os.path.relpath(path, service_dir)[:-4].replace(os.sep, '.')
            root = parse(path)
            if root is None:
                continue
            if path.endswith('.secas.xml'):
                for seca in root.findall('seca'):
                    _, calls = code_refs(ET.tostring(seca, encoding='unicode'))
                    triggers.setdefault(seca.get('service'), set()).update(calls)
                continue
            for s in root.findall('service'):
                noun = s.get('noun')
                name = rel + '.' + s.get('verb') + ('#' + noun if noun else '')
                text = ET.tostring(s, encoding='unicode')
                ents, calls = code_refs(text)
                if s.get('type') in ('script',) and s.get('location'):
                    loc = s.get('location')
                    if loc.startswith('component://'):
                        p = os.path.join(COMPONENTS, loc[len('component://'):])
                        if os.path.exists(p):
                            more_e, more_c = code_refs(open(p, encoding='utf-8').read())
                            ents |= more_e
                            calls |= more_c
                if s.get('type') == 'entity-auto' or (s.get('type') is None and s.find('actions') is None and noun):
                    ents.add(noun)
                services[name] = (ents, calls)
                if comp_name in GROWERP_COMPONENTS:
                    roots.append(name)
        for path in xml_files(comp, 'entity'):
            if not path.endswith('.eecas.xml'):
                continue
            root = parse(path)
            for eeca in root.findall('eeca') if root is not None else []:
                _, calls = code_refs(ET.tostring(eeca, encoding='unicode'))
                triggers.setdefault('entity:' + eeca.get('entity'), set()).update(calls)
    groovy = set()
    for comp_name in GROWERP_COMPONENTS:
        base = os.path.join(COMPONENTS, comp_name)
        for dirpath, _, files in os.walk(base, followlinks=True):
            if '/build/' in dirpath + '/' or '/test/' in dirpath + '/':
                continue
            for f in files:
                if f.endswith(('.groovy', '.xml', '.ftl')) and '/data' not in dirpath:
                    groovy.add(os.path.join(dirpath, f))
    return services, triggers, roots, groovy


def used_entities(entities, short):
    services, triggers, roots, files = load_services()
    used, seen = set(), set()
    todo = list(roots)
    for path in files:
        ents, calls = code_refs(open(path, encoding='utf-8', errors='ignore').read())
        used |= ents
        todo += calls
    while todo:
        name = todo.pop()
        if name in seen:
            continue
        seen.add(name)
        m = ENTITY_AUTO.match(name)
        if m and name not in services:
            used.add(m.group(2))
            todo += triggers.get('entity:' + m.group(2), ())
            continue
        if name not in services:
            # moqui-adk style short service names (AdkServices100.get#X)
            match = [s for s in services if s.endswith('.' + name) or s == name]
            if len(match) != 1:
                continue
            name = match[0]
            if name in seen:
                continue
            seen.add(name)
        ents, calls = services[name]
        used |= ents
        todo += calls
        todo += triggers.get(name, ())
        for e in ents:
            todo += triggers.get('entity:' + e, ())
    resolved = set()
    for e in used:
        full = resolve(e, short)
        if full in entities:
            resolved.add(full)
    return resolved


# ---------------------------------------------------------------- classification
def add_implicit_relations(entities):
    """id fields without a relationship that still point at a record, by name:
    partyId / *PartyId -> Party, userId / *UserId -> UserAccount, <pk>Id -> the entity
    with that single primary key. Kept per entity in implicit (field -> entity)."""
    by_pk = {}
    for n, e in entities.items():
        if len(e['pks']) == 1:
            by_pk.setdefault(e['pks'][0], []).append(n)
    for n, e in entities.items():
        rel_fields = set()
        for r in e['rels']:
            keys = r['keys'] or {k: k for k in entities.get(r['related'], {}).get('pks', [])}
            rel_fields |= set(keys)
        e['implicit'] = {}
        for f, t in e['fields'].items():
            if f in rel_fields or not t or not t.startswith('id') or f == 'pseudoId' or f.endswith('SeqId'):
                continue
            if len(e['pks']) == 1 and f == e['pks'][0]:
                continue
            if f == 'partyId' or f.endswith('PartyId'):
                target = 'mantle.party.Party'
            elif f == 'userId' or f.endswith('UserId'):
                target = 'moqui.security.UserAccount'
            elif f in by_pk and len(by_pk[f]) == 1 and by_pk[f][0] != n:
                target = by_pk[f][0]
            else:
                continue
            e['implicit'][f] = target
            e['rels'].append({'related': target, 'title': None, 'keys': {f: entities[target]['pks'][0]}})


def classify(entities, used):
    tenant = {n for n, e in entities.items() if 'ownerPartyId' in e['fields']}
    tenant.add('mantle.party.Party')
    changed = True
    while changed:
        changed = False
        for n, e in entities.items():
            if n not in tenant and any(r['related'] in tenant for r in e['rels']):
                tenant.add(n)
                changed = True
    result = {'tenant': [], 'global': [], 'excluded': []}
    for n in sorted(set(used) | set(SPECIAL) | set(PULL_IN) | set(OWNER_KEYED)):
        if n in SPECIAL or n in PULL_IN or n in OWNER_KEYED:
            result['tenant'].append(n)
        elif any(re.search(p, n) for p in EXCLUDED_PATTERNS):
            result['excluded'].append(n)
        elif n in tenant:
            result['tenant'].append(n)
        else:
            result['global'].append(n)
    return result


def id_fields_without_relation(entities, tenant):
    """*Id fields of tenant entities with no relationship: review for overrides."""
    out = {}
    for n in tenant:
        e = entities[n]
        rel_fields = {f for r in e['rels'] for f in (r['keys'] or {k: k for k in entities.get(r['related'], {}).get('pks', [])})}
        loose = [f for f, t in e['fields'].items()
                 if f.endswith('Id') and t and t.startswith('id') and f not in rel_fields
                 and not (len(e['pks']) == 1 and f in e['pks'])]
        if loose:
            out[n] = sorted(loose)
    return out


def main():
    entities, views, short = load_entities()
    add_implicit_relations(entities)
    used = used_entities(entities, short)
    result = classify(entities, used)
    existing = json.load(open(OUT)) if os.path.exists(OUT) else {}
    if '--check' in sys.argv:
        known = set(existing.get('tenant', [])) | set(existing.get('global', [])) | set(existing.get('excluded', []))
        missing = sorted(set(result['tenant'] + result['global'] + result['excluded']) - known)
        if missing:
            print('Entities used by GrowERP but not classified in %s:' % os.path.relpath(OUT, ROOT))
            for m in missing:
                print('  ' + m)
            print('Rerun without --check and review the result.')
            sys.exit(1)
        print('ownerDataEntities.json covers all %d used entities' % len(known))
        return
    # manual classification in the existing file wins over the automatic one
    for key in ('tenant', 'global', 'excluded'):
        for n in existing.get(key, []):
            for other in ('tenant', 'global', 'excluded'):
                if n in result[other] and other != key:
                    result[other].remove(n)
                    result[key].append(n)
    for key in result:
        result[key] = sorted(set(result[key]))
    out = {'description': existing.get('description', 'Entities used by GrowERP, classified for the owner '
                                       'data backup/transfer. Generated by backend/ci/owner_data_entities.py; '
                                       'moving an entity to another list by hand is kept on the next run.'),
           'tenant': result['tenant'], 'global': result['global'], 'excluded': result['excluded'],
           'pullIn': PULL_IN, 'ownerKeyed': OWNER_KEYED,
           'implicitRelations': {n: entities[n]['implicit'] for n in result['tenant'] if entities[n]['implicit']},
           'fieldOverrides': existing.get('fieldOverrides', {})}
    with open(OUT, 'w') as f:
        json.dump(out, f, indent=2)
        f.write('\n')
    print('tenant %d, global %d, excluded %d -> %s' % (len(out['tenant']), len(out['global']),
                                                        len(out['excluded']), os.path.relpath(OUT, ROOT)))
    loose = id_fields_without_relation(entities, out['tenant'])
    if '--loose' in sys.argv:
        for n, fields in sorted(loose.items()):
            print('  %s: %s' % (n, ', '.join(fields)))


if __name__ == '__main__':
    main()
