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
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/* Tests for the knowledge base (moqui-adk AdkServices100 / AdkKnowledgeServices):
   - a ZIP loads in the background, one document per supported file, titled with its path
   - loading the same ZIP again updates those documents instead of adding new ones
   - unsupported, hidden, __MACOSX and empty files are skipped with a reason
   - a file that is not a zip, a too large zip and a second load at the same time are refused
   - statistics: size, folders, recency, index health (outdated model, no chunks), searches
   - re-index rebuilds the chunks of an outdated embedding model
   - another company sees none of it
   Embeddings run in test mode (growerp.testMode): a local vector, no API call.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
@Stepwise
class AdkKnowledgeServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(AdkKnowledgeServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared Map otherTenant

    def setupSpec() {
        System.setProperty('growerp.testMode', 'true')
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'Knowledge')
        otherTenant = GrowerpTestSupport.tenant(ec, 'KnowledgeOther')
        // the tenants are kept between runs: start from an empty knowledge base
        ec.artifactExecution.disableAuthz()
        [tenant, otherTenant].each { Map t ->
            ['moqui.adk.AdkKnowledgeChunk', 'moqui.adk.AdkKnowledgeDoc', 'moqui.adk.AdkKnowledgeImport'].each {
                ec.entity.find(it).condition('ownerPartyId', t.ownerPartyId).deleteAll()
            }
            ec.entity.find('moqui.adk.AdkActionLog').condition('ownerPartyId', t.ownerPartyId)
                .condition('toolName', 'searchKnowledge').deleteAll()
        }
    }

    def cleanupSpec() {
        System.clearProperty('growerp.testMode')
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    private static String zip(Map<String, Object> files) {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream()
        new ZipOutputStream(bytes).withCloseable { zout ->
            files.each { String path, Object content ->
                zout.putNextEntry(new ZipEntry(path))
                if (content != null) zout.write(content instanceof byte[] ? content as byte[] : (content as String).getBytes('UTF-8'))
                zout.closeEntry()
            }
        }
        return Base64.encoder.encodeToString(bytes.toByteArray())
    }

    /** A minimal docx: a zip with the text in word/document.xml. */
    private static byte[] docx(String text) {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream()
        new ZipOutputStream(bytes).withCloseable { zout ->
            zout.putNextEntry(new ZipEntry('word/document.xml'))
            zout.write("<w:document><w:body><w:p><w:r><w:t>${text}</w:t></w:r></w:p></w:body></w:document>".getBytes('UTF-8'))
            zout.closeEntry()
        }
        return bytes.toByteArray()
    }

    private Map files(String version) {
        return [
            'policies/'                  : null,
            'policies/hr/leave.md'       : "# Leave\nEmployees get 25 vacation days a year. ${version}".toString(),
            'policies/travel.txt'        : "Travel by train when the trip is under 500 km. ${version}".toString(),
            'manuals/guide.docx'         : docx("The forklift guide says to check the brakes daily. ${version}"),
            'manuals/photo.png'          : 'not text',
            'manuals/empty.txt'          : '   ',
            '__MACOSX/policies/._leave.md': 'mac junk',
            '.DS_Store'                  : 'mac junk',
        ]
    }

    private Map startLoad(String fileName, String zipData) {
        Map out = ec.service.sync().name('AdkServices100.create#AdkKnowledgeImport')
                .parameters([fileName: fileName, zip: zipData]).call()
        return out?.adkKnowledgeImport as Map
    }

    /** The background worker runs on another thread: poll until it is done. */
    private Map waitFor(String adkKnowledgeImportId) {
        Map job = null
        for (int i = 0; i < 120; i++) {
            job = ec.service.sync().name('AdkServices100.get#AdkKnowledgeImport')
                    .parameters([adkKnowledgeImportId: adkKnowledgeImportId]).call().adkKnowledgeImport as Map
            if (!(job?.status in ['QUEUED', 'RUNNING'])) return job
            Thread.sleep(500)
        }
        return job
    }

    private Map stats() {
        Map result = ec.service.sync().name('AdkServices100.get#AdkKnowledgeStats').call()
        assert !ec.message.hasError()
        return result
    }

    private List docs() {
        return ec.entity.find('moqui.adk.AdkKnowledgeDoc').condition('ownerPartyId', tenant.ownerPartyId)
                .orderBy('title').list()
    }

    def "a search on an empty knowledge base counts as a search without result"() {
        when:
        Map found = ec.service.sync().name('AdkKnowledgeServices.search#AdkKnowledge')
                .parameters([ownerPartyId: tenant.ownerPartyId, query: 'vacation days']).call()
        Map st = stats()

        then:
        !ec.message.hasError()
        found.results == []
        st.docCount == 0
        st.searchCountLast30Days == 1
        st.emptySearchCountLast30Days == 1
        st.lastSearchDate != null
    }

    def "a zip loads each supported file as a document titled with its path"() {
        when:
        Map started = startLoad('handbook.zip', zip(files('v1')))
        Map job = waitFor(started.adkKnowledgeImportId as String)

        then:
        !ec.message.hasError()
        started.status in ['QUEUED', 'RUNNING', 'DONE']
        job.status == 'DONE'
        job.jobType == 'ZIP'
        job.fileCount == 4
        job.processedCount == 4
        job.createdCount == 3
        job.updatedCount == 0
        docs()*.title == ['manuals/guide', 'policies/hr/leave', 'policies/travel']
        docs()*.sourceId as Set == ['handbook/manuals/guide.docx', 'handbook/policies/hr/leave.md',
                                   'handbook/policies/travel.txt'] as Set
        docs().every { it.sourceType == 'upload' }
        docs().find { it.title == 'manuals/guide' }.metadataJson.contains('"path":"manuals/guide.docx"')
        ec.entity.find('moqui.adk.AdkKnowledgeImport').condition('adkKnowledgeImportId', started.adkKnowledgeImportId)
                .one().zipData == null
    }

    def "unsupported, empty and hidden files are skipped with a reason"() {
        when:
        Map job = ec.service.sync().name('AdkServices100.get#AdkKnowledgeImport').call().adkKnowledgeImport as Map

        then:
        job.skippedCount == 2
        (job.skipped as List).collectEntries { [it.path, it.reason] } ==
                ['manuals/photo.png': 'unsupported file type', 'manuals/empty.txt': 'no text']
    }

    def "the text of a docx is searchable"() {
        when:
        Map found = ec.service.sync().name('AdkKnowledgeServices.search#AdkKnowledge')
                .parameters([ownerPartyId: tenant.ownerPartyId, query: 'forklift brakes', limit: 1]).call()

        then:
        !ec.message.hasError()
        found.results[0].title == 'manuals/guide'
        found.results[0].text.contains('forklift')
    }

    def "loading the same zip again updates the documents in place"() {
        given:
        List before = docs()*.adkKnowledgeDocId

        when:
        Map job = waitFor(startLoad('handbook.zip', zip(files('v2'))).adkKnowledgeImportId as String)
        Map leave = docs().find { it.title == 'policies/hr/leave' }
        List texts = ec.entity.find('moqui.adk.AdkKnowledgeChunk')
                .condition('adkKnowledgeDocId', leave.adkKnowledgeDocId).list()*.text

        then:
        job.status == 'DONE'
        job.createdCount == 0
        job.updatedCount == 3
        docs()*.adkKnowledgeDocId == before
        texts.size() == 1
        texts[0].contains('v2')
    }

    def "a file that is not a zip is refused"() {
        when:
        startLoad('notes.zip', Base64.encoder.encodeToString('just text'.getBytes('UTF-8')))

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('not a readable zip file')
    }

    def "a zip larger than 25 MB is refused"() {
        given:
        byte[] noise = new byte[26 * 1024 * 1024]
        new Random(1).nextBytes(noise)

        when:
        startLoad('big.zip', zip(['big.txt': noise]))

        then:
        ec.message.hasError()
        ec.message.errorsString.contains('larger than 25 MB')
    }

    def "a second load while one is running is refused"() {
        given:
        Map running = ec.service.sync().name('create#moqui.adk.AdkKnowledgeImport')
                .parameters([ownerPartyId: tenant.ownerPartyId, jobType: 'ZIP', status: 'RUNNING',
                             createdDate: ec.user.nowTimestamp]).call()

        when:
        startLoad('handbook.zip', zip(files('v3')))
        boolean refused = ec.message.hasError() && ec.message.errorsString.contains('already running')
        ec.message.clearAll()
        ec.entity.find('moqui.adk.AdkKnowledgeImport')
                .condition('adkKnowledgeImportId', running.adkKnowledgeImportId).deleteAll()

        then:
        refused
    }

    def "statistics give size, folders, recency and searches"() {
        when:
        Map st = stats()

        then:
        st.docCount == 3
        st.chunkCount == 3
        st.tokenCount > 0
        st.docsAddedLast30Days == 3
        st.lastChangedDate != null
        st.bySourceType == [[sourceType: 'upload', docCount: 3, chunkCount: 3]]
        st.topFolders as Set == [[folder: 'handbook/policies/hr', docCount: 1],
                                 [folder: 'handbook/policies', docCount: 1],
                                 [folder: 'handbook/manuals', docCount: 1]] as Set
        st.currentEmbeddingModel == 'test-embedding'
        st.staleChunkCount == 0
        st.staleDocCount == 0
        st.emptyDocCount == 0
        // the empty search and the docx search
        st.searchCountLast30Days == 2
        st.emptySearchCountLast30Days == 1
    }

    def "chunks of another embedding model and docs without chunks count as index problems"() {
        given:
        def chunk = ec.entity.find('moqui.adk.AdkKnowledgeChunk').condition('ownerPartyId', tenant.ownerPartyId)
                .list().first()
        chunk.embeddingModel = 'old-model'
        chunk.update()
        ec.service.sync().name('create#moqui.adk.AdkKnowledgeDoc')
                .parameters([ownerPartyId: tenant.ownerPartyId, title: 'no text', sourceType: 'note']).call()

        when:
        Map st = stats()

        then:
        st.docCount == 4
        st.staleChunkCount == 1
        st.staleDocCount == 1
        st.emptyDocCount == 1
    }

    def "re-index rebuilds the chunks of an outdated embedding model"() {
        when:
        Map started = ec.service.sync().name('AdkServices100.create#AdkKnowledgeReindex').call().adkKnowledgeImport as Map
        Map job = waitFor(started.adkKnowledgeImportId as String)
        Map st = stats()

        then:
        job.status == 'DONE'
        job.jobType == 'REINDEX'
        job.fileCount == 1
        job.updatedCount == 1
        st.staleChunkCount == 0
        st.chunkCount == 3
    }

    def "the document list counts chunks per document"() {
        when:
        List list = ec.service.sync().name('AdkServices100.get#AdkKnowledge').call().adkKnowledgeDocs as List

        then:
        list.size() == 4
        list.find { it.title == 'policies/travel' }.chunkCount == 1
        list.find { it.title == 'no text' }.chunkCount == 0
    }

    def "another company sees none of it"() {
        given:
        ec.user.internalLoginUser(otherTenant.username)

        when:
        Map st = stats()
        Map job = ec.service.sync().name('AdkServices100.get#AdkKnowledgeImport').call().adkKnowledgeImport as Map

        then:
        st.docCount == 0
        st.searchCountLast30Days == 0
        job == null
    }

    def "text with < and > (markdown, code, html) loads and is searchable"() {
        given:
        String md = "# Pricing\nUse <b>bold</b> sparingly; plans for teams of < 10 and > 50 users. Ticket <TICKET-1>."

        when: 'one file of a zip'
        Map job = waitFor(startLoad('markup.zip', zip(['markup/pricing.md': md])).adkKnowledgeImportId as String)

        then:
        !ec.message.hasError()
        job.status == 'DONE'
        job.createdCount == 1

        when: 'a note added by hand, then changed'
        Map created = ec.service.sync().name('AdkServices100.create#AdkKnowledge')
                .parameters([title: 'markup note', text: md]).call()
        ec.service.sync().name('AdkServices100.update#AdkKnowledge')
                .parameters([adkKnowledgeDocId: created.adkKnowledgeDocId, text: md + ' <i>v2</i>']).call()
        Map found = ec.service.sync().name('AdkKnowledgeServices.search#AdkKnowledge')
                .parameters([ownerPartyId: tenant.ownerPartyId, query: 'teams of < 10 users <b>', limit: 1]).call()

        then:
        !ec.message.hasError()
        found.results[0].text.contains('<')
    }
}
