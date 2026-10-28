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

/* Tests for OwnerDataServices100 / OwnerDataTransfer.groovy, the download and upload of
   all data of an owner:
   - the download holds the owner's data (parties, users, products, ledger, files) and
     nothing of another owner
   - an upload whose users exist already is refused without writing anything
   - an upload becomes a new owner with new ids: the same records, no reference back to
     the source owner, the source owner unchanged, files under a new location, and its
     users can log in with their old password
   - only system support can upload, the background job reports its progress

   The source tenant gets demo data once (the test database persists between runs);
   every run uploads one more copy.

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

    def "the download holds the owner's data and files"() {
        when:
        exported = ec.transaction.runUseOrBegin(600, 'export failed') { transfer().export(tenant.ownerPartyId, zipFile) }
        Map data = transferClass.readZip(zipFile.bytes)
        ec.logger.info("Owner data download counts: ${exported.counts}, files ${data.files.keySet()}, left out ${exported.leftOut}")

        then:
        data.manifest.ownerPartyId == tenant.ownerPartyId
        ['mantle.party.Party', 'mantle.party.Person', 'moqui.security.UserAccount', 'mantle.product.Product',
         'mantle.product.store.ProductStore', 'mantle.ledger.account.GlAccount',
         'mantle.ledger.account.GlAccountOrganization', 'mantle.order.OrderHeader', 'mantle.order.OrderItem',
         'growerp.general.TenantSetup'].every { exported.counts[it] }
        ['mantle.party.contact.ContactMech', 'mantle.party.contact.PostalAddress',
         'mantle.party.contact.PartyContactMech', 'mantle.order.OrderPart'].every { exported.counts[it] }
        // the demo owner has no data shared with another owner
        exported.leftOut.isEmpty()
        data.files.containsKey(fileLocation.substring('dbresource://'.length()))
        // nothing of another owner
        !data.entities['mantle.party.Party'].any { it.partyId == other.ownerPartyId || it.ownerPartyId == other.ownerPartyId }
        !data.entities['mantle.party.Party'].any { it.partyId == 'GROWERP' }
        data.entities['moqui.security.UserAccount'].every { it.username != other.username }
    }

    def "the download is standard Moqui data: the Moqui data check finds it equal to the database"() {
        when:
        List<String> differences = []
        long checked = 0
        new java.util.zip.ZipInputStream(new ByteArrayInputStream(zipFile.bytes)).withCloseable { zis ->
            def entry
            while ((entry = zis.getNextEntry()) != null) {
                if (!entry.name.startsWith('entities/')) continue
                List<Map<String, Object>> diffs = []
                checked += ec.entity.makeDataLoader()
                        .xmlText(new String(zis.readAllBytes(), 'UTF-8')).checkInfo(diffs, [])
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
        transfer().conflicts(transferClass.readZip(zipFile.bytes)).any { it.contains(tenant.username) }
    }

    def "an upload becomes a new owner with new ids and the same records"() {
        given:
        Map before = selectCounts(tenant.ownerPartyId)
        Map data = transferClass.readZip(zipFile.bytes)
        String run = System.currentTimeMillis().toString()
        // as on another system: users not known here
        data.entities['moqui.security.UserAccount'].each {
            it.username = "${run}.${it.username}".toString()
            if (it.emailAddress) it.emailAddress = "${run}.${it.emailAddress}".toString()
        }

        when:
        imported = ec.transaction.runUseOrBegin(600, 'import failed') { transfer().load(data) }
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
        def content = ec.entity.find('mantle.product.ProductContent').condition('contentLocation', 'like', '%ownerDataSpock.txt')
                .list().find { it.contentLocation != fileLocation }

        then:
        content
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
        ec.service.sync().name('growerp.100.OwnerDataServices100.create#OwnerDataImport')
                .parameters([fileName: 'backup.zip', zip: zipFile.bytes.encodeBase64().toString()]).call()

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('system support')
    }

    def "a download runs in the background and can be fetched when done"() {
        when:
        Map started = ec.service.sync().name('growerp.100.OwnerDataServices100.create#OwnerDataExport').call()
        assert !ec.message.hasError(), ec.message.errorsString
        String id = started.ownerDataTransfer.ownerDataTransferId
        Map job = null
        for (int i = 0; i < 600; i++) {
            job = ec.service.sync().name('growerp.100.OwnerDataServices100.get#OwnerDataTransfer')
                    .parameters([ownerDataTransferId: id]).call().ownerDataTransfer
            if (job.status in ['DONE', 'FAILED']) break
            Thread.sleep(500)
        }
        Map file = ec.service.sync().name('growerp.100.OwnerDataServices100.get#OwnerDataExportFile')
                .parameters([ownerDataTransferId: id]).call()

        then:
        job.status == 'DONE'
        job.counts == exported.counts
        file.fileName.endsWith('.zip')
        transferClass.readZip(file.zip.decodeBase64()).manifest.ownerPartyId == tenant.ownerPartyId

        when: "another owner cannot fetch it"
        ec.user.internalLoginUser(other.username)
        ec.service.sync().name('growerp.100.OwnerDataServices100.get#OwnerDataExportFile')
                .parameters([ownerDataTransferId: id]).call()

        then:
        ec.message.hasError()
    }
}
