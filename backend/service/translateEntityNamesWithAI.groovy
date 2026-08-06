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
 * Translate the store, category and product names a website shows into the target locales and
 * write them as moqui.basic.LocalizedEntityField rows. Reads of the fields listed in
 * entity/LocalizationExtendEntities.xml then resolve through those rows on their own.
 *
 * Names are short, so unlike the pages they go out in batches: one JSON mode call per locale
 * per batch, keyed by index because a name is not unique enough to key on itself.
 *
 * In:  productStoreId, sourceLocale, targetLocales (csv), apiKey, ownerPartyId
 * Out: translatedCount
 */

import groovy.json.JsonOutput
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

final Map LANGUAGE_NAMES = [en: 'English', th: 'Thai', zh: 'Simplified Chinese',
                            de: 'German', fr: 'French', nl: 'Dutch']
final int BATCH_SIZE = 50

def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

// read the source values in the source language, whatever locale this worker thread happens to
// run under: the fields below are localized, so ec.user.locale decides what get() returns
ec.user.setLocale(new Locale(sourceLocale as String))

// --------------------------------------------------------------------------------------
// collect what to translate: [entityName, fieldName, pkValue, text]
// --------------------------------------------------------------------------------------
List items = []
def add = { String entityName, String fieldName, String pkValue, def text ->
    String value = (text ?: '').toString().trim()
    if (value) items.add([entityName: entityName, fieldName: fieldName,
                          pkValue: pkValue, text: value])
}

def store = ec.entity.find('mantle.product.store.ProductStore')
    .condition('productStoreId', productStoreId).disableAuthz().one()
if (store) add('mantle.product.store.ProductStore', 'storeName', productStoreId, store.storeName)

def rows = ec.entity.find('growerp.website.ProductStoreAndWebsiteCategories')
    .condition('productStoreId', productStoreId).disableAuthz().list()

Set seenCategories = [] as Set
Set seenProducts = [] as Set
for (def row in rows) {
    if (row.productCategoryId && seenCategories.add(row.productCategoryId)) {
        def category = ec.entity.find('mantle.product.category.ProductCategory')
            .condition('productCategoryId', row.productCategoryId).disableAuthz().one()
        if (category) {
            add('mantle.product.category.ProductCategory', 'categoryName',
                row.productCategoryId, category.categoryName)
            add('mantle.product.category.ProductCategory', 'description',
                row.productCategoryId, category.description)
        }
    }
    if (row.productId && seenProducts.add(row.productId)) {
        def product = ec.entity.find('mantle.product.Product')
            .condition('productId', row.productId).disableAuthz().one()
        if (product) {
            add('mantle.product.Product', 'productName', row.productId, product.productName)
            add('mantle.product.Product', 'description', row.productId, product.description)
        }
    }
}

if (!items) {
    translatedCount = 0
    return
}

// --------------------------------------------------------------------------------------
// translate and store, per locale, in batches
// --------------------------------------------------------------------------------------
String sourceName = LANGUAGE_NAMES[sourceLocale as String] ?: (sourceLocale as String)
List locales = (targetLocales as String).split(',').collect { it.trim() }.findAll { it }
int stored = 0

for (String locale in locales) {
    String targetName = LANGUAGE_NAMES[locale] ?: locale
    items.collate(BATCH_SIZE).each { batch ->
        Map toTranslate = [:]
        batch.eachWithIndex { item, index -> toTranslate["${index}".toString()] = item.text }

        String prompt = """
Translate these ${sourceName} website labels into ${targetName}.

They are the store name, the product category names and the product names and short
descriptions of a company web shop, so they have to read as a native ${targetName} shop
would write them.

Leave brand names, product codes, model numbers, units of measure and anything that is
clearly a proper name exactly as it is: a customer searching for the product has to
recognise it. When a whole label is such a name, return it unchanged.

Return a JSON object with exactly the same keys as the input and the translated text as the
values. No extra keys, no commentary.

INPUT:
${JsonOutput.toJson(toTranslate)}
"""
        String raw = GeminiAiUtil.callGeminiApi(ec, prompt,
            [apiKey: apiKey, ownerPartyId: ownerPartyId, jsonMode: true,
             temperature: 0.2, maxOutputTokens: 8192])
        Map translated = GeminiAiUtil.parseJsonResponse(raw) as Map
        if (!translated) {
            throw new Exception("The AI returned no ${targetName} translation for the names")
        }

        batch.eachWithIndex { item, index ->
            String value = (translated["${index}".toString()] ?: '').toString().trim()
            if (!value) return
            ec.service.sync().name('store#moqui.basic.LocalizedEntityField')
                .parameters([entityName: item.entityName, fieldName: item.fieldName,
                             pkValue: item.pkValue, locale: locale, localized: value])
                .disableAuthz().call()
            stored++
        }
    }
}

// the rendered pages carry these names, so the SEO copies of them are stale now
ec.cache.getCache('growerp.seo.page').clear()
ec.cache.getCache('growerp.seo.index').clear()

translatedCount = stored
