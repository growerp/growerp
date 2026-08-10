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
 * Translate the ledger texts - the distinct GL account names plus the account class and account
 * type descriptions - into the target locale and write them as moqui.basic.LocalizedMessage rows,
 * keyed on the text itself. AccountingServices100 reads them back with ec.l10n.localize().
 *
 * Text keyed rather than per glAccountId: every company clones the same chart of accounts, and
 * a company that uploaded its own chart stored those names in the language it was working in,
 * so one row per distinct name serves every company that uses that name. The class and type
 * descriptions are shared enumerations, so they are text keyed by nature.
 *
 * Names already having a row for a locale are skipped, so a rerun only fills the gaps and
 * names uploaded later cost one batch instead of the whole chart.
 *
 * In:  sourceLocale, targetLocale, apiKey, ownerPartyId
 * Out: translatedCount
 */

import groovy.json.JsonOutput
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityCondition

ExecutionContext ec = context.ec ?: context

final Map LANGUAGE_NAMES = [en: 'English', th: 'Thai', zh: 'Simplified Chinese',
                            de: 'German', fr: 'French', nl: 'Dutch']
final int BATCH_SIZE = 50

def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)

List names = ec.service.sync()
    .name('growerp.100.GlAccountTranslationServices100.get#LedgerTexts')
    .disableAuthz().call()?.ledgerTexts ?: []

if (!names) {
    translatedCount = 0
    return
}

String sourceName = LANGUAGE_NAMES[sourceLocale as String] ?: (sourceLocale as String)
String locale = targetLocale as String
String targetName = LANGUAGE_NAMES[locale] ?: locale
int stored = 0

// only the names that have no translation yet for this locale
Set done = [] as Set
names.collate(200).each { batch ->
    ec.entity.find('moqui.basic.LocalizedMessage').condition('locale', locale)
        .condition('original', EntityCondition.IN, batch)
        .selectField('original').disableAuthz().list().each { done.add(it.original) }
}
List todo = names.findAll { !done.contains(it) }

todo.collate(BATCH_SIZE).each { batch ->
    Map toTranslate = [:]
    batch.eachWithIndex { name, index -> toTranslate["${index}".toString()] = name }

    String prompt = """
Translate these ${sourceName} general ledger labels into ${targetName}.

They are the account names of a chart of accounts and the classifications those accounts are
grouped by, such as Assets, Current Assets or Revenue, so use the wording an accountant in the
${targetName} language would find in a standard chart of accounts, not a literal translation.

Leave account code fragments, abbreviations and legal or product names as they are: 401k,
VAT, NSF, COGS, WIP and the like stay untouched. When a name is already ${targetName}, return
it unchanged.

Return a JSON object with exactly the same keys as the input and the translated name as the
values. No extra keys, no commentary.

INPUT:
${JsonOutput.toJson(toTranslate)}
"""
    String raw = GeminiAiUtil.callGeminiApi(ec, prompt,
        [apiKey: apiKey, ownerPartyId: ownerPartyId, jsonMode: true,
         temperature: 0.2, maxOutputTokens: 8192])
    Map translated = GeminiAiUtil.parseJsonResponse(raw) as Map
    if (!translated) {
        throw new Exception("The AI returned no ${targetName} translation for the account names")
    }

    batch.eachWithIndex { name, index ->
        String value = (translated["${index}".toString()] ?: '').toString().trim()
        if (!value) return
        ec.service.sync().name('store#moqui.basic.LocalizedMessage')
            .parameters([original: name, locale: locale, localized: value])
            .disableAuthz().call()
        stored++
    }
}

translatedCount = stored
