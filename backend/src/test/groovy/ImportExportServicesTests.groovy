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

/* Tests for ImportExportServices100:
   - import#WebsiteOwner creates a new owner serving the website of the file

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class ImportExportServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(ImportExportServicesTests.class)
    @Shared ExecutionContext ec

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        GrowerpTestSupport.tenant(ec, 'ImportExport')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
    }

    def "import#WebsiteOwner creates an owner that serves the website of the file"() {
        setup:
        String id = "IMP${System.currentTimeMillis()}"
        String email = "${id.toLowerCase()}@spock.example.com"
        String host = "${id.toLowerCase()}.spock.example.com"

        when:
        Map result = ec.service.sync().name('growerp.100.ImportExportServices100.import#WebsiteOwner')
                .parameters([siteId: id, xmlText: ownerXml(id, email, host)]).call()
        Map store = ec.entity.find('mantle.product.store.ProductStore')
                .condition('productStoreId', result.productStoreId).useCache(false).one()?.getMap()
        Map settings = ec.entity.find('mantle.product.store.ProductStoreSetting')
                .condition('productStoreId', result.productStoreId).useCache(false).list()
                .groupBy { it.settingTypeEnumId }

        then:
        !ec.message.hasError()
        result.ownerPartyId && result.password
        store.storeName == 'Import Spock'
        store.wikiSpaceId == "${id}_WS"
        settings.PsstTemplateId*.settingValue == ['modern']
        settings.PsstContentLocation*.settingValue.every { it == "dbresource://${id}_ROOT" }
        settings.PsstHostname*.settingValue.contains(host)
        ec.entity.find('growerp.store.ProductStoreContent')
                .condition('productStoreId', result.productStoreId).useCache(false).list()
                .collect { it.contentLocation }.contains("dbresource://${id}_ROOT/images/logo.png" as String)
        ec.entity.find('mantle.party.PartyContent')
                .condition([partyId: result.companyPartyId, partyContentTypeEnumId: 'PcntLogoImage'] as Map)
                .useCache(false).list().collect { it.contentLocation }
                .contains("dbresource://${id}_ROOT/images/logo.png" as String)
    }

    /** a minimal owner-import file, the same shape generateWebsiteWithAI.groovy writes */
    private static String ownerXml(String id, String email, String host) {
        String low = id.toLowerCase()
        String png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
        return """<?xml version="1.0" encoding="UTF-8"?>
<entity-facade-xml type="seed">
    <moqui.resource.DbResource filename="${id}_ROOT" isFile="N" resourceId="${id}_ROOT" parentResourceId=""/>
    <moqui.resource.DbResource filename="content" isFile="N" resourceId="${low}_content_dir" parentResourceId="${id}_ROOT"/>
    <moqui.resource.DbResource filename="images" isFile="N" resourceId="${id}_IMAGES" parentResourceId="${id}_ROOT"/>
    <moqui.resource.wiki.WikiSpace wikiSpaceId="${id}_WS" description="Import Spock Website Content"
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
        <fileData><![CDATA[{"adminEmail": "${email}", "companyName": "Import Spock", "currencyId": "USD",
            "hostNames": ["${host}"], "logoPath": "images/logo.png"}]]></fileData>
    </moqui.resource.DbResourceFile>
</entity-facade-xml>
"""
    }
}
