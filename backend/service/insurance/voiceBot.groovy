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

// One turn of the AI renewal call (converse#VoiceBot). The call follows a fixed, respectful
// path: permission to talk -> confirm the vehicle (last characters of the plate) -> offer:
// renew, talk to a person, or questions -> close. The LLM only understands what the customer
// said and answers questions from the policy facts; it never quotes prices or promises. Stop
// works at every step. At the end the call is written as a RenewalTouch (transcript, summary,
// outcome) and a person takes over where needed.
// In: policy, text (what the customer said, empty to start), state (Map), language.
// Out: reply, state, done, outcomeEnumId.

import groovy.json.JsonOutput

boolean testMode = 'true'.equals(System.getenv('GROWERP_TEST_MODE'))
def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
boolean vi = language != 'en'
String stage = state.stage ?: 'start'
List history = state.history ?: []
if (text) history.add([role: 'customer', text: text])

def nameOf = { partyId -> ec.service.sync().name('growerp.100.InsuranceServices100.get#PartyName')
        .parameters([partyId: partyId]).call().name ?: '' }
String firstName = nameOf(policy.insuredPartyId).tokenize(' ').with { it ? it[-1] : '' }
String agency = nameOf(policy.ownerPartyId)
String carrier = nameOf(policy.carrierPartyId)
String expires = ec.l10n.format(policy.expirationDate, 'dd/MM/yyyy')
String plate = policy.vehiclePlate ?: ''
String plateClean = plate.replaceAll('[^A-Za-z0-9]', '').toUpperCase()

// understanding the customer: the LLM, with keyword rules as fallback (and in test mode)
def keywordIntent = { String t ->
    String s = (t ?: '').toLowerCase()
    if (s =~ /(dừng|đừng gọi|không gọi|stop|unsubscribe)/) return 'stop'
    if (s =~ /(bán xe|đã bán|sold)/) return 'sold'
    if (s =~ /(nhầm|không phải|wrong)/) return 'wrong_person'
    if (s =~ /(gia hạn|tái tục|renew)/) return 'renew'
    if (s =~ /(nhân viên|tư vấn viên|người thật|gọi lại|call me|person|agent)/) return 'human'
    if (s.contains('?') || s =~ /(bao nhiêu|như thế nào|là gì|what|how|which)/) return 'question'
    if (s =~ /(không|chưa|bận|no\b|not now|later)/) return 'no'
    if (s =~ /(có|vâng|dạ|được|ừ|ok|yes|sure)/) return 'yes'
    return 'other'
}
Map nlu = [intent: keywordIntent(text), plateEnd: (text ?: '').replaceAll('[^A-Za-z0-9]', '').toUpperCase()]
if (text && !testMode) {
    String prompt = """A customer answers an insurance renewal call. The current step is "${stage}"
(consent = we asked if they have a minute; plate = we asked the last 3 characters of the licence plate;
offer = we asked whether to renew now, talk to a person, or ask a question).
Customer said: "${text}"
Return JSON only: {"intent": "yes|no|stop|sold|wrong_person|renew|human|question|other",
"plateEnd": "the characters they said for the plate, digits and letters only, uppercase, or empty"}.
Spoken numbers count as digits (for example "bốn sáu" is 46)."""
    try {
        def parsed = GeminiAiUtil.parseJsonResponse(GeminiAiUtil.callLlmApi(ec, prompt,
                [ownerPartyId: policy.ownerPartyId, jsonMode: true, temperature: 0.0,
                 maxOutputTokens: 200, purpose: 'insurance voice call']))
        if (parsed?.intent) nlu.intent = parsed.intent
        if (parsed?.plateEnd != null) nlu.plateEnd = parsed.plateEnd.toString().toUpperCase()
    } catch (Throwable t) {
        ec.logger.warn("Voice call understanding fell back to keywords: ${t.message}")
        ec.message.clearErrors()
    }
}

def answerQuestion = { String q ->
    def coverages = ec.entity.find('growerp.insurance.PolicyCoverage').condition('policyId', policy.policyId).list()
    String facts = "insurer ${carrier}; agency ${agency}; cover ends ${expires}; plate ${plate}; " +
            "coverages: " + coverages.collect { "${it.coverageName} limit ${it.limitAmount ?: '-'}" }.join('; ')
    if (testMode) return vi ? "Bảo hiểm của xe do ${carrier} cung cấp và hết hạn ngày ${expires}." :
            "The cover is with ${carrier} and ends on ${expires}."
    String prompt = """You are a polite insurance renewal call assistant of ${agency}. Answer the customer's
question in ${vi ? 'Vietnamese' : 'English'}, in at most 2 short spoken sentences, using only these facts: ${facts}.
Never quote or estimate prices, never promise payments or discounts. If the facts do not answer it,
say a colleague will explain. Question: "${q}"."""
    try {
        return GeminiAiUtil.callLlmApi(ec, prompt, [ownerPartyId: policy.ownerPartyId,
                temperature: 0.3, maxOutputTokens: 200, purpose: 'insurance voice call'])?.trim()
    } catch (Throwable t) {
        ec.message.clearErrors()
        return vi ? 'Câu hỏi này đồng nghiệp của em sẽ giải thích rõ hơn.' : 'A colleague will explain that.'
    }
}

String offer = vi ? "Anh/chị muốn gia hạn ngay, nói chuyện với nhân viên, hay có câu hỏi ạ?"
                  : "Would you like to renew now, talk to a colleague, or do you have a question?"
String reply
String outcome = null
boolean done = false
String event = null // journey event to record besides the call itself

switch (stage) {
    case 'start':
        reply = vi ? "Xin chào anh/chị ${firstName}, em là trợ lý AI của ${agency}. Em gọi để nhắc bảo hiểm " +
                     "bắt buộc của xe kết thúc ngày ${expires}. Anh/chị có một phút để nghe không ạ?"
                   : "Hello ${firstName}, this is the AI assistant of ${agency}. I am calling about your compulsory " +
                     "motor insurance, which ends on ${expires}. Do you have a minute?"
        stage = 'consent'
        break
    case 'consent':
        if (nlu.intent in ['yes', 'renew', 'question', 'human']) {
            reply = vi ? "Cảm ơn anh/chị. Để chắc đúng xe, anh/chị đọc giúp em ba ký tự cuối của biển số ạ."
                       : "Thank you. To be sure it is your vehicle, please tell me the last three characters of the plate."
            stage = 'plate'
        } else if (nlu.intent == 'wrong_person') {
            reply = vi ? "Xin lỗi đã làm phiền anh/chị. Chúc anh/chị một ngày tốt lành." : "Sorry to have disturbed you. Have a good day."
            outcome = 'InocWrongNumber'; done = true
        } else if (nlu.intent in ['stop', 'sold']) {
            reply = vi ? "Dạ, em sẽ không gọi lại nữa. Cảm ơn anh/chị." : "Understood, we will not call again. Thank you."
            outcome = nlu.intent == 'sold' ? 'InocSoldVehicle' : 'InocOptOut'; event = 'InevOptOut'; done = true
        } else {
            reply = vi ? "Dạ, không sao ạ. Nhân viên của chúng em sẽ gọi lại vào lúc khác. Cảm ơn anh/chị."
                       : "No problem. A colleague will call another time. Thank you."
            outcome = 'InocCallLater'; done = true
        }
        break
    case 'plate':
        String said = nlu.plateEnd ?: ''
        if (nlu.intent in ['stop', 'sold']) {
            reply = vi ? "Dạ, em sẽ không gọi lại nữa. Cảm ơn anh/chị." : "Understood, we will not call again. Thank you."
            outcome = nlu.intent == 'sold' ? 'InocSoldVehicle' : 'InocOptOut'; event = 'InevOptOut'; done = true
        } else if (said.length() >= 3 && plateClean.endsWith(said)) {
            reply = (vi ? "Cảm ơn anh/chị, đúng xe ${plate}. Bảo hiểm do ${carrier} cung cấp, kết thúc ngày ${expires}. "
                        : "Thank you, that is ${plate}. The cover is with ${carrier} and ends on ${expires}. ") + offer
            stage = 'offer'; event = 'InevConfirmed'
        } else if ((state.plateTries ?: 0) < 1) {
            state.plateTries = (state.plateTries ?: 0) + 1
            reply = vi ? "Em chưa nghe rõ. Anh/chị đọc lại ba ký tự cuối của biển số giúp em ạ."
                       : "Sorry, I did not catch that. Please say the last three characters of the plate again."
        } else {
            reply = vi ? "Em chưa xác nhận được xe. Nhân viên của chúng em sẽ gọi lại để hỗ trợ anh/chị. Cảm ơn anh/chị."
                       : "I could not confirm the vehicle. A colleague will call you back to help. Thank you."
            outcome = 'InocInterested'; event = 'InevCallback'; done = true
        }
        break
    default: // offer
        switch (nlu.intent) {
            case 'renew':
            case 'yes':
                reply = vi ? "Em đã ghi nhận yêu cầu gia hạn. Anh/chị sẽ nhận đường link xác nhận qua Zalo, và giấy " +
                             "chứng nhận điện tử sau khi nhân viên phát hành. Cảm ơn anh/chị đã tin tưởng ${agency}."
                           : "I have noted your renewal. You will receive a confirmation link on Zalo, and the digital " +
                             "certificate once a colleague issues it. Thank you for staying with ${agency}."
                outcome = 'InocInterested'; event = 'InevRenewRequested'; done = true
                break
            case 'human':
                reply = vi ? "Dạ, em chuyển cho nhân viên tư vấn. Anh/chị sẽ nhận cuộc gọi sớm. Cảm ơn anh/chị."
                           : "I will pass you to a colleague, who will call you shortly. Thank you."
                outcome = 'InocInterested'; event = 'InevCallback'; done = true
                break
            case 'question':
            case 'other':
                reply = answerQuestion(text) + ' ' + offer
                break
            case 'stop':
            case 'sold':
                reply = vi ? "Dạ, em sẽ không gọi lại nữa. Cảm ơn anh/chị." : "Understood, we will not call again. Thank you."
                outcome = nlu.intent == 'sold' ? 'InocSoldVehicle' : 'InocOptOut'; event = 'InevOptOut'; done = true
                break
            default: // no
                reply = vi ? "Dạ, em hiểu. Nếu cần, anh/chị có thể gia hạn bất cứ lúc nào qua đường link trong tin nhắn. Cảm ơn anh/chị."
                           : "I understand. You can renew any time with the link in our message. Thank you."
                outcome = 'InocNotInterested'; done = true
        }
}
history.add([role: 'assistant', text: reply])

if (done) {
    String transcript = history.collect { "${it.role == 'customer' ? 'Customer' : 'AI'}: ${it.text}" }.join('\n')
    String summary = "AI call: ${ec.entity.find('moqui.basic.Enumeration').condition('enumId', outcome).useCache(true).one()?.description}."
    if (!testMode) {
        try {
            summary = GeminiAiUtil.callLlmApi(ec, """Summarise this insurance renewal call for the telesales colleague who
continues it, in Vietnamese, in at most 2 sentences: what the customer wants and anything to know. Transcript:
${transcript}""", [ownerPartyId: policy.ownerPartyId, temperature: 0.2, maxOutputTokens: 200,
                   purpose: 'insurance voice call'])?.trim() ?: summary
        } catch (Throwable t) { ec.message.clearErrors() }
    }
    ec.service.sync().name('create#growerp.insurance.RenewalTouch').parameters([ownerPartyId: policy.ownerPartyId,
            policyId: policy.policyId, channelEnumId: 'InchVoiceBot', eventEnumId: 'InevCalled',
            outcomeEnumId: outcome, summary: summary, transcript: transcript,
            touchDate: ec.user.nowTimestamp]).call()
    if (event == 'InevRenewRequested') {
        def p = ec.entity.find('growerp.insurance.Policy').condition('policyId', policy.policyId).forUpdate(true).one()
        p.renewalRequestedDate = ec.user.nowTimestamp
        p.update()
    }
    if (event == 'InevOptOut') {
        ec.entity.find('growerp.insurance.CustomerConsent').condition('partyId', policy.insuredPartyId).list().each {
            it.granted = 'N'; it.consentDate = ec.user.nowTimestamp; it.source = 'AI voice call: stop'; it.update()
        }
    }
}
if (event) {
    ec.service.sync().name('create#growerp.insurance.RenewalTouch').parameters([ownerPartyId: policy.ownerPartyId,
            policyId: policy.policyId, channelEnumId: 'InchVoiceBot', eventEnumId: event,
            touchDate: ec.user.nowTimestamp]).call()
}
state.stage = done ? 'end' : stage
state.history = history
return [reply: reply, state: state, done: done, outcomeEnumId: outcome]
