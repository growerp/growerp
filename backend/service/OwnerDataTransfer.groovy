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
import org.moqui.util.MNode

import java.util.regex.Matcher
import java.util.regex.Pattern
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
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
 */
class OwnerDataTransfer {
    static final int FORMAT_VERSION = 1
    static final String CONFIG = 'component://growerp/service/ownerDataEntities.json'
    static final String PARTY = 'mantle.party.Party'
    static final String SEQUENCE = 'moqui.entity.SequenceValueItem'
    static final Pattern SEQUENCED_ID = ~/\d{6,}/
    static final Pattern DB_LOCATION = ~/dbresource:\/\/[^\s"'<>()\\]+/

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

    /** Write the owner's data as a zip to the file; returns [counts: [entity: rows], files: n]. */
    Map export(String ownerPartyId, File zipFile) {
        Map<String, Map<String, EntityValue>> rows = select(ownerPartyId)
        List<String> locations = fileLocations(ownerPartyId, rows)
        Map counts = rows.collectEntries { k, v -> [k, v.size()] }.findAll { it.value }
        int files = 0
        zipFile.parentFile.mkdirs()
        zipFile.withOutputStream { OutputStream os ->
            ZipOutputStream zos = new ZipOutputStream(os)
            rows.each { String entity, Map<String, EntityValue> byPk ->
                if (!byPk) return
                zos.putNextEntry(new ZipEntry("entities/${entity}.xml"))
                zos.write(dataXml(byPk.values()).getBytes('UTF-8'))
                zos.closeEntry()
            }
            for (String location in locations) {
                def ref = ec.resource.getLocationReference(location)
                byte[] bytes = ref.openStream()?.withCloseable { it.bytes }
                if (bytes == null) continue
                zos.putNextEntry(new ZipEntry('files/' + location.substring('dbresource://'.length())))
                zos.write(bytes)
                zos.closeEntry()
                files++
            }
            zos.putNextEntry(new ZipEntry('manifest.json'))
            zos.write(JsonOutput.prettyPrint(JsonOutput.toJson([formatVersion: FORMAT_VERSION,
                    ownerPartyId: ownerPartyId, exportDate: ec.user.nowTimestamp.time,
                    source: System.getProperty('default_host') ?: InetAddress.localHost.hostName,
                    counts: counts, files: files, leftOut: leftOut])).getBytes('UTF-8'))
            zos.closeEntry()
            zos.finish()
        }
        return [counts: counts, files: files, leftOut: leftOut]
    }

    /** entity -> [pk string -> row] of everything belonging to the owner. */
    Map<String, Map<String, EntityValue>> select(String owner) {
        Map<String, Map<String, EntityValue>> rows = [:].withDefault { [:] }
        Map<String, Set<String>> ids = [:].withDefault { [] as Set }
        Map<String, Set<String>> frontier = [:].withDefault { [] as Set }
        Closure add = { String entity, EntityValue ev ->
            String key = pkKey(entity, ev)
            if (rows[entity].containsKey(key)) return false
            rows[entity][key] = ev
            if (ownIds.contains(entity)) {
                String id = ev[ed(entity).getPkFieldNames()[0]]
                if (ids[entity].add(id)) frontier[entity].add(id)
            }
            return true
        }
        // the roots: the owner, its parties, its rows with ownerPartyId, owner keyed rows
        EntityValue ownerParty = find(PARTY).condition('partyId', owner).one()
        if (ownerParty == null) throw new IllegalArgumentException("Owner ${owner} not found")
        add(PARTY, ownerParty)
        for (String entity in tenant) {
            if (pullIn.contains(entity)) continue
            if (ed(entity).isField('ownerPartyId'))
                find(entity).condition('ownerPartyId', owner).list().each { add(entity, it) }
            if (ownerKeyed[entity])
                find(entity).condition((String) ownerKeyed[entity], owner).list().each { add(entity, it) }
        }
        if (tenant.contains(SEQUENCE)) find(SEQUENCE).condition('seqName', 'like', owner + '-%').list().each { add(SEQUENCE, it) }

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
                    if (ownIds.contains(entity) && field == ed(entity).getPkFieldNames()[0] && target == entity) return
                    current[target].toList().collate(500).each { List chunk ->
                        find(entity).condition(field, 'in', chunk).list().each { add(entity, it) }
                    }
                }
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
                                .unique().each { id ->
                            EntityValue ev = find(target).condition(pk, id).one()
                            if (ev != null && add(target, ev)) pulled = true
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
    private void prune(String owner, Map<String, Map<String, EntityValue>> rows, Map<String, Set<String>> ids) {
        Map<String, Boolean> foreignCache = [:]
        boolean changed = true
        while (changed) {
            changed = false
            rows.each { String entity, Map<String, EntityValue> byPk ->
                Iterator<Map.Entry<String, EntityValue>> it = byPk.entrySet().iterator()
                while (it.hasNext()) {
                    EntityValue row = it.next().value
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

    /** dbresource locations the rows refer to, a directory with everything below it. */
    List<String> fileLocations(String owner, Map<String, Map<String, EntityValue>> rows) {
        Set<String> found = [] as Set
        rows.values().each { byPk ->
            byPk.values().each { EntityValue row ->
                row.values().each { v -> if (v instanceof String && v.contains('dbresource://')) {
                    Matcher m = DB_LOCATION.matcher(v)
                    while (m.find()) found.add(m.group().replaceAll(/\/+$/, ''))
                } }
            }
        }
        Set<String> files = [] as Set
        for (String location in found) {
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

    /** records as a standard Moqui data file (entity-facade-xml). */
    static String dataXml(Collection<EntityValue> values) {
        StringWriter writer = new StringWriter()
        writer.append('<?xml version="1.0" encoding="UTF-8"?>\n<entity-facade-xml type="ownerData">\n')
        for (EntityValue ev in values) ev.writeXmlText(writer, null, 0)
        writer.append('</entity-facade-xml>\n')
        return writer.toString()
    }

    /** the records of a data file as field name -> text, the way the Moqui loader reads them. */
    static List<Map> parseDataXml(String text) {
        MNode root = MNode.parseText('ownerData', text)
        return root.getChildren().collect { MNode node ->
            Map row = new HashMap(node.getAttributes())
            node.getChildren().each { MNode field -> row[field.getName()] = field.getText() }
            row
        }
    }

    private String pkKey(String entity, Map row) {
        return ed(entity).getPkFieldNames().collect { row[it]?.toString() }.join('|')
    }

    private def find(String entity) {
        return ec.entity.find(entity).useCache(false).disableAuthz()
    }

    // ------------------------------------------------------------------------ import

    static Map readZip(byte[] zipBytes) {
        Map manifest = null
        Map<String, List<Map>> entities = [:]
        Map<String, byte[]> files = [:]
        new ZipInputStream(new ByteArrayInputStream(zipBytes)).withCloseable { ZipInputStream zis ->
            ZipEntry entry
            while ((entry = zis.getNextEntry()) != null) {
                if (entry.isDirectory()) continue
                byte[] bytes = zis.readAllBytes()
                String name = entry.name
                if (name == 'manifest.json') manifest = (Map) new JsonSlurper().parse(bytes, 'UTF-8')
                else if (name.startsWith('entities/') && name.endsWith('.xml'))
                    entities[name.substring(9, name.length() - 4)] = parseDataXml(new String(bytes, 'UTF-8'))
                else if (name.startsWith('files/')) files[name.substring(6)] = bytes
            }
        }
        return [manifest: manifest, entities: entities, files: files]
    }

    /** Conflicts that stop an import: user names and email addresses already in use. */
    List<String> conflicts(Map data) {
        String oldOwner = data.manifest.ownerPartyId
        List<String> out = []
        for (Map ua in (List<Map>) (data.entities['moqui.security.UserAccount'] ?: [])) {
            String username = ownerToken(ua.username as String, oldOwner, 'X')
            if (username == ua.username && find('moqui.security.UserAccount').condition('username', username).count())
                out.add("user name ${username} exists already".toString())
            else if (ua.emailAddress && find('moqui.security.UserAccount').condition('emailAddress', ua.emailAddress).count())
                out.add("user email ${ua.emailAddress} exists already".toString())
        }
        return out
    }

    /** Load the zip data as a new owner; returns [ownerPartyId: new owner, counts: [...], skipped: [...]]. */
    Map load(Map data) {
        Map manifest = (Map) data.manifest
        if (!manifest || (manifest.formatVersion as int) > FORMAT_VERSION)
            throw new IllegalArgumentException('This is not a GrowERP owner data file, or from a newer version')
        String oldOwner = manifest.ownerPartyId
        Map<String, List<Map>> entities = (Map) data.entities
        entities.keySet().findAll { !tenant.contains(it) }.each { entities.remove(it) }

        // new ids
        Map<String, Map<String, String>> idMap = [:].withDefault { [:] }
        String newOwner = newId(PARTY, oldOwner, oldOwner, null)
        idMap[PARTY][oldOwner] = newOwner
        entities.each { String entity, List<Map> list ->
            if (!ownIds.contains(entity)) return
            String pk = ed(entity).getPkFieldNames()[0]
            for (Map row in list) {
                String old = row[pk]
                if (!idMap[entity].containsKey(old)) idMap[entity][old] = newId(entity, old, oldOwner, newOwner)
            }
        }
        Map<String, String> roots = fileRoots(data, idMap, oldOwner, newOwner)

        Map counts = [:]
        List<String> skipped = []
        Map<String, Boolean> exists = [:]
        int total = entities.values().sum { it.size() } as int ?: 0
        int done = 0
        for (String entity in loadOrder(entities.keySet())) {
            Set<String> pks = ed(entity).getPkFieldNames() as Set
            List<EntityValue> values = []
            for (Map row in entities[entity]) {
                Map value = rewrite(entity, row, idMap, roots, oldOwner, newOwner, exists, pks)
                if (value == null) { skipped.add("${entity} ${pkKey(entity, row)}".toString()); continue }
                EntityValue ev = ec.entity.makeValue(entity)
                value.each { String f, Object v -> if (ev.isField(f)) ev.setString(f, (String) v) }
                uniquePseudoId(ed(entity), ev)
                values.add(ev)
            }
            if (!values) continue
            // the standard Moqui data loader: dummy records for references loaded later, no ECAs
            ec.entity.makeDataLoader().xmlText(dataXml(values)).dummyFks(true).disableEntityEca(true)
                    .disableAuditLog(true).disableDataFeed(true).load([])
            counts[entity] = values.size()
            done += values.size()
            progress("Loading data: ${done} of ${total} records")
        }
        data.files.each { String path, byte[] bytes ->
            ec.resource.getLocationReference(relocate('dbresource://' + path, roots)).putBytes(bytes)
        }
        ec.cache.clearAllCaches()
        return [ownerPartyId: newOwner, counts: counts, files: data.files.size(), skipped: skipped]
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
    private Map<String, String> fileRoots(Map data, Map<String, Map<String, String>> idMap, String oldOwner, String newOwner) {
        Set<String> tops = [] as Set
        data.files.keySet().each { String p -> tops.add(p.split('/')[0]) }
        ((Map<String, List<Map>>) data.entities).values().each { list -> list.each { Map row ->
            row.values().each { v -> if (v instanceof String && v.contains('dbresource://')) {
                Matcher m = DB_LOCATION.matcher(v)
                while (m.find()) { String rest = m.group().substring('dbresource://'.length()); if (rest) tops.add(rest.split('/')[0]) }
            } }
        } }
        Map<String, String> roots = [:]
        for (String top in tops) {
            if (top in ['DEFAULT_ROOT', 'GROWERP_ROOT', 'growerp'] && !data.files.keySet().any { it.startsWith(top + '/') }) continue
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
