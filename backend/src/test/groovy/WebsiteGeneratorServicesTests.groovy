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

/* Tests for WebsiteGeneratorServices100, the website conversion of a tenant (issue #30):
   - a tenant converts into its own store, never into a new tenant
   - a tenant needs its own Gemini key, the system key is for support only
   - replace#StoreWebsite installs the generated site and deletes the old one

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class WebsiteGeneratorServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(WebsiteGeneratorServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenantNoKey
    @Shared Map tenantWithKey

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenantNoKey = GrowerpTestSupport.tenant(ec, 'WsGenNoKey')
        tenantWithKey = GrowerpTestSupport.tenant(ec, 'WsGenKey')
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

    private Map store(Map tenant) {
        Map store = ec.entity.find('mantle.product.store.ProductStore')
                .condition('organizationPartyId', tenant.companyPartyId).useCache(false).one().getMap()
        store.contentLocation = ec.entity.find('mantle.product.store.ProductStoreSetting')
                .condition([productStoreId: store.productStoreId, settingTypeEnumId: 'PsstContentLocation'] as Map)
                .orderBy('-fromDate').useCache(false).list().first.settingValue
        return store
    }

    def "a tenant without its own Gemini key cannot convert a website"() {
        setup:
        ec.user.internalLoginUser(tenantNoKey.username)

        when:
        ec.service.sync().name('growerp.100.WebsiteGeneratorServices100.create#WebsiteConversion')
                .parameters([sourceUrl: 'http://localhost:1/', maxPages: 6]).call()

        then: 'the system key is not used for a tenant'
        ec.message.hasError()
        ec.message.errorsString.contains('No Gemini API key configured for your company')

        cleanup:
        ec.message.clearAll()
    }

    def "a tenant conversion targets its own store, not a new tenant"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)
        String storeId = store(tenantWithKey).productStoreId

        when: 'only the source url is given, even asking for a new tenant'
        Map result = ec.service.sync().name('growerp.100.WebsiteGeneratorServices100.create#WebsiteConversion')
                .parameters([sourceUrl: 'http://localhost:1/', maxPages: 6, targetStore: false]).call()

        then:
        !ec.message.hasError()
        result.websiteConversion.targetStore == 'Y'
        result.websiteConversion.productStoreId == storeId
        !result.websiteConversion.adminEmail
        !result.websiteConversion.hostNames
    }

    def "a tenant cannot list or delete conversions of another owner"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)
        String conversionId = ec.service.sync()
                .name('growerp.100.WebsiteGeneratorServices100.get#WebsiteConversions').call()
                .websiteConversions[0].conversionId
        ec.user.internalLoginUser(tenantNoKey.username)

        when:
        Map listed = ec.service.sync()
                .name('growerp.100.WebsiteGeneratorServices100.get#WebsiteConversions').call()
        ec.service.sync().name('growerp.100.WebsiteGeneratorServices100.delete#WebsiteConversion')
                .parameters([conversionId: conversionId]).call()

        then:
        !listed.websiteConversions.find { it.conversionId == conversionId }
        ec.message.hasError()
        ec.entity.find('growerp.website.WebsiteConversion').condition('conversionId', conversionId)
                .useCache(false).one() != null

        cleanup:
        ec.message.clearAll()
    }

    def "replace#StoreWebsite installs the new website and deletes the old one"() {
        setup:
        ec.user.internalLoginUser(tenantWithKey.username)
        Map before = store(tenantWithKey)
        String oldRootId = before.contentLocation.substring('dbresource://'.length())
        String siteId = "SPK${System.currentTimeMillis()}"

        expect: 'the tenant has its own copy of the default website'
        oldRootId != 'DEFAULT_ROOT'
        ec.entity.find('moqui.resource.DbResource').condition('resourceId', oldRootId).one() != null

        when:
        ec.service.sync().name('growerp.100.WebsiteGeneratorServices100.replace#StoreWebsite')
                .parameters([productStoreId: before.productStoreId, siteId: siteId,
                        xmlText: siteXml(siteId)]).call()
        Map after = store(tenantWithKey)

        then: 'the store serves the new website'
        !ec.message.hasError()
        after.wikiSpaceId == "${siteId}_WS"
        after.contentLocation == "dbresource://${siteId}_ROOT"
        ec.entity.find('growerp.website.ProductStoreAndWebsiteContent')
                .condition('productStoreId', before.productStoreId).useCache(false).list()
                .collect { it.pagePath }.contains('home')
        ec.entity.find('growerp.store.ProductStoreContent')
                .condition('productStoreId', before.productStoreId).useCache(false).list()
                .collect { it.contentLocation }.contains("dbresource://${siteId}_ROOT/images/logo.png" as String)

        and: 'the old website is gone'
        ec.entity.find('moqui.resource.wiki.WikiSpace').condition('wikiSpaceId', before.wikiSpaceId)
                .useCache(false).one() == null
        ec.entity.find('moqui.resource.wiki.WikiPage').condition('wikiSpaceId', before.wikiSpaceId)
                .useCache(false).count() == 0
        ec.entity.find('moqui.resource.DbResource').condition('resourceId', oldRootId)
                .useCache(false).one() == null
        ec.entity.find('moqui.resource.DbResource').condition('parentResourceId', oldRootId)
                .useCache(false).count() == 0
        ec.entity.find('growerp.store.ProductStoreContent')
                .condition('productStoreId', before.productStoreId).useCache(false).list()
                .every { !it.contentLocation?.startsWith(before.contentLocation as String) }

        and: 'the shared default website is untouched'
        ec.entity.find('moqui.resource.DbResource').condition('resourceId', 'DEFAULT_ROOT')
                .useCache(false).one() != null
        ec.entity.find('moqui.resource.wiki.WikiSpace').condition('wikiSpaceId', 'DEFAULT_WS')
                .useCache(false).one() != null
    }

    /** a minimal generated website, the same shape generateWebsiteWithAI.groovy writes */
    private static String siteXml(String id) {
        String low = id.toLowerCase()
        String png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
        return """<?xml version="1.0" encoding="UTF-8"?>
<entity-facade-xml type="seed">
    <moqui.resource.DbResource filename="${id}_ROOT" isFile="N" resourceId="${id}_ROOT" parentResourceId=""/>
    <moqui.resource.DbResource filename="content" isFile="N" resourceId="${low}_content_dir" parentResourceId="${id}_ROOT"/>
    <moqui.resource.DbResource filename="images" isFile="N" resourceId="${id}_IMAGES" parentResourceId="${id}_ROOT"/>
    <moqui.resource.wiki.WikiSpace wikiSpaceId="${id}_WS" description="Spock Website Content"
        allowAnyHtml="Y" rootPageLocation="dbresource://${id}_ROOT"/>
    <moqui.resource.wiki.WikiPage wikiPageId="${id}_HOME" wikiSpaceId="${id}_WS" pagePath="home"
        publishedVersionName="01"/>
    <moqui.resource.DbResource filename="home.md.ftl" isFile="Y" resourceId="${id}_HOME"
        parentResourceId="${low}_content_dir"/>
    <moqui.resource.DbResourceFile resourceId="${id}_HOME" rootVersionName="01" mimeType="text/markdown">
        <fileData><![CDATA[# Home]]></fileData>
    </moqui.resource.DbResourceFile>
    <moqui.resource.DbResource filename="logo.png" isFile="Y" resourceId="${id}_LOGO"
        parentResourceId="${id}_IMAGES"/>
    <moqui.resource.DbResourceFile resourceId="${id}_LOGO" rootVersionName="01" mimeType="image/png">
        <fileData><![CDATA[${png}]]></fileData>
    </moqui.resource.DbResourceFile>
    <moqui.resource.DbResource filename="ownerSpec.json" isFile="Y" resourceId="${id}_SPEC"
        parentResourceId="${id}_ROOT"/>
    <moqui.resource.DbResourceFile resourceId="${id}_SPEC" rootVersionName="01" mimeType="application/json">
        <fileData><![CDATA[{"companyName": "Spock", "currencyId": "USD", "logoPath": "images/logo.png"}]]></fileData>
    </moqui.resource.DbResourceFile>
</entity-facade-xml>
"""
    }
}
