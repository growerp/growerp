/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

/* Tests for OwnerDataServices100 / OwnerDataTransfer.groovy, the download and upload of
   all data of an owner:
   - the download holds the owner's data (parties, users, products, ledger, files) and
     nothing of another owner, in the standard Moqui data format
   - an upload whose users exist already is refused without writing anything
   - an upload becomes a new owner with new ids: the same records, no reference back to
     the source owner, the source owner unchanged, files under a new location, and its
     users can log in with their old password
   - the upload comes in chunks (proxies limit a request), only from system support
   - a download runs in the background and gives a link for its owner only

   The source tenant gets demo data once (the test database persists between runs);
   every run uploads more copies.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test --tests OwnerDataServicesTests"
 */
@Stepwise
class OwnerDataServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, other
    @Shared def transferClass
    @Shared File zipFile
    @Shared Map exported, imported
    @Shared String fileLocation

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'OwnerDataSource')
        other = GrowerpTestSupport.tenant(ec, 'OwnerDataOther')
        ec.user.internalLoginUser(tenant.username)
        transferClass = ec.resource.script('component://growerp/service/OwnerDataTransfer.groovy', null)
        if (!ec.entity.find('mantle.product.Product').condition('ownerPartyId', tenant.ownerPartyId).disableAuthz().count()) {
            ec.service.sync().name('growerp.100.PartyServices100.load#DemoData')
                    .parameters([ownerPartyId: tenant.ownerPartyId, companyPartyId: tenant.companyPartyId,
                                 userPartyId: tenant.adminPartyId, currencyId: 'USD', applicationId: 'AppAdmin',
                                 timeZoneOffset: '00:00']).call()
            assert !ec.message.hasError(), ec.message.errorsString
        }
        // a file of the owner, referred to by a product
        def product = ec.entity.find('mantle.product.Product').condition('ownerPartyId', tenant.ownerPartyId)
                .disableAuthz().list().first()
        fileLocation = "dbresource://C${tenant.companyPartyId}/images/ownerDataSpock.txt".toString()
        ec.resource.getLocationReference(fileLocation).putText('owner data spock file')
        if (!ec.entity.find('mantle.product.ProductContent').condition('contentLocation', fileLocation).disableAuthz().count())
            ec.service.sync().name('create#mantle.product.ProductContent').parameters([productId: product.productId,
                    productContentTypeEnumId: 'PcntImageOriginal', contentLocation: fileLocation]).disableAuthz().call()
        zipFile = File.createTempFile('ownerData', '.zip')
    }

    def cleanupSpec() {
        zipFile?.delete()
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    private def transfer() { return transferClass.newInstance(ec, null) }

    private Map selectCounts(String owner) {
        return transfer().select(owner).collectEntries { k, v -> [k, v.size()] }.findAll { it.value }
    }

    /** the records of one entity in a download */
    private List<Map> records(File file, String entity) {
        List<Map> rows = []
        new ZipFile(file).withCloseable { ZipFile zip ->
            ZipEntry entry = zip.getEntry("entities/${entity}.xml")
            if (entry) zip.getInputStream(entry).withCloseable { transferClass.eachDataRecord(it) { Map row -> rows.add(row) } }
        }
        return rows
    }

    /** a copy of the download with its users renamed, as if loaded on another system */
    private File renamedUsers(String prefix) {
        File copy = File.createTempFile('ownerDataCopy', '.zip')
        new ZipFile(zipFile).withCloseable { ZipFile zip ->
            new ZipOutputStream(new FileOutputStream(copy)).withCloseable { ZipOutputStream zos ->
                zip.entries().each { ZipEntry e ->
                    byte[] bytes = zip.getInputStream(e).readAllBytes()
                    if (e.name == 'entities/moqui.security.UserAccount.xml') bytes = new String(bytes, 'UTF-8')
                            .replaceAll(/(username|emailAddress)="/, '$1="' + prefix + '.').getBytes('UTF-8')
                    zos.putNextEntry(new ZipEntry(e.name))
                    zos.write(bytes)
                    zos.closeEntry()
                }
            }
        }
        return copy
    }

    private Map waitFor(String id, String ownerPartyId = null) {
        Map job = null
        for (int i = 0; i < 600; i++) {
            job = ec.service.sync().name('growerp.100.OwnerDataServices100.get#OwnerDataTransfer')
                    .parameters([ownerDataTransferId: id, ownerPartyId: ownerPartyId]).call().ownerDataTransfer
            if (job.status in ['DONE', 'FAILED']) break
            Thread.sleep(500)
        }
        return job
    }

    def "the download holds the owner's data and files"() {
        when:
        exported = ec.transaction.runUseOrBegin(600, 'export failed') { transfer().export(tenant.ownerPartyId, zipFile) }
        Map manifest
        Set<String> names
        new ZipFile(zipFile).withCloseable { ZipFile zip ->
            manifest = transferClass.manifest(zip)
            names = zip.entries().collect { it.name } as Set
        }
        List<Map> parties = records(zipFile, 'mantle.party.Party')
        ec.logger.info("Owner data download counts: ${exported.counts}, left out ${exported.leftOut}")

        then:
        manifest.ownerPartyId == tenant.ownerPartyId
        ['mantle.party.Party', 'mantle.party.Person', 'moqui.security.UserAccount', 'mantle.product.Product',
         'mantle.product.store.ProductStore', 'mantle.ledger.account.GlAccount',
         'mantle.ledger.account.GlAccountOrganization', 'mantle.order.OrderHeader', 'mantle.order.OrderItem',
         'growerp.general.TenantSetup'].every { exported.counts[it] }
        ['mantle.party.contact.ContactMech', 'mantle.party.contact.PostalAddress',
         'mantle.party.contact.PartyContactMech', 'mantle.order.OrderPart'].every { exported.counts[it] }
        // every record written
        exported.counts.every { entity, n -> records(zipFile, entity).size() == n }
        // only what points at another owner's data is left out (a GROWERP email sequence
        // enrollment of the admin), never the owner's own records
        exported.leftOut.every { String row -> !(row.split(' ')[0] in ['mantle.party.Party', 'mantle.party.Person',
                'mantle.party.contact.ContactMech', 'mantle.party.contact.PartyContactMech', 'mantle.product.Product',
                'mantle.order.OrderHeader', 'mantle.order.OrderPart', 'mantle.order.OrderItem', 'moqui.security.UserAccount']) }
        names.contains('files/' + fileLocation.substring('dbresource://'.length()))
        // nothing of another owner
        !parties.any { it.partyId == other.ownerPartyId || it.ownerPartyId == other.ownerPartyId }
        !parties.any { it.partyId == 'GROWERP' }
        records(zipFile, 'moqui.security.UserAccount').every { it.username != other.username }
    }

    def "the download is standard Moqui data: the Moqui data check finds it equal to the database"() {
        when:
        List<String> differences = []
        long checked = 0
        new ZipFile(zipFile).withCloseable { ZipFile zip ->
            zip.entries().findAll { it.name.startsWith('entities/') }.each { ZipEntry entry ->
                List<Map<String, Object>> diffs = []
                checked += ec.entity.makeDataLoader()
                        .xmlText(new String(zip.getInputStream(entry).readAllBytes(), 'UTF-8')).checkInfo(diffs, [])
                diffs.each { differences.add("${entry.name}: ${it}".toString()) }
            }
        }

        then:
        // the check counts the fields it compared
        checked >= exported.counts.values().sum()
        differences.isEmpty()
    }

    def "an upload whose users exist here already is refused"() {
        expect:
        new ZipFile(zipFile).withCloseable { transfer().conflicts(it) }.any { it.contains(tenant.username) }
    }

    def "an upload becomes a new owner with new ids and the same records"() {
        given:
        Map before = selectCounts(tenant.ownerPartyId)
        String run = System.currentTimeMillis().toString()
        File copy = renamedUsers(run)
        File work = File.createTempDir()

        when:
        imported = new ZipFile(copy).withCloseable { ZipFile zip ->
            ec.transaction.runUseOrBegin(600, 'import failed') { transfer().load(zip, work) }
        }
        copy.delete()
        String newOwner = imported.ownerPartyId
        Map after = selectCounts(newOwner)

        then:
        newOwner && newOwner != tenant.ownerPartyId
        !imported.skipped
        imported.counts == exported.counts
        // the copy holds the same records, none of them pointing back at the source
        after == exported.counts
        selectCounts(tenant.ownerPartyId) == before
        ec.entity.find('mantle.product.Product').condition('ownerPartyId', newOwner).count() ==
                ec.entity.find('mantle.product.Product').condition('ownerPartyId', tenant.ownerPartyId).count()
        ec.entity.find('mantle.product.Product').condition('ownerPartyId', newOwner).list()*.productId
                .intersect(ec.entity.find('mantle.product.Product').condition('ownerPartyId', tenant.ownerPartyId).list()*.productId)
                .isEmpty()
        ec.entity.find('mantle.party.Party').condition('ownerPartyId', newOwner).count() ==
                ec.entity.find('mantle.party.Party').condition('ownerPartyId', tenant.ownerPartyId).count()

        when: "the file moved along with the new company id"
        List newProducts = ec.entity.find('mantle.product.Product').condition('ownerPartyId', newOwner).list()*.productId
        def content = ec.entity.find('mantle.product.ProductContent').condition('contentLocation', 'like', '%ownerDataSpock.txt')
                .condition('productId', 'in', newProducts).one()

        then:
        content
        content.contentLocation != fileLocation
        ec.resource.getLocationText(content.contentLocation, false) == 'owner data spock file'

        when: "a user of the copy logs in with the old password"
        ec.user.logoutUser()
        boolean loggedIn = ec.user.loginUser("${run}.${tenant.username}".toString(), 'qqqqqq9!')
        Map related = ec.service.sync().name('growerp.100.GeneralServices100.get#RelatedCompanyAndOwner').call()

        then:
        loggedIn
        related.ownerPartyId == newOwner
        related.companyPartyId != tenant.companyPartyId
    }

    def "only system support can upload"() {
        when:
        ec.service.sync().name('growerp.100.OwnerDataServices100.upload#OwnerDataChunk')
                .parameters([fileName: 'backup.zip', offset: 0L, last: true, file: zipFile.bytes]).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('system support')
    }

    def "system support uploads in chunks, loaded in the background as a new owner"() {
        given:
        ec.user.internalLoginUser('SystemSupport')
        File copy = renamedUsers('chunks' + System.currentTimeMillis())
        byte[] bytes = copy.bytes
        copy.delete()
        List<byte[]> chunks = bytes.toList().collate(bytes.length.intdiv(3) + 1).collect { it as byte[] }

        when:
        String id = null
        long offset = 0
        chunks.eachWithIndex { byte[] chunk, int i ->
            Map out = ec.service.sync().name('growerp.100.OwnerDataServices100.upload#OwnerDataChunk')
                    .parameters([ownerDataTransferId: id, fileName: 'backup.zip', offset: offset,
                                 last: i == chunks.size() - 1, file: chunk]).call()
            assert !ec.message.hasError(), ec.message.errorsString
            id = out.ownerDataTransfer.ownerDataTransferId
            offset += chunk.length
        }
        Map job = waitFor(id)

        then:
        chunks.size() == 3
        job.status == 'DONE'
        job.newOwnerPartyId
        job.counts == exported.counts

        when: "a chunk out of place is refused"
        ec.message.clearAll()
        Map first = ec.service.sync().name('growerp.100.OwnerDataServices100.upload#OwnerDataChunk')
                .parameters([fileName: 'backup.zip', offset: 0L, last: false, file: chunks[0]]).call()
        ec.service.sync().name('growerp.100.OwnerDataServices100.upload#OwnerDataChunk')
                .parameters([ownerDataTransferId: first.ownerDataTransfer.ownerDataTransferId, fileName: 'backup.zip',
                             offset: 5L, last: false, file: chunks[1]]).call()

        then:
        ec.message.errorsString.contains('does not follow')

        when: "a new upload gives up the one not finished"
        ec.message.clearAll()
        Map next = ec.service.sync().name('growerp.100.OwnerDataServices100.upload#OwnerDataChunk')
                .parameters([fileName: 'backup.zip', offset: 0L, last: false, file: chunks[0]]).call()
        def abandoned = ec.entity.find('growerp.general.OwnerDataTransfer')
                .condition('ownerDataTransferId', first.ownerDataTransfer.ownerDataTransferId).one()

        then:
        !ec.message.hasError()
        next.ownerDataTransfer.status == 'UPLOADING'
        abandoned.status == 'FAILED'
    }

    def "a download runs in the background and gives a link for its owner only"() {
        when:
        Map started = ec.service.sync().name('growerp.100.OwnerDataServices100.create#OwnerDataExport').call()
        assert !ec.message.hasError(), ec.message.errorsString
        String id = started.ownerDataTransfer.ownerDataTransferId
        Map job = waitFor(id)
        def row = ec.entity.find('growerp.general.OwnerDataTransfer').condition('ownerDataTransferId', id).one()

        then:
        job.status == 'DONE'
        job.counts == exported.counts
        job.downloadPath == '/ownerData/download?t=' + row.downloadToken
        new File(row.fileLocation as String).length() == job.fileSize

        when: "another owner does not get it"
        ec.user.internalLoginUser(other.username)
        Map seen = ec.service.sync().name('growerp.100.OwnerDataServices100.get#OwnerDataTransfer')
                .parameters([ownerDataTransferId: id]).call().ownerDataTransfer

        then:
        seen == null

        when: "system support downloads any owner"
        ec.user.internalLoginUser('SystemSupport')
        Map support = ec.service.sync().name('growerp.100.OwnerDataServices100.create#OwnerDataExport')
                .parameters([ownerPartyId: other.ownerPartyId]).call().ownerDataTransfer
        Map supportJob = waitFor(support.ownerDataTransferId, other.ownerPartyId)

        then:
        supportJob.status == 'DONE'
        supportJob.downloadPath
        supportJob.counts['mantle.party.Party']
    }
}
