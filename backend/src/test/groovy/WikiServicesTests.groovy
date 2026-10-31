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

/* Tests for WikiServices100:
   - get#WikiPage returns the page file type (wikiType) so the client picks the
     markdown or the html editor
   - update#WikiPage keeps the file type of an existing html page

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class WikiServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared String wikiSpaceId
    // the test database persists between runs: new page paths every run
    @Shared String suffix = System.currentTimeMillis().toString()

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'Wiki')
        Map spaces = ec.service.sync().name('growerp.100.WikiServices100.get#WikiSpaces').call()
        wikiSpaceId = spaces.wikiSpaces[0].wikiSpaceId
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    def "the owner's own space comes first"() {
        expect:
        wikiSpaceId && wikiSpaceId != 'GROWERP_OKF'
    }

    def "a new page is markdown"() {
        when:
        Map result = ec.service.sync().name('growerp.100.WikiServices100.update#WikiPage')
                .parameters([wikiSpaceId: wikiSpaceId, pagePath: "spockMarkdown${suffix}",
                        pageText: '# Markdown\n\nSome text\n']).call()

        then:
        !ec.message.hasError()
        result.wikiPage.wikiType == 'md'
        result.wikiPage.pageText.contains('# Markdown')
    }

    def "a page created while another thread lists its directory is found"() {
        given: "the space root directory"
        String rootPageLocation = ec.entity.find('moqui.resource.wiki.WikiSpace')
                .condition('wikiSpaceId', wikiSpaceId).one().rootPageLocation
        String fileName = "spockRace${suffix}.md"

        when: "a reader in its own transaction (like the wiki DataFeed worker) lists the directory before the write commits"
        boolean began = ec.transaction.begin(null)
        ec.resource.getLocationReference("${rootPageLocation}/${fileName}").putText('race')
        Thread reader = Thread.start {
            ExecutionContext readerEc = Moqui.getExecutionContext()
            try { readerEc.resource.getLocationReference(rootPageLocation).getDirectoryEntries() }
            finally { readerEc.destroy() }
        }
        reader.join()
        ec.transaction.commit(began)

        then:
        ec.resource.getLocationReference(rootPageLocation).getDirectoryEntries()*.fileName.contains(fileName)
    }

    def "an html page reports html.ftl and stays html after an update"() {
        given: "an html page as the website generator writes it"
        Map created = ec.service.sync().name('org.moqui.impl.WikiServices.update#WikiPage')
                .parameters([wikiSpaceId: wikiSpaceId, pagePath: "spockHtml${suffix}", pageName: "spockHtml${suffix}",
                        wikiType: 'html.ftl', pageText: '<h1>Html</h1>']).call()
        ec.service.sync().name('org.moqui.impl.WikiServices.set#PublishedVersion')
                .parameters([wikiPageId: created.wikiPageId, publishedVersionName: created.versionName]).call()

        when:
        Map read = ec.service.sync().name('growerp.100.WikiServices100.get#WikiPage')
                .parameters([wikiSpaceId: wikiSpaceId, pagePath: "spockHtml${suffix}"]).call()
        Map updated = ec.service.sync().name('growerp.100.WikiServices100.update#WikiPage')
                .parameters([wikiSpaceId: wikiSpaceId, pagePath: "spockHtml${suffix}",
                        pageText: '<h1>Html changed</h1>']).call()

        then:
        !ec.message.hasError()
        read.wikiPage.wikiType == 'html.ftl'
        read.wikiPage.pageText == '<h1>Html</h1>'
        updated.wikiPage.pageText == '<h1>Html changed</h1>'
        // the read-back above comes from the resource cache: check the stored file name
        ec.entity.find('moqui.resource.DbResource')
                .condition('filename', "spockHtml${suffix}.html.ftl").useCache(false).count() == 1
    }
}
