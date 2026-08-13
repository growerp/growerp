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

/**
 * Rebuild an owner-import XML document from a website that is live in this installation, so it
 * can be installed on another one with import#WebsiteOwner. Reads the CURRENT content, so pages
 * edited afterwards in the admin app's Website dialog are included.
 *
 * Works for any website, whoever made it: the AI generator, the /convert-website skill, or by
 * hand in the Website dialog.
 *
 * In:  productStoreId (required), siteId (optional, defaults to a name from the company),
 *      adminEmail/adminFirstName/adminLastName (optional overrides for the target installation)
 * Out: xmlText, fileName, pageCount, imageCount
 */

import groovy.json.JsonOutput
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

def cdata = { String text -> "<![CDATA[${(text ?: '').replace(']]>', ']]]]><![CDATA[>')}]]>" }
def xmlAttr = { String text ->
    (text ?: '').replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
}
def shortId = { String value -> value.length() > 40 ? value.substring(0, 40) : value }

try {
    def store = ec.entity.find("mantle.product.store.ProductStore")
        .condition("productStoreId", productStoreId).disableAuthz().one()
    if (!store) throw new Exception("Store ${productStoreId} not found")
    if (!store.wikiSpaceId) throw new Exception("Store ${productStoreId} has no website")

    def company = ec.entity.find("mantle.party.Organization")
        .condition("partyId", store.organizationPartyId).disableAuthz().one()
    String companyName = company?.organizationName ?: store.storeName

    // ---- site id: uppercase, unique per file, not per installation -------------------------
    String id = (siteId ?: companyName.toUpperCase().replaceAll(/[^A-Z0-9]/, ''))
    if (id.length() > 12) id = id.substring(0, 12)
    if (!id) id = 'SITE'
    String low = id.toLowerCase()

    // ---- the content tree of this store -----------------------------------------------------
    def contentSetting = ec.entity.find("mantle.product.store.ProductStoreSetting")
        .condition("productStoreId", productStoreId)
        .condition("settingTypeEnumId", "PsstContentLocation").disableAuthz().one()
    String rootLocation = contentSetting?.settingValue
    if (!rootLocation) throw new Exception("Store ${productStoreId} has no content location")

    def rootRef = ec.resource.getLocationReference(rootLocation)
    if (rootRef == null || !rootRef.exists) throw new Exception("Content ${rootLocation} not found")

    // published pages of the wiki space, in menu order
    def wikiPages = ec.entity.find("moqui.resource.wiki.WikiPage")
        .condition("wikiSpaceId", store.wikiSpaceId).orderBy("sequenceNum")
        .disableAuthz().list()
    if (!wikiPages) throw new Exception("Website of store ${productStoreId} has no pages")

    long stamp = System.currentTimeMillis()
    StringBuilder xml = new StringBuilder()
    xml.append('<?xml version="1.0" encoding="UTF-8"?>\n')
    xml.append("<!-- ${xmlAttr(companyName)} website, exported from this GrowERP installation\n")
    xml.append("     (store ${productStoreId}) on ${new Date()}.\n")
    xml.append("     Install elsewhere with:\n")
    xml.append("        growerp.100.ImportExportServices100.import#WebsiteOwner\n")
    xml.append("            location=component://growerp/data/${id.toLowerCase().capitalize()}OwnerImportData.xml siteId=${id} -->\n")
    xml.append('<entity-facade-xml type="demo">\n\n')

    xml.append("""    <moqui.resource.DbResource filename="${id}_ROOT" isFile="N" resourceId="${id}_ROOT" parentResourceId=""/>\n""")
    xml.append("""    <moqui.resource.DbResource filename="content" isFile="N" resourceId="${low}_content_dir" parentResourceId="${id}_ROOT"/>\n""")
    xml.append("""    <moqui.resource.DbResource filename="images" isFile="N" resourceId="${id}_IMAGES" parentResourceId="${id}_ROOT"/>\n""")

    // one directory per two level page path group
    Set groups = new LinkedHashSet()
    wikiPages.each { page ->
        List parts = (page.pagePath as String).tokenize('/')
        if (parts.size() > 1) groups.add(parts[0])
    }
    groups.each { String g ->
        xml.append("""    <moqui.resource.DbResource filename="${g}" isFile="N" resourceId="${shortId("${low}_${g.replaceAll(/[^a-zA-Z0-9]/, '')}_dir")}" parentResourceId="${low}_content_dir"/>\n""")
    }

    xml.append("""\n    <moqui.resource.wiki.WikiSpace wikiSpaceId="${id}_WS" description="${xmlAttr(companyName)} Website Content"\n""")
    xml.append("""        allowAnyHtml="Y" rootPageLocation="dbresource://${id}_ROOT"/>\n\n""")

    // ---- pages -------------------------------------------------------------------------------
    int pageNum = 0
    wikiPages.each { page ->
        String pagePath = page.pagePath as String
        if (!pagePath || pagePath == '==temp==') return
        // the page content lives in the DbResource with the same id as the wiki page
        def resource = ec.entity.find("moqui.resource.DbResource")
            .condition("resourceId", page.wikiPageId).disableAuthz().one()
        String fileName = resource?.filename
        String text = null
        if (fileName) {
            def ref = ec.resource.getLocationReference("${rootLocation}/content/" +
                (pagePath.contains('/') ? "${pagePath.tokenize('/')[0]}/" : '') + fileName)
            if (ref?.exists) text = ref.getText()
        }
        if (text == null) {
            // fall back to the file rows directly, the folder layout may differ
            def dbrf = ec.entity.find("moqui.resource.DbResourceFile")
                .condition("resourceId", page.wikiPageId).disableAuthz().one()
            def blob = dbrf?.getSerialBlob("fileData")
            if (blob != null) text = new String(blob.getBytes(1, (int) blob.length()), "UTF-8")
        }
        if (!text) {
            ec.logger.warn("exportWebsiteOwner: no content for page ${pagePath}, skipped")
            return
        }

        List parts = pagePath.tokenize('/')
        String parentDir = parts.size() > 1 ?
            shortId("${low}_${parts[0].replaceAll(/[^a-zA-Z0-9]/, '')}_dir") : "${low}_content_dir"
        String pageId = shortId("${low}_${pageNum}_${pagePath.replaceAll(/[^a-zA-Z0-9]/, '_')}")
        String outName = fileName ?: "${parts.last()}.html.ftl"
        String mime = outName.endsWith('.md.ftl') ? 'text/markdown' : 'text/html'

        xml.append("""    <moqui.resource.wiki.WikiPage wikiPageId="${pageId}" wikiSpaceId="${id}_WS" pagePath="${xmlAttr(pagePath)}"\n""")
        xml.append("""        publishedVersionName="01" sequenceNum="${page.sequenceNum ?: (pageNum + 1)}">\n""")
        xml.append("""        <histories historySeqId="01" versionName="01" changeDateTime="${stamp}"/>\n""")
        xml.append("""    </moqui.resource.wiki.WikiPage>\n""")
        xml.append("""    <moqui.resource.DbResource filename="${outName}" isFile="Y" resourceId="${pageId}"\n""")
        xml.append("""        parentResourceId="${parentDir}">\n""")
        xml.append("""        <file mimeType="${mime}" versionName="01" rootVersionName="01">\n""")
        xml.append("""            <fileData>${cdata(text)}</fileData>\n""")
        xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
        xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")
        pageNum++
    }

    // ---- theme --------------------------------------------------------------------------------
    def colorRef = ec.resource.getLocationReference("${rootLocation}/content/websiteColor.json")
    if (colorRef?.exists) {
        xml.append("""    <moqui.resource.DbResource filename="websiteColor.json" isFile="Y" resourceId="${low}_website_color"\n""")
        xml.append("""        parentResourceId="${low}_content_dir">\n""")
        xml.append("""        <file mimeType="application/json" versionName="01" rootVersionName="01">\n""")
        xml.append("""            <fileData>${cdata(colorRef.getText())}</fileData>\n""")
        xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
        xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")
    }

    // ---- images: the logo plus everything served through /getImage -----------------------------
    int imageNum = 0
    String logoPath = null
    // filename is unique per directory, and the logo usually appears twice: once as the
    // company logo and once in the store image list
    Map usedNames = [:]
    def addImage = { String location, String preferredName ->
        def ref = ec.resource.getLocationReference(location)
        if (ref == null || !ref.exists) return null
        byte[] bytes = ref.openStream()?.bytes
        if (bytes == null || bytes.length == 0) return null
        String name = preferredName.toLowerCase().replaceAll(/[^a-z0-9.-]+/, '-')
        if (usedNames.containsKey(name)) {
            if (usedNames[name] == location) return name // the very same image, keep one copy
            String stem = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name
            String ext = name.contains('.') ? name.substring(name.lastIndexOf('.')) : ''
            int n = 2
            while (usedNames.containsKey("${stem}-${n}${ext}")) n++
            name = "${stem}-${n}${ext}"
        }
        usedNames[name] = location
        String mime = name.endsWith('.png') ? 'image/png' : name.endsWith('.gif') ? 'image/gif' :
            name.endsWith('.svg') ? 'image/svg+xml' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg'
        String resId = "${id}_IMG_${imageNum++}"
        xml.append("""    <moqui.resource.DbResource filename="${name}" isFile="Y" resourceId="${resId}"\n""")
        xml.append("""        parentResourceId="${id}_IMAGES"/>\n""")
        xml.append("""    <moqui.resource.DbResourceFile resourceId="${resId}" rootVersionName="01"\n""")
        xml.append("""        versionName="01" mimeType="${mime}">\n""")
        xml.append("""        <fileData><![CDATA[${bytes.encodeBase64().toString()}]]></fileData>\n""")
        xml.append("""    </moqui.resource.DbResourceFile>\n""")
        return name
    }

    def logoContent = ec.entity.find("mantle.party.PartyContent")
        .condition("partyId", store.organizationPartyId)
        .condition("partyContentTypeEnumId", "PcntLogoImage").disableAuthz().list()
    if (logoContent) {
        String loc = logoContent[0].contentLocation
        String base = loc.tokenize('/').last()
        if (!base.contains('.')) base = "${base}.png"
        String stored = addImage(loc, base)
        if (stored) logoPath = "images/${stored}"
    }

    def storeContents = ec.entity.find("growerp.store.ProductStoreContent")
        .condition("productStoreId", productStoreId)
        .condition("contentTypeEnumId", "PrstImageLarge").disableAuthz().list()
    storeContents.each { content ->
        String desc = (content.description ?: '') as String
        if (!desc.startsWith('images/')) return // obsidian and legacy entries stay out
        addImage(content.contentLocation as String, desc.substring('images/'.length()))
    }

    // ---- owner spec ----------------------------------------------------------------------------
    def hostSettings = ec.entity.find("mantle.product.store.ProductStoreSetting")
        .condition("productStoreId", productStoreId)
        .condition("settingTypeEnumId", "PsstHostname").orderBy("fromDate").disableAuthz().list()
    List hosts = hostSettings.collect { it.settingValue as String }.findAll {
        // a test name on this installation is meaningless on the next one
        it && !it.contains('localhost')
    }

    def acctg = ec.entity.find("mantle.ledger.config.PartyAcctgPreference")
        .condition("organizationPartyId", store.organizationPartyId).disableAuthz().one()

    // PartyContactMech carries the purpose, the details live in the type specific entity
    def contactMechIdFor = { String purpose ->
        def rows = ec.entity.find("mantle.party.contact.PartyContactMech")
            .condition("partyId", store.organizationPartyId)
            .condition("contactMechPurposeId", purpose)
            .conditionDate("fromDate", "thruDate", ec.user.nowTimestamp)
            .disableAuthz().list()
        return rows ? rows[0].contactMechId : null
    }

    Map contact = [:]
    String emailId = contactMechIdFor('EmailPrimary')
    if (emailId) {
        def mech = ec.entity.find("mantle.party.contact.ContactMech")
            .condition("contactMechId", emailId).disableAuthz().one()
        if (mech?.infoString) contact.email = mech.infoString
    }
    String phoneId = contactMechIdFor('PhonePrimary')
    if (phoneId) {
        def tel = ec.entity.find("mantle.party.contact.TelecomNumber")
            .condition("contactMechId", phoneId).disableAuthz().one()
        if (tel) {
            contact.telephone = [countryCode: tel.countryCode ?: '',
                                 areaCode: tel.areaCode ?: '',
                                 contactNumber: tel.contactNumber ?: '']
        }
    }
    String postalId = contactMechIdFor('PostalPrimary')
    if (postalId) {
        def postal = ec.entity.find("mantle.party.contact.PostalAddress")
            .condition("contactMechId", postalId).disableAuthz().one()
        if (postal) {
            contact.address = [address1: postal.address1 ?: '',
                               address2: postal.address2 ?: '',
                               city: postal.city ?: '',
                               postalCode: postal.postalCode ?: '',
                               stateProvinceGeoId: postal.stateProvinceGeoId ?: '',
                               countryGeoId: postal.countryGeoId ?: '']
        }
    }

    Map spec = [adminEmail: adminEmail ?: '', adminFirstName: adminFirstName ?: 'Site',
                adminLastName: adminLastName ?: 'Administrator',
                companyName: companyName,
                currencyId: acctg?.baseCurrencyUomId ?: store.defaultCurrencyUomId ?: 'USD',
                fiscalYearStartMonth: (acctg?.fiscalYearStartMonth ?: 1) as Integer,
                applicationId: 'AppAdmin', hostNames: hosts]
    if (logoPath) spec.logoPath = logoPath
    if (contact) spec.contact = contact

    xml.append("""\n    <moqui.resource.DbResource filename="ownerSpec.json" isFile="Y"\n""")
    xml.append("""        resourceId="${id}_OWNER_SPEC" parentResourceId="${id}_ROOT">\n""")
    xml.append("""        <file mimeType="application/json" versionName="01" rootVersionName="01">\n""")
    xml.append("""            <fileData>${cdata(JsonOutput.prettyPrint(JsonOutput.toJson(spec)))}</fileData>\n""")
    xml.append("""            <histories versionName="01" versionDate="${stamp}" isDiff="N"/>\n""")
    xml.append("""        </file>\n    </moqui.resource.DbResource>\n\n""")
    xml.append('</entity-facade-xml>\n')

    xmlText = xml.toString()
    fileName = "${companyName.replaceAll(/[^A-Za-z0-9]/, '')}OwnerImportData.xml"
    pageCount = pageNum
    imageCount = imageNum
    ec.logger.info("exportWebsiteOwner: store ${productStoreId} -> ${pageCount} pages, ${imageCount} images, ${xmlText.length()} chars")
} catch (Exception e) {
    ec.logger.error("exportWebsiteOwner failed for store ${productStoreId}: ${e.message}", e)
    ec.message.addError("Website export failed: ${e.message}")
}
