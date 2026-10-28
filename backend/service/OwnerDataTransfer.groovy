/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.moqui.impl.entity.EntityDefinition
import org.moqui.impl.entity.EntityJavaUtil
import org.moqui.entity.EntityCondition
import org.moqui.entity.EntityListIterator
import org.xml.sax.Attributes
import org.xml.sax.helpers.DefaultHandler

import javax.xml.parsers.SAXParserFactory

import java.util.regex.Matcher
import java.util.regex.Pattern
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/* Download and upload all data of an owner (tenant), for a backup or to move it to
   another system that has the seed data and the GROWERP owner already loaded.

   Which entities: service/ownerDataEntities.json, made by ci/owner_data_entities.py
   from the entities the GrowERP programs use.

   Export: starting from the owner's parties, every row of a tenant entity that points
   (relationship or implicit id field) at an already selected row is taken, until
   nothing new is found. Rows that also point at another owner's data (the owner's
   GROWERP subscription invoices, ...) are left out. DbResource files the rows refer to
   (dbresource://...) go into the zip under files/.

   Import: every row gets a new id, the references are rewritten to those new ids, so
   the data becomes a new owner next to what is there already. Ids holding the owner's
   id (AGENT_<owner>, <owner>-<sequence>, emailServerId) keep that form with the new owner.

   The records are in the standard Moqui data format (entity-facade-xml, as written by
   EntityValue.writeXmlText), the upload is loaded by the Moqui data loader after the ids
   are changed. Zip layout: manifest.json, entities/<entityName>.xml, files/<path>.
   Both ways stream: in memory are only the keys and references of the records (export)
   and the old -> new ids (import), so the size of the data is limited by disk, not memory.
 */
class OwnerDataTransfer {
    static final int FORMAT_VERSION = 1
    static final String CONFIG = 'component://growerp/service/ownerDataEntities.json'
    static final String PARTY = 'mantle.party.Party'
    static final String SEQUENCE = 'moqui.entity.SequenceValueItem'
    static final Pattern SEQUENCED_ID = ~/\d{6,}/
    static final Pattern DB_LOCATION = ~/dbresource:\/\/[^\s"'<>()\\]+/
    /** records per data file loaded, and between clearing the operation history */
    static final int BATCH = 5000

    ExecutionContext ec
    Map config
    /** entity -> [field -> entity the field points to (the entity with that single pk)] */
    Map<String, Map<String, String>> targets = [:]
    /** entities whose single pk is their own id, a new one is made on import */
    Set<String> ownIds = [] as Set
    /** entity -> references to a tenant entity with a composite pk: [[entity, [field: related field]]] */
    Map<String, List<List>> compositeRefs = [:]
    /** entity -> tenant entities it refers to directly, for the load order */
    Map<String, Set<String>> parents = [:]
    /** export: rows left out because they also belong to another owner, 'entity pk: field' */
    List<String> leftOut = []
    Set<String> tenant, pullIn
    Map<String, String> ownerKeyed
    Closure progress

    OwnerDataTransfer(ExecutionContext ec, Closure progress = null) {
        this.ec = ec
        this.progress = progress ?: { String m -> }
        config = (Map) new JsonSlurper().parseText(ec.resource.getLocationText(CONFIG, false))
        pullIn = (config.pullIn ?: []) as Set
        ownerKeyed = (Map) (config.ownerKeyed ?: [:])
        tenant = ((config.tenant ?: []) as List<String>).findAll { ec.entity.isEntityDefined(it) } as Set
        buildTargets()
        // records only reached through a reference (ContactMech, GlAccount): taken when pointed at
        for (String name in ownIds) {
            if (ed(name).isField('ownerPartyId') || ownerKeyed[name] || name == SEQUENCE) continue
            if (!targets[name].any { f, t -> t != name }) pullIn.add(name)
        }
    }

    EntityDefinition ed(String name) { return (EntityDefinition) ec.entity.getEntityDefinition(name) }

    /* field -> target entity: follow type one relationships to an entity with a single pk,
       through composite keys (OrderItem.orderId -> OrderPart.orderId -> OrderHeader). */
    private void buildTargets() {
        Map<String, Map<String, String>> implicit = (Map) (config.implicitRelations ?: [:])
        Map<String, Map<String, String>> overrides = (Map) (config.fieldOverrides ?: [:])
        // direct pointers: [entity: [field: [relatedEntity, relatedField]]]
        Map<String, Map<String, List<String>>> direct = [:]
        for (String name in tenant) {
            EntityDefinition entityDef = ed(name)
            Map<String, List<String>> fields = [:]
            List<String> pkList = entityDef.getPkFieldNames()
            for (EntityJavaUtil.RelationshipInfo rel in entityDef.getRelationshipsInfo(false)) {
                if (!rel.isTypeOne || !tenant.contains(rel.relatedEntityName)) continue
                // Party -> Person/Organization: a one-nofk on the own id is the reverse of a subtype
                if (!rel.isFk && pkList.size() == 1 && rel.keyMap.containsKey(pkList[0])) continue
                rel.keyMap.each { String f, String rf -> if (!fields.containsKey(f)) fields[f] = [rel.relatedEntityName, rf] }
            }
            (implicit[name] ?: [:]).each { String f, String t ->
                if (!fields.containsKey(f) && tenant.contains(t)) fields[f] = [t, ed(t).getPkFieldNames()[0]]
            }
            (overrides[name] ?: [:]).each { String f, String t -> if (tenant.contains(t)) fields[f] = [t, ed(t).getPkFieldNames()[0]] }
            direct[name] = fields
            parents[name] = fields.values().collect { it[0] } as Set
            compositeRefs[name] = entityDef.getRelationshipsInfo(false).findAll { rel ->
                rel.isTypeOne && tenant.contains(rel.relatedEntityName) && ed(rel.relatedEntityName).getPkFieldNames().size() > 1 &&
                        rel.keyMap.values().toSet() == ed(rel.relatedEntityName).getPkFieldNames().toSet()
            }.collect { [it.relatedEntityName, it.keyMap] }
            List<String> pks = entityDef.getPkFieldNames()
            if (pks.size() == 1 && !fields.containsKey(pks[0]) && entityDef.getFieldInfo(pks[0]).type?.startsWith('id'))
                ownIds.add(name)
        }
        for (String name in tenant) {
            Map<String, String> resolved = [:]
            direct[name].each { String f, List<String> to ->
                String t = resolve(direct, to[0], to[1], 0)
                if (t) resolved[f] = t
            }
            if (ownIds.contains(name)) resolved[ed(name).getPkFieldNames()[0]] = name
            targets[name] = resolved
        }
    }

    private String resolve(Map<String, Map<String, List<String>>> direct, String entity, String field, int depth) {
        if (depth > 6) return null
        if (ownIds.contains(entity) && ed(entity).getPkFieldNames()[0] == field) return entity
        List<String> next = direct[entity]?.get(field)
        return next ? resolve(direct, next[0], next[1], depth + 1) : null
    }

    // ------------------------------------------------------------------------ export

    /** Write the owner's data as a zip to the file; returns [counts: [entity: rows], files: n, leftOut: [...]].
        Only keys and references are held in memory, the records are streamed into the zip. */
    Map export(String ownerPartyId, File zipFile) {
        Map<String, Map<String, Map>> rows = select(ownerPartyId)
        Map counts = rows.collectEntries { k, v -> [k, v.size()] }.findAll { it.value }
        Set<String> references = [] as Set
        int files = 0, written = 0
        int total = counts.values().sum() as Integer ?: 0
        zipFile.parentFile.mkdirs()
        zipFile.withOutputStream { OutputStream os ->
            ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(os))
            Writer writer = new OutputStreamWriter(zos, 'UTF-8')
            rows.each { String entity, Map<String, Map> byPk ->
                if (!byPk) return
                zos.putNextEntry(new ZipEntry("entities/${entity}.xml"))
                writer.write('<?xml version="1.0" encoding="UTF-8"?>\n<entity-facade-xml type="ownerData">\n')
                eachRecord(entity, byPk.values()) { EntityValue ev ->
                    ev.writeXmlText(writer, null, 0)
                    ev.values().each { v -> if (v instanceof String && v.contains('dbresource://')) {
                        Matcher m = DB_LOCATION.matcher(v)
                        while (m.find()) references.add(m.group().replaceAll(/\/+$/, ''))
                    } }
                    if (++written % 5000 == 0) progress("Writing data: ${written} of ${total} records")
                }
                writer.write('</entity-facade-xml>\n')
                writer.flush()
                zos.closeEntry()
            }
            for (String location in fileLocations(ownerPartyId, references)) {
                InputStream is = ec.resource.getLocationReference(location).openStream()
                if (is == null) continue
                zos.putNextEntry(new ZipEntry('files/' + location.substring('dbresource://'.length())))
                is.withCloseable { it.transferTo(zos) }
                zos.closeEntry()
                files++
            }
            zos.putNextEntry(new ZipEntry('manifest.json'))
            writer.write(JsonOutput.prettyPrint(JsonOutput.toJson([formatVersion: FORMAT_VERSION,
                    ownerPartyId: ownerPartyId, exportDate: ec.user.nowTimestamp.time,
                    source: System.getProperty('default_host') ?: InetAddress.localHost.hostName,
                    counts: counts, files: files, leftOut: leftOut])))
            writer.flush()
            zos.closeEntry()
            zos.finish()
            zos.flush()
        }
        return [counts: counts, files: files, leftOut: leftOut]
    }

    /** the full records of selected keys, read in chunks */
    private void eachRecord(String entity, Collection<Map> keys, Closure handle) {
        List<String> pks = ed(entity).getPkFieldNames()
        keys.collate(pks.size() == 1 ? 500 : 100).each { List<Map> chunk ->
            def find = find(entity)
            if (pks.size() == 1) find.condition(pks[0], 'in', chunk.collect { it[pks[0]] })
            else find.condition(ec.entity.conditionFactory.makeCondition(chunk.collect { Map key ->
                ec.entity.conditionFactory.makeCondition(key.subMap(pks)) }, EntityCondition.JoinOperator.OR))
            iterate(find, handle)
            forgetHistory()
        }
    }

    private static void iterate(def find, Closure handle) {
        EntityListIterator eli = find.iterator()
        try {
            EntityValue ev
            while ((ev = eli.next()) != null) handle(ev)
        } finally {
            eli.close()
        }
    }

    /** the fields kept in memory per record: the keys and the references */
    private Set<String> keptFields(String entity) {
        Set<String> fields = new LinkedHashSet<>(ed(entity).getPkFieldNames())
        fields.addAll(targets[entity].keySet())
        compositeRefs[entity].each { List ref -> fields.addAll(((Map) ref[1]).keySet()) }
        return fields
    }

    /** entity -> [pk string -> keys and references] of everything belonging to the owner. */
    Map<String, Map<String, Map>> select(String owner) {
        Map<String, Map<String, Map>> rows = [:].withDefault { [:] }
        Map<String, Set<String>> ids = [:].withDefault { [] as Set }
        Map<String, Set<String>> frontier = [:].withDefault { [] as Set }
        Map<String, Set<String>> kept = [:].withDefault { String e -> keptFields(e) }
        Closure add = { String entity, EntityValue ev ->
            Map row = ev.getMap().subMap(kept[entity])
            String key = pkKey(entity, row)
            if (rows[entity].containsKey(key)) return false
            rows[entity][key] = row
            if (ownIds.contains(entity)) {
                String id = row[ed(entity).getPkFieldNames()[0]]
                if (ids[entity].add(id)) frontier[entity].add(id)
            }
            return true
        }
        Closure query = { String entity -> find(entity).selectFields(kept[entity]) }
        // the roots: the owner, its parties, its rows with ownerPartyId, owner keyed rows
        EntityValue ownerParty = find(PARTY).condition('partyId', owner).one()
        if (ownerParty == null) throw new IllegalArgumentException("Owner ${owner} not found")
        add(PARTY, ownerParty)
        for (String entity in tenant) {
            if (pullIn.contains(entity)) continue
            if (ed(entity).isField('ownerPartyId'))
                iterate(query(entity).condition('ownerPartyId', owner)) { add(entity, it) }
            if (ownerKeyed[entity])
                iterate(query(entity).condition((String) ownerKeyed[entity], owner)) { add(entity, it) }
        }
        if (tenant.contains(SEQUENCE)) iterate(query(SEQUENCE).condition('seqName', 'like', owner + '-%')) { add(SEQUENCE, it) }

        int round = 0
        while (frontier.values().any { it }) {
            round++
            Map<String, Set<String>> current = frontier.collectEntries { k, v -> [k, new HashSet<String>(v)] }
            frontier.clear()
            int before = rows.values().sum { it.size() } as int
            for (String entity in tenant) {
                if (pullIn.contains(entity) || entity == SEQUENCE) continue
                List<String> pks = ed(entity).getPkFieldNames()
                targets[entity].each { String field, String target ->
                    if (!current[target]) return
                    // from a pulled in record only its own extension (PostalAddress of a ContactMech)
                    if (pullIn.contains(target) && !(pks.size() == 1 && pks[0] == field)) return
                    if (ownIds.contains(entity) && field == pks[0] && target == entity) return
                    current[target].toList().collate(500).each { List chunk ->
                        iterate(query(entity).condition(field, 'in', chunk)) { add(entity, it) }
                    }
                }
                forgetHistory()
            }
            // the pull in entities (own GL accounts, wiki spaces) the rows point at
            boolean pulled = true
            while (pulled) {
                pulled = false
                rows.collect { k, v -> [k, v.values().toList()] }.each { List pair ->
                    String entity = pair[0]
                    targets[entity].each { String field, String target ->
                        if (!pullIn.contains(target)) return
                        String pk = ed(target).getPkFieldNames()[0]
                        ((List<Map>) pair[1]).collect { it[field] }.findAll { it && !ids[target].contains(it) }
                                .unique().collate(500).each { List chunk ->
                            iterate(query(target).condition(pk, 'in', chunk)) { if (add(target, it)) pulled = true }
                        }
                    }
                }
            }
            int after = rows.values().sum { it.size() } as int
            progress("Selecting data, round ${round}: ${after} records (+${after - before})")
        }
        prune(owner, rows, ids)
        return rows
    }

    /* Leave out rows pointing at data of another owner: a party of another owner, an
       owner itself, or a not selected record with a sequenced id. Repeated, as leaving out
       an order also leaves out its items. */
    private void prune(String owner, Map<String, Map<String, Map>> rows, Map<String, Set<String>> ids) {
        Map<String, Boolean> foreignCache = [:]
        boolean changed = true
        while (changed) {
            changed = false
            rows.each { String entity, Map<String, Map> byPk ->
                Iterator<Map.Entry<String, Map>> it = byPk.entrySet().iterator()
                while (it.hasNext()) {
                    Map row = it.next().value
                    String bad = targets[entity].find { String field, String target ->
                        String v = row[field]
                        v && !ids[target].contains(v) && !pullIn.contains(target) &&
                                foreign(owner, target, v, foreignCache)
                    }?.key
                    // a part of an order left out: its items too
                    if (bad == null) bad = compositeRefs[entity].find { List ref ->
                        Map<String, String> keyMap = (Map) ref[1]
                        Map key = keyMap.collectEntries { f, rf -> [rf, row[f]] }
                        key.values().every { it != null } && !rows[(String) ref[0]].containsKey(pkKey((String) ref[0], key)) &&
                                find((String) ref[0]).condition(key).count() > 0
                    }?.getAt(1)?.keySet()?.join(',')
                    if (bad == null) continue
                    leftOut.add("${entity} ${pkKey(entity, row)}: ${bad}".toString())
                    it.remove()
                    changed = true
                    if (ownIds.contains(entity)) ids[entity].remove(row[ed(entity).getPkFieldNames()[0]])
                }
            }
        }
    }

    private boolean foreign(String owner, String entity, String id, Map<String, Boolean> cache) {
        String key = entity + '|' + id
        if (cache.containsKey(key)) return cache[key]
        boolean result
        if (entity == PARTY) {
            EntityValue p = find(PARTY).condition('partyId', id).one()
            result = p != null && (p.partyTypeEnumId == 'PtyOwner' ||
                    (p.ownerPartyId && p.ownerPartyId != '_NA_' && p.ownerPartyId != owner))
        } else if (ed(entity).isField('ownerPartyId')) {
            EntityValue v = find(entity).condition(ed(entity).getPkFieldNames()[0], id).one()
            result = v != null && v.ownerPartyId && v.ownerPartyId != '_NA_' && v.ownerPartyId != owner
        } else {
            result = SEQUENCED_ID.matcher(id).find()
        }
        cache[key] = result
        return result
    }

    /** the files of the dbresource locations the records refer to, a directory with everything below it. */
    List<String> fileLocations(String owner, Collection<String> references) {
        Set<String> files = [] as Set
        for (String location in references) {
            // the shared default site and the GROWERP site belong to the system
            if (location.startsWith('dbresource://DEFAULT_ROOT') || location.startsWith('dbresource://growerp/')) continue
            if (location.startsWith('dbresource://GROWERP_ROOT') && owner != 'GROWERP') continue
            def ref = ec.resource.getLocationReference(location)
            if (!ref?.getExists()) continue
            collectFiles(ref, files)
        }
        return files.sort()
    }

    private void collectFiles(def ref, Set<String> files) {
        if (ref.isFile()) { files.add(ref.getLocation()); return }
        for (def child in ref.getDirectoryEntries()) collectFiles(child, files)
    }

    private String pkKey(String entity, Map row) {
        return ed(entity).getPkFieldNames().collect { row[it]?.toString() }.join('|')
    }

    private def find(String entity) {
        return ec.entity.find(entity).useCache(false).disableAuthz()
    }

    // ------------------------------------------------------------------------ import

    static Map manifest(ZipFile zip) {
        ZipEntry entry = zip.getEntry('manifest.json')
        return entry ? (Map) new JsonSlurper().parse(zip.getInputStream(entry), 'UTF-8') : null
    }

    /** the entities in the zip: entity name -> zip entry */
    private Map<String, ZipEntry> entityEntries(ZipFile zip) {
        Map<String, ZipEntry> out = [:]
        zip.entries().each { ZipEntry e ->
            if (e.name.startsWith('entities/') && e.name.endsWith('.xml')) {
                String entity = e.name.substring(9, e.name.length() - 4)
                if (tenant.contains(entity)) out[entity] = e
            }
        }
        return out
    }

    /** Stream the records of an entity-facade-xml file, each as field name -> text,
        the way the Moqui loader reads them: attributes and field sub elements. */
    static void eachDataRecord(InputStream is, Closure handle) {
        SAXParserFactory factory = SAXParserFactory.newInstance()
        factory.setNamespaceAware(false)
        factory.newSAXParser().parse(is, new DefaultHandler() {
            int depth = 0
            Map row = null
            String field = null
            StringBuilder text = new StringBuilder()
            @Override void startElement(String uri, String localName, String qName, Attributes attributes) {
                depth++
                if (depth == 2) {
                    row = [:]
                    for (int i = 0; i < attributes.length; i++) row[attributes.getQName(i)] = attributes.getValue(i)
                } else if (depth == 3) {
                    field = qName
                    text.setLength(0)
                }
            }
            @Override void characters(char[] ch, int start, int length) { if (depth == 3) text.append(ch, start, length) }
            @Override void endElement(String uri, String localName, String qName) {
                if (depth == 3) row[field] = text.toString()
                else if (depth == 2) { handle(row); row = null }
                depth--
            }
        })
    }

    private void eachRow(ZipFile zip, ZipEntry entry, Closure handle) {
        zip.getInputStream(entry).withCloseable { InputStream is -> eachDataRecord(new BufferedInputStream(is), handle) }
    }

    /** Conflicts that stop an import: user names and email addresses already in use. */
    List<String> conflicts(ZipFile zip) {
        String oldOwner = manifest(zip).ownerPartyId
        List<String> out = []
        ZipEntry users = zip.getEntry('entities/moqui.security.UserAccount.xml')
        if (users) eachRow(zip, users) { Map ua ->
            String username = ownerToken(ua.username as String, oldOwner, 'X')
            if (username == ua.username && find('moqui.security.UserAccount').condition('username', username).count())
                out.add("user name ${username} exists already".toString())
            else if (ua.emailAddress && find('moqui.security.UserAccount').condition('emailAddress', ua.emailAddress).count())
                out.add("user email ${ua.emailAddress} exists already".toString())
        }
        return out
    }

    /** Load the zip as a new owner; returns [ownerPartyId: new owner, counts: [...], files: n, skipped: [...]]. */
    Map load(ZipFile zip, File workDir) {
        Map manifest = manifest(zip)
        if (!manifest || (manifest.formatVersion as int) > FORMAT_VERSION)
            throw new IllegalArgumentException('This is not a GrowERP owner data file, or from a newer version')
        String oldOwner = manifest.ownerPartyId
        Map<String, ZipEntry> entries = entityEntries(zip)
        List<ZipEntry> fileEntries = zip.entries().toList().findAll { ZipEntry e -> !e.isDirectory() && e.name.startsWith('files/') }

        // first pass: new ids and the dbresource directories referred to
        Map<String, Map<String, String>> idMap = [:].withDefault { [:] }
        String newOwner = newId(PARTY, oldOwner, oldOwner, null)
        idMap[PARTY][oldOwner] = newOwner
        Set<String> tops = fileEntries.collect { it.name.substring(6).split('/')[0] } as Set
        int total = 0
        entries.each { String entity, ZipEntry entry ->
            String pk = ownIds.contains(entity) ? ed(entity).getPkFieldNames()[0] : null
            eachRow(zip, entry) { Map row ->
                total++
                if (pk) {
                    String old = row[pk]
                    if (!idMap[entity].containsKey(old)) idMap[entity][old] = newId(entity, old, oldOwner, newOwner)
                }
                row.values().each { v -> if (v instanceof String && v.contains('dbresource://')) {
                    Matcher m = DB_LOCATION.matcher(v)
                    while (m.find()) { String rest = m.group().substring('dbresource://'.length()); if (rest) tops.add(rest.split('/')[0]) }
                } }
            }
            progress("Reading data: ${total} records")
        }
        Set<String> fileTops = fileEntries.collect { it.name.substring(6).split('/')[0] } as Set
        Map<String, String> roots = fileRoots(tops, fileTops, idMap, oldOwner, newOwner)

        // second pass: rewritten into a standard data file per entity, loaded by the Moqui data loader
        workDir.mkdirs()
        Map counts = [:]
        List<String> skipped = []
        Map<String, Boolean> exists = [:]
        int done = 0
        List<String> order = loadOrder(entries.keySet())
        Set<String> cyclic = cyclic(entries.keySet())
        for (String entity in order) {
            Set<String> pks = ed(entity).getPkFieldNames() as Set
            int n = 0
            Writer writer = null
            File dataFile = null
            // the standard Moqui data loader, a file of BATCH records at a time; dummy records
            // only where references go round (parents load first otherwise), no ECAs
            Closure flush = {
                if (writer == null) return
                writer.write('</entity-facade-xml>\n')
                writer.close()
                writer = null
                ec.entity.makeDataLoader().location(dataFile.toURI().toString()).dummyFks(cyclic.contains(entity))
                        .disableEntityEca(true).disableAuditLog(true).disableDataFeed(true).load([])
                dataFile.delete()
                forgetHistory()
                progress("Loading data: ${done + n} of ${total} records")
            }
            eachRow(zip, entries[entity]) { Map row ->
                Map value = rewrite(entity, row, idMap, roots, oldOwner, newOwner, exists, pks)
                if (value == null) { skipped.add("${entity} ${pkKey(entity, row)}".toString()); return }
                EntityValue ev = ec.entity.makeValue(entity)
                value.each { String f, Object v -> if (ev.isField(f)) ev.setString(f, (String) v) }
                uniquePseudoId(ed(entity), ev)
                if (writer == null) {
                    dataFile = new File(workDir, "${entity}-${n}.xml")
                    writer = dataFile.newWriter('UTF-8')
                    writer.write('<?xml version="1.0" encoding="UTF-8"?>\n<entity-facade-xml type="ownerData">\n')
                }
                ev.writeXmlText(writer, null, 0)
                n++
                if (n % BATCH == 0) flush()
            }
            flush()
            if (n) counts[entity] = n
            done += n
        }
        workDir.delete()
        for (ZipEntry e in fileEntries) {
            zip.getInputStream(e).withCloseable { InputStream is ->
                ec.resource.getLocationReference(relocate('dbresource://' + e.name.substring(6), roots)).putStream(is)
            }
        }
        ec.cache.clearAllCaches()
        return [ownerPartyId: newOwner, counts: counts, files: fileEntries.size(), skipped: skipped]
    }

    private String newId(String entity, String old, String oldOwner, String newOwner) {
        if (newOwner && old == oldOwner) return newOwner
        if (newOwner && hasToken(old, oldOwner)) return ownerToken(old, oldOwner, newOwner)
        EntityValue ev = ec.entity.makeValue(entity)
        ev.setSequencedIdPrimary()
        return ev.get(ed(entity).getPkFieldNames()[0])
    }

    static boolean hasToken(String s, String token) {
        return s != null && Pattern.compile('(?<![A-Za-z0-9])' + Pattern.quote(token) + '(?![A-Za-z0-9])').matcher(s).find()
    }

    static String ownerToken(String s, String oldOwner, String newOwner) {
        if (s == null) return null
        return s.replaceAll('(?<![A-Za-z0-9])' + Pattern.quote(oldOwner) + '(?![A-Za-z0-9])',
                Matcher.quoteReplacement(newOwner))
    }

    /* dbresource top directories: C<company> and <owner>_ROOT style names follow the new
       ids, any other name already present here gets the new owner appended. */
    private Map<String, String> fileRoots(Set<String> tops, Set<String> fileTops, Map<String, Map<String, String>> idMap,
                                          String oldOwner, String newOwner) {
        Map<String, String> roots = [:]
        for (String top in tops) {
            if (top in ['DEFAULT_ROOT', 'GROWERP_ROOT', 'growerp'] && !fileTops.contains(top)) continue
            String renamed = ownerToken(top, oldOwner, newOwner)
            Matcher m = (renamed =~ /^(\D*)(\d{6,})(\D*)$/)
            if (renamed == top && m.matches() && idMap[PARTY][m.group(2)])
                renamed = m.group(1) + idMap[PARTY][m.group(2)] + m.group(3)
            if (renamed == top && ec.resource.getLocationReference('dbresource://' + top)?.getExists())
                renamed = top + '_' + newOwner
            if (renamed != top) roots[top] = renamed
        }
        return roots
    }

    static String relocate(String text, Map<String, String> roots) {
        if (!roots || !text.contains('dbresource://')) return text
        return text.replaceAll(/dbresource:\/\/([^\/\s"'<>()\\]+)/) { all, String top ->
            roots[top] ? 'dbresource://' + roots[top] : all
        }
    }

    private Map rewrite(String entity, Map row, Map<String, Map<String, String>> idMap, Map<String, String> roots,
                        String oldOwner, String newOwner, Map<String, Boolean> exists, Set<String> pks) {
        Map value = new HashMap(row)
        Map<String, String> fieldTargets = targets[entity]
        for (Map.Entry<String, String> ft in fieldTargets.entrySet()) {
            String field = ft.key
            String v = value[field]
            if (v == null) continue
            String mapped = idMap[ft.value][v]
            if (mapped != null) { value[field] = mapped; continue }
            if (ft.value == PARTY && v == oldOwner) { value[field] = newOwner; continue }
            // not in the file: a seed record that must be here already
            String key = ft.value + '|' + v
            if (!exists.containsKey(key))
                exists[key] = find(ft.value).condition(ed(ft.value).getPkFieldNames()[0], v).count() > 0
            if (exists[key]) continue
            if (pks.contains(field)) return null
            value[field] = null
        }
        // pseudoId is unique per owner: an owner itself (ownerPartyId _NA_) keeps its id as pseudoId
        if (ownIds.contains(entity) && row.pseudoId && value.ownerPartyId == row.ownerPartyId) {
            String pk = ed(entity).getPkFieldNames()[0]
            if (row.pseudoId == row[pk]) value.pseudoId = value[pk]
        }
        if (entity == SEQUENCE) value.seqName = ownerToken(value.seqName as String, oldOwner, newOwner)
        if (entity == 'moqui.security.UserAccount') value.username = ownerToken(value.username as String, oldOwner, newOwner)
        if (roots) value.each { k, v -> if (v instanceof String && v.contains('dbresource://')) value[k] = relocate(v, roots) }
        return value
    }

    /* A pseudoId unique over all owners (Facility) taken here already: the new id is used instead. */
    private void uniquePseudoId(EntityDefinition entityDef, EntityValue ev) {
        List<String> pks = entityDef.getPkFieldNames()
        if (!entityDef.isField('pseudoId') || !ev.get('pseudoId') || pks.size() != 1) return
        for (def index in entityDef.getEntityNode().children('index')) {
            if (index.attribute('unique') != 'true') continue
            List<String> fields = index.children('index-field').collect { it.attribute('name') }
            if (!fields.contains('pseudoId')) continue
            def find = ec.entity.find(entityDef.getFullEntityName()).useCache(false).disableAuthz()
            fields.each { find.condition(it, ev.get(it)) }
            EntityValue other = find.one()
            if (other != null && other.get(pks[0]) != ev.get(pks[0])) ev.set('pseudoId', ev.get(pks[0]))
        }
    }

    /* Moqui keeps every entity operation as a child of the running artifact (or, with none
       running, in the history of the execution context), for the hot spot report of the call.
       For a load of millions of records that fills the heap: what is done is dropped (no API,
       the private lists). */
    private void forgetHistory() {
        def running = ec.artifactExecution.peek()
        if (running != null) running.@childList = null
        else ec.artifactExecution.@artifactExecutionInfoHistory.clear()
    }

    /** entities that refer back to themselves, directly or round other entities */
    Set<String> cyclic(Collection<String> entities) {
        Set<String> out = [] as Set
        for (String start in entities) {
            Set<String> seen = [] as Set
            List<String> todo = (parents[start] ?: []).findAll { entities.contains(it) }.toList()
            while (todo) {
                String e = todo.pop()
                if (e == start) { out.add(start); break }
                if (seen.add(e)) todo.addAll((parents[e] ?: []).findAll { entities.contains(it) })
            }
        }
        return out
    }

    /** parents before children so few dummy records are needed. */
    List<String> loadOrder(Collection<String> entities) {
        List<String> order = []
        Set<String> visiting = [] as Set
        Closure visit
        visit = { String e ->
            if (order.contains(e) || visiting.contains(e)) return
            visiting.add(e)
            parents[e]?.each { String t -> if (t != e && entities.contains(t)) visit(t) }
            visiting.remove(e)
            order.add(e)
        }
        entities.sort().each { visit(it) }
        return order
    }
}

// Return the class for use by OwnerDataServices100
return OwnerDataTransfer
