/*
 * OKF (Open Knowledge Format v0.1) bundle exporter.
 * Called from growerp.100.OkfServices100.export#OkfBundle.
 * Context in: wikiSpaceId, rootPageLocation, packagePrefixes, includeViewEntities, baseUrl
 * Context out: outputPath, entityCount
 *
 * Writes one markdown file (YAML frontmatter + # Schema + # Relationships) per entity,
 * plus index.md / log.md / datasets pages, via the ResourceReference API so both
 * file and dbresource WikiSpace roots work. Ensures a WikiPage row with
 * publishedVersionName per page - required by get#PublishedWikiPageText.
 */

import org.moqui.impl.entity.EntityDefinition
import org.moqui.impl.entity.FieldInfo
import org.moqui.impl.entity.EntityJavaUtil.RelationshipInfo

def efi = ec.entity
def logger = ec.logger

// bundle dir = rootPageLocation minus the .md extension (wiki convention: root page
// file <name>.md, child pages under directory <name>/)
String rootLoc = (String) rootPageLocation
String bundleDirLoc = rootLoc.endsWith('.md') ? rootLoc.substring(0, rootLoc.length() - 3) : rootLoc

List<String> prefixes = ((String) packagePrefixes).split(',').collect { it.trim() }.findAll { it }
boolean includeViews = includeViewEntities as boolean
String nowIso = java.time.Instant.now().toString()

// ---- collect entity definitions in scope ----
List<EntityDefinition> edList = []
for (String name in efi.getAllEntityNames()) {
    if (!prefixes.any { name.startsWith(it) }) continue
    EntityDefinition ed
    try { ed = efi.getEntityDefinition(name) } catch (Exception e) {
        logger.warn("OKF export: skipping ${name}: ${e.message}"); continue }
    if (ed == null) continue
    if (ed.isViewEntity && !includeViews) continue
    edList.add(ed)
}
edList.sort { it.getEntityName() }

// filename per entity: short name, full name on short-name collision
Map<String, List<EntityDefinition>> byShort = edList.groupBy { it.getEntityName() }
Map<String, String> fileBaseByFullName = [:]
for (entry in byShort) {
    if (entry.value.size() == 1) {
        fileBaseByFullName.put(entry.value[0].getFullEntityName(), entry.key)
    } else {
        for (ed in entry.value) fileBaseByFullName.put(ed.getFullEntityName(), ed.getFullEntityName())
    }
}

def yq = { String s ->
    if (s == null) return '""'
    String oneLine = s.replace('\\', '\\\\').replace('"', '\\"').replaceAll(/\s+/, ' ').trim()
    return '"' + oneLine + '"'
}
def descriptionOf = { EntityDefinition ed ->
    String d = ed.getEntityNode().first("description")?.getText()
    if (!d) d = ed.getPrettyName(null, null)
    return d?.replaceAll(/\s+/, ' ')?.trim()
}

// ---- write helper: file content via ResourceReference, plus WikiPage row ----
String spaceId = (String) wikiSpaceId
def writePage = { String relPath, String text ->
    // relPath without .md, relative to bundle dir; null = space root page file
    String loc = relPath == null ? rootLoc : (bundleDirLoc + '/' + relPath + '.md')
    def ref = ec.resource.getLocationReference(loc)
    ref.putText(text)

    String pagePath = relPath // null for root page
    def existing = ec.entity.find("moqui.resource.wiki.WikiPage")
            .condition("wikiSpaceId", spaceId).condition("pagePath", pagePath).one()
    if (existing == null) {
        ec.entity.makeValue("moqui.resource.wiki.WikiPage")
                .setAll([wikiSpaceId:spaceId, pagePath:pagePath, publishedVersionName:'1',
                         createdByUserId:ec.user.userId])
                .setSequencedIdPrimary().create()
    } else if (!existing.publishedVersionName) {
        existing.publishedVersionName = '1'
        existing.update()
    }
}

// ---- per-entity concept pages ----
int count = 0
List<Map> tableIndexEntries = []
for (EntityDefinition ed in edList) {
    String fullName = ed.getFullEntityName()
    String shortName = ed.getEntityName()
    String fileBase = fileBaseByFullName.get(fullName)
    String desc = descriptionOf(ed)
    // tags = package segments, e.g. mantle.order.OrderHeader -> [mantle, order]
    List<String> tags = fullName.tokenize('.')
    tags = tags.size() > 1 ? tags[0..-2] : []

    StringBuilder sb = new StringBuilder()
    sb.append('---\n')
    sb.append('type: Moqui Entity\n')
    sb.append('title: ').append(shortName).append('\n')
    sb.append('description: ').append(yq(desc)).append('\n')
    sb.append('resource: ').append(baseUrl).append('/rest/e1/').append(fullName).append('\n')
    sb.append('tags: [').append(tags.join(', ')).append(']\n')
    sb.append('timestamp: ').append(nowIso).append('\n')
    sb.append('---\n\n')

    sb.append('# ').append(shortName).append('\n\n')
    if (desc) sb.append(desc).append('\n\n')
    sb.append('Full entity name: `').append(fullName).append('`\n\n')

    sb.append('# Schema\n\n')
    sb.append('| Column | Type | PK | Description |\n')
    sb.append('|--------|------|----|-------------|\n')
    for (String fn in ed.getAllFieldNames()) {
        FieldInfo fi = ed.getFieldInfo(fn)
        if (fi == null) continue
        String fDesc = fi.fieldNode?.first("description")?.getText()?.replaceAll(/\s+/, ' ')?.trim() ?: ''
        fDesc = fDesc.replace('|', '\\|')
        sb.append('| `').append(fi.name).append('` | ').append(fi.type ?: '')
        sb.append(' | ').append(fi.isPk ? 'Y' : '').append(' | ').append(fDesc).append(' |\n')
    }
    sb.append('\n')

    List<RelationshipInfo> relInfoList = ed.getRelationshipsInfo(false)
    if (relInfoList) {
        sb.append('# Relationships\n\n')
        for (RelationshipInfo ri in relInfoList) {
            String relFileBase = fileBaseByFullName.get(ri.relatedEntityName)
            String relShort = ri.relatedEntityName.contains('.') ?
                    ri.relatedEntityName.substring(ri.relatedEntityName.lastIndexOf('.') + 1) : ri.relatedEntityName
            String label = ri.title ? (ri.title + ' ' + relShort) : relShort
            // relative sibling link: the reference-impl visualizer and Google's sample
            // bundles use relative links only (absolute /-links are not followed)
            String target = relFileBase != null ?
                    ('[' + label + '](' + relFileBase + '.md)') : ('`' + ri.relatedEntityName + '`')
            String via = ri.keyMap ? (' via `' + ri.keyMap.keySet().join('`, `') + '`') : ''
            sb.append('- ').append(ri.type).append(' ').append(target).append(via).append('\n')
        }
        sb.append('\n')
    }

    // conventional source-list heading used by the OKF reference bundles
    sb.append('# Citations\n\n')
    sb.append('- ').append(baseUrl).append('/rest/e1/').append(fullName).append('\n')

    writePage('tables/' + fileBase, sb.toString())
    tableIndexEntries.add([fileBase: fileBase, title: shortName, desc: desc ?: ''])
    count++
}

// ---- tables/index.md ----
StringBuilder ti = new StringBuilder()
ti.append('# Tables\n\n')
for (Map e in tableIndexEntries.sort { it.fileBase }) {
    ti.append('* [').append(e.title).append('](').append(e.fileBase).append('.md) - ').append(e.desc).append('\n')
}
writePage('tables/index', ti.toString())

// ---- datasets/growerp.md + datasets/index.md ----
String datasetDesc = 'The GrowERP multi-company ERP data model: runtime Moqui entity definitions (mantle + growerp).'
StringBuilder ds = new StringBuilder()
ds.append('---\n')
ds.append('type: Dataset\n')
ds.append('title: GrowERP Data Model\n')
ds.append('description: ').append(yq(datasetDesc)).append('\n')
ds.append('tags: [growerp, mantle]\n')
ds.append('timestamp: ').append(nowIso).append('\n')
ds.append('---\n\n')
ds.append('# GrowERP Data Model\n\n')
ds.append(datasetDesc).append('\n\n')
ds.append('## Tables\n\n')
for (Map e in tableIndexEntries.sort { it.fileBase }) {
    ds.append('- [').append(e.title).append('](../tables/').append(e.fileBase).append('.md)\n')
}
writePage('datasets/growerp', ds.toString())

StringBuilder di = new StringBuilder()
di.append('# Datasets\n\n')
di.append('* [GrowERP Data Model](growerp.md) - ').append(datasetDesc).append('\n')
writePage('datasets/index', di.toString())

// ---- bundle root index.md (only index allowed frontmatter: okf_version) + root wiki page ----
StringBuilder ri = new StringBuilder()
ri.append('---\n')
ri.append('okf_version: "0.1"\n')
ri.append('---\n\n')
ri.append('# Datasets\n\n')
ri.append('* [GrowERP Data Model](datasets/growerp.md) - ').append(datasetDesc).append('\n\n')
ri.append('# Tables\n\n')
ri.append('* [Tables Index](tables/index.md) - All ').append(count).append(' entity concepts of the GrowERP data model.\n')
String rootIndexText = ri.toString()
writePage('index', rootIndexText)
writePage(null, rootIndexText) // wiki space root page file (<bundleDir>.md)

// ---- log.md (append a run entry) ----
String logLoc = bundleDirLoc + '/log.md'
String prevLog = null
try { prevLog = ec.resource.getLocationReference(logLoc).getText() } catch (Exception e) { /* first run */ }
StringBuilder lg = new StringBuilder()
if (prevLog) { lg.append(prevLog); if (!prevLog.endsWith('\n')) lg.append('\n') }
else lg.append('# Log\n\n')
lg.append('* ').append(nowIso).append(' - exported ').append(count)
lg.append(' entities (prefixes: ').append(prefixes.join(', ')).append(') by ').append(ec.user.username ?: 'system').append('\n')
writePage('log', lg.toString())

outputPath = bundleDirLoc
entityCount = count
logger.info("OKF export: wrote ${count} entity pages to ${bundleDirLoc} (wikiSpaceId=${spaceId})")
