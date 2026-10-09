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

/*
 * write#ArticleFromIdea: turn a ContentIdea (pasted text and/or an article URL, both used when
 * both are given) into a ~500 word article in the house voice, stored as a DRAFT MasterContent
 * ARTICLE in teaser mode. Its targetUrl is the website page under content/_articles/ that
 * publish#ArticlePage writes once the piece is approved.
 */

import groovy.json.JsonSlurper
import org.jsoup.Jsoup
import org.moqui.context.ExecutionContext

ExecutionContext ec = context.ec ?: context

def owner = ec.service.sync().name("growerp.100.GeneralServices100.get#RelatedCompanyAndOwner").call()
String ownerPartyId = owner.ownerPartyId
if (!ownerPartyId) { ec.message.addError("User not authenticated or no party associated"); return }

def idea = ec.entity.find("growerp.marketing.ContentIdea").condition("ideaId", ideaId).one()
if (!idea || idea.ownerPartyId != ownerPartyId) { ec.message.addError("Content idea not found"); return }

// ---- material: the pasted text and the fetched article, both when both are given
List<String> material = []
if (idea.rawText?.trim()) material.add("TEXT / NOTES FROM THE USER:\n" + idea.rawText.trim())
if (idea.sourceUrl) {
    String url = idea.sourceUrl.trim()
    try {
        // no fetching of internal addresses: the url comes from a user
        def host = new URI(url).getHost()
        def addr = host ? InetAddress.getByName(host) : null
        if (!(url ==~ /(?i)https?:\/\/.+/) || addr == null || addr.isLoopbackAddress() ||
                addr.isSiteLocalAddress() || addr.isLinkLocalAddress() || addr.isAnyLocalAddress()) {
            ec.message.addError("The article URL ${url} cannot be fetched (not a public web address)")
            return
        }
        def doc = Jsoup.connect(url).userAgent("Mozilla/5.0 (compatible; GrowERP article reader)")
            .timeout(20000).maxBodySize(3 * 1024 * 1024).get()
        doc.select("script, style, nav, header, footer, aside, form, noscript").remove()
        def main = doc.selectFirst("article") ?: doc.selectFirst("main") ?: doc.body()
        String text = main?.text()?.trim() ?: ''
        if (text.length() > 15000) text = text.substring(0, 15000)
        if (text) material.add("ARTICLE FROM ${url} (title: ${doc.title()}):\n" + text)
        else if (!material) { ec.message.addError("No readable text found at ${url}"); return }
    } catch (Exception e) {
        ec.logger.warn("write#ArticleFromIdea could not fetch ${url}: ${e.message}")
        if (!material) { ec.message.addError("Could not read the article at ${url}: ${e.message}"); return }
    }
}
// a one-line idea alone is material too
if (!material && idea.title?.trim()) material.add("IDEA FROM THE USER:\n" + idea.title.trim())
if (!material) { ec.message.addError("The idea has no text and no article URL"); return }

// ---- persona: the given one, else the owner's first
def persona = personaId ? ec.entity.find("growerp.marketing.MarketingPersona")
        .condition("personaId", personaId).condition("ownerPartyId", ownerPartyId).one() :
    ec.entity.find("growerp.marketing.MarketingPersona").condition("ownerPartyId", ownerPartyId)
        .orderBy("createdDate").list()?.find { true }
def personaBlock = persona ? """CUSTOMER AVATAR (write for this reader):
Name: ${persona.name}
Demographics: ${persona.demographics}
Pain Points: ${persona.painPoints}
Goals: ${persona.goals}
""" : ""

def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
String thePnp = (pnpType ?: 'OTHER').toUpperCase()
def prompt = """
Write ONE website article of about 500 words (between 450 and 550) based on the material below.
${personaBlock}
ANGLE (Pain-News-Prize): ${thePnp}
${idea.title ? "WORKING TITLE / IDEA: ${idea.title}\n" : ''}
MATERIAL:
${material.join('\n\n')}

HOUSE VOICE (how it must sound):
${GeminiAiUtil.houseVoice(ec, ownerPartyId)}

RULES:
- Use ALL the material given: when there are notes and an article, combine them; the notes show
  the user's own point of view and win where they disagree with the article.
- Write it in your own words; never copy sentences from a third-party article.
${idea.sourceUrl ? "- The material includes an article by someone else: end with one line 'Source: ${idea.sourceUrl}'.\n" : ''}- Only state facts, numbers and names that are in the material; do not invent any.
- Markdown body: short paragraphs, 2-4 '## ' subheadings, no '# ' heading (the title is separate),
  no hashtags, no emojis.
- End with what the reader can do next.

RETURN FORMAT: Return ONLY valid JSON (no markdown fences) with this exact structure:
{
  "title": "A specific, compelling title (max 80 characters)",
  "body": "The markdown article body",
  "callToAction": "One-line call to action"
}
"""
String generated = GeminiAiUtil.callLlmApi(ec, prompt,
    [ownerPartyId: ownerPartyId, temperature: 0.7, maxOutputTokens: 4096])
generated = generated?.replaceAll(/```json\s*/, '')?.replaceAll(/```\s*$/, '')?.replaceAll(/^```\s*/, '')?.trim()
def data
try { data = new JsonSlurper().parseText(generated) }
catch (Exception e) { ec.message.addError("The AI did not return a usable article, try again"); return }
if (!data?.title || !data?.body) { ec.message.addError("The AI did not return a usable article, try again"); return }
// plain markdown only: create#MasterContent rejects html, and the page must not carry markup
data.title = data.title.toString().replaceAll(/<[^>]*>/, '').trim()
data.body = data.body.toString().replaceAll(/<[^>]*>/, '')
data.callToAction = data.callToAction?.toString()?.replaceAll(/<[^>]*>/, '')

// ---- the website page the article will live on (written on approval)
String slug = data.title.toString().toLowerCase().replaceAll(/[^a-z0-9]+/, '-')
    .replaceAll(/^-+|-+$/, '')
if (slug.length() > 60) slug = slug.substring(0, 60).replaceAll(/-+$/, '')
if (!slug) slug = 'article'
String articlePath = "_articles/${slug}"
int n = 2
while (ec.entity.find("growerp.marketing.MasterContent").condition("ownerPartyId", ownerPartyId)
        .condition("articlePath", articlePath).count() > 0) {
    articlePath = "_articles/${slug}-${n++}"
}
def website = ec.service.sync().name("growerp.100.WebsiteServices100.get#Website").call()?.website
String hostName = website?.hostName
if (!hostName || hostName == '????') { ec.message.addError("The company has no website address to publish the article on"); return }
String scheme = hostName.contains('localhost') ? 'http' : 'https'
targetUrl = "${scheme}://${hostName}/content/${articlePath}".toString()

def created = ec.service.sync().name("growerp.100.MasterContentServices100.create#MasterContent")
    .parameters([planId: planId, contentType: 'ARTICLE', pnpType: thePnp, title: data.title,
                 body: data.body, callToAction: data.callToAction, targetUrl: targetUrl,
                 teaserMode: 'Y', status: 'DRAFT']).call()
if (ec.message.hasError()) return
masterContentId = created.masterContentId
pseudoId = created.pseudoId
title = created.title
ec.service.sync().name("update#growerp.marketing.MasterContent")
    .parameters([masterContentId: masterContentId, articlePath: articlePath]).call()
// the idea is used up: the article is what remains
idea.delete()
ec.message.addMessage("Article '${title}' written; approve it to put it on the website")
