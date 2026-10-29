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

/* Tests for WebsiteTranslationServices100 used by a tenant (issue #30):
   - a tenant translates its own website only, never another owner's
   - a tenant needs its own Gemini key, the system key is for support only
   - a tenant lists and deletes only its own translations
   - a translated .html.ftl page keeps its '<#-- title: ... -->' line first, even when the
     model moves, prefixes or drops it (production failure 2026-10-28, Thai, page 9)
   - a page that fails does not stop the run, and overwrite only redoes a page whose source
     changed after its translation (production run stopped at 24/50 on one Gemini timeout,
     2026-10-29, and a re-run started again at page 1)

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class WebsiteTranslationServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(WebsiteTranslationServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenantNoKey
    @Shared Map tenantWithKey

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenantNoKey = GrowerpTestSupport.tenant(ec, 'WsTransNoKey')
        tenantWithKey = GrowerpTestSupport.tenant(ec, 'WsTransKey')
        ec.service.sync().name('store#growerp.general.SystemSettings').disableAuthz()
                .parameters([ownerPartyId: tenantWithKey.ownerPartyId]).call()
        ec.service.sync().name('store#growerp.general.LlmConfig').disableAuthz()
                .parameters([ownerPartyId: tenantWithKey.ownerPartyId, llmProvider: 'gemini',
                        apiKey: 'spock-test-key']).call()
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
    }

    private Map create(Map parameters) {
        return ec.service.sync().name('growerp.100.WebsiteTranslationServices100.create#WebsiteTranslation')
                .parameters([targetLocales: 'th'] + parameters).call()
    }

    def "a tenant without its own Gemini key cannot translate its website"() {
        setup:
        ec.user.internalLoginUser(tenantNoKey.username)

        when:
        create([:])

        then: 'the system key is not used for a tenant'
        ec.message.hasError()
        ec.message.errorsString.contains('No Gemini API key configured for your company')

        cleanup:
        ec.message.clearAll()
    }

    def "a tenant cannot translate the website of another owner"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)

        when:
        create([ownerPartyId: tenantNoKey.companyPartyId])

        then: 'the ownerPartyId of a translation is the company whose website it is'
        ec.message.hasError()
        ec.entity.find('growerp.website.WebsiteTranslation')
                .condition('ownerPartyId', tenantNoKey.companyPartyId).useCache(false).count() == 0

        cleanup:
        ec.message.clearAll()
    }

    def "a tenant translates its own website without naming the owner"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)

        when:
        Map result = create([:])

        then:
        !ec.message.hasError()
        result.websiteTranslation.ownerPartyId == tenantWithKey.companyPartyId
    }

    def "a tenant lists and deletes only its own translations"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)
        String translationId = ec.service.sync()
                .name('growerp.100.WebsiteTranslationServices100.get#WebsiteTranslations').call()
                .websiteTranslations[0].translationId
        ec.user.internalLoginUser(tenantNoKey.username)

        when:
        Map listed = ec.service.sync()
                .name('growerp.100.WebsiteTranslationServices100.get#WebsiteTranslations').call()
        ec.service.sync().name('growerp.100.WebsiteTranslationServices100.delete#WebsiteTranslation')
                .parameters([translationId: translationId]).call()

        then:
        translationId
        !listed.websiteTranslations.find { it.translationId == translationId }
        ec.message.hasError()
        ec.entity.find('growerp.website.WebsiteTranslation').condition('translationId', translationId)
                .useCache(false).one() != null

        cleanup:
        ec.message.clearAll()
    }

    def "the title line of a translated ftl page is put back first"() {
        setup:
        def util = ec.resource.script('component://growerp/service/WebsiteTranslationUtil.groovy', null)
        String source = '<#-- title: About -->\n<!-- description: Who we are -->\n<main>About us</main>'

        expect:
        util.normalizeFtlTitle(source, translated) == expected

        where:
        translated                                                                            || expected
        // the model put the description comment first
        '<!-- description: TH who -->\n<#-- title: TH About -->\n<main>TH</main>'             || '<#-- title: TH About -->\n<!-- description: TH who -->\n<main>TH</main>'
        // a byte order mark or a sentence in front of the file
        '\uFEFF<#-- title: TH About -->\n<main>TH</main>'                                     || '<#-- title: TH About -->\n<main>TH</main>'
        'Here is the translation:\n<#-- title: TH About -->\n<main>TH</main>'                 || '<#-- title: TH About -->\n<main>TH</main>'
        // the model dropped the title: the source title is used untranslated
        '<!-- description: TH who -->\n<main>TH</main>'                                       || '<#-- title: About -->\n<!-- description: TH who -->\n<main>TH</main>'
        // already right
        '<#-- title: TH About -->\n<main>TH</main>'                                           || '<#-- title: TH About -->\n<main>TH</main>'
    }

    def "a source page without a title line is translated as is"() {
        setup:
        def util = ec.resource.script('component://growerp/service/WebsiteTranslationUtil.groovy', null)

        expect:
        util.normalizeFtlTitle('<main>About us</main>', '<main>TH</main>') == '<main>TH</main>'
    }

    def "a failed page does not stop the run and overwrite redoes only changed pages"() {
        setup: 'every source page translated into nl, except one missing and one edited since'
        ec.user.internalLoginUser(tenantWithKey.username)
        Map store = ec.entity.find('mantle.product.store.ProductStore')
                .condition('organizationPartyId', tenantWithKey.companyPartyId).useCache(false).one().getMap()
        List sources = ec.entity.find('growerp.website.ProductStoreAndWebsiteContent')
                .condition('productStoreId', store.productStoreId).useCache(false).list()
                .findAll { it.pagePath && !(it.pagePath.split('/')[0] in ['en', 'th', 'zh', 'de', 'fr', 'nl']) }
        String root = sources[0].rootPageLocation
        def location = { String path ->
            def md = ec.resource.getLocationReference("${root}/content/${path}.md.ftl")
            return md?.exists ? md : ec.resource.getLocationReference("${root}/content/${path}.html.ftl")
        }
        String missing = sources[0].pagePath
        String edited = sources[1].pagePath
        sources.drop(1).each { page ->
            ec.service.sync().name('growerp.100.WebsiteTranslationServices100.store#TranslatedPage')
                    .parameters([productStoreId: store.productStoreId, pagePath: "nl/${page.pagePath}",
                            text: "NL ${page.pagePath}",
                            contentType: location(page.pagePath).fileName.endsWith('.md.ftl') ? 'md' : 'ftl'])
                    .call()
        }
        Thread.sleep(20)
        def editedRef = location(edited)
        editedRef.putText(editedRef.getText() + '\nedited')
        String translationId = ec.entity.sequencedIdPrimary('growerp.website.WebsiteTranslation', null, null)
        ec.entity.makeValue('growerp.website.WebsiteTranslation').setAll([translationId: translationId,
                ownerPartyId: tenantWithKey.companyPartyId, productStoreId: store.productStoreId,
                sourceLocale: 'en', targetLocales: 'nl', translateEntityNames: 'N',
                overwriteExisting: 'Y', status: 'PENDING', createdDate: ec.user.nowTimestamp]).create()

        when: 'the Gemini key is fake, so every page that is translated fails'
        ec.service.sync().name('growerp.100.WebsiteTranslationServices100.process#WebsiteTranslation')
                .parameters([translationId: translationId, username: tenantWithKey.username]).call()
        def translation = ec.entity.find('growerp.website.WebsiteTranslation')
                .condition('translationId', translationId).useCache(false).one()

        then: 'the run went through every page and tried only the missing and the edited one'
        translation.status == 'FAILED'
        translation.translatedCount == sources.size()
        translation.errorMessage.contains("nl/${missing}")
        translation.errorMessage.contains("nl/${edited}")
        sources.drop(2).every { !translation.errorMessage.contains("nl/${it.pagePath}:") }

        cleanup:
        ec.message.clearAll()
    }
}
