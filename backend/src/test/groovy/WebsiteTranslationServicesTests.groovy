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
}
