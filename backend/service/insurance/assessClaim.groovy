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

// Triage of a new claim from its photos and description, run by assess#Claim in the
// background. The result is advice for the adjuster: the AI never approves, denies or
// prices a claim. Context in: claimId. Out: the Claim gets aiAssessment (JSON) and
// aiAssessedDate; a claim still Submitted moves to Assessed, awaiting adjuster.

import groovy.json.JsonOutput

def claim = ec.entity.find("growerp.insurance.Claim").condition("claimId", claimId).one()
if (!claim) { ec.logger.warn("assess#Claim: claim ${claimId} not found"); return }
def policy = ec.entity.find("growerp.insurance.Policy").condition("policyId", claim.policyId).one()
def contents = ec.entity.find("growerp.insurance.ClaimContent").condition("claimId", claimId)
    .orderBy("contentSeqId").list()

List images = []
List photoLabels = []
contents.each { content ->
    def ref = ec.resource.getLocationReference(content.contentLocation as String)
    if (!ref?.getExists()) return
    byte[] bytes = ref.openStream().withCloseable { it.bytes }
    // magic bytes: the app sends jpeg or png
    String mimeType = (bytes.length > 3 && bytes[0] == (byte) 0x89 && bytes[1] == (byte) 0x50) ? "image/png" : "image/jpeg"
    images.add([mimeType: mimeType, data: bytes.encodeBase64().toString()])
    photoLabels.add("photo ${images.size()}: ${content.description ?: 'no label'}")
}

def incidentType = claim.incidentTypeEnumId ? ec.entity.find("moqui.basic.Enumeration")
    .condition("enumId", claim.incidentTypeEnumId).useCache(true).one()?.description : null
def policyType = ec.entity.find("moqui.basic.Enumeration")
    .condition("enumId", policy?.policyTypeEnumId).useCache(true).one()?.description
String language = ec.user.locale?.getDisplayLanguage(Locale.ENGLISH) ?: "English"

String prompt = """You assist an insurance claims adjuster with the first triage of a claim.
You do NOT decide whether the claim is covered, approved, denied or how much is paid: a person does.
Be factual, say "unclear" when the photos do not show something, never guess an identity.

Policy: ${policyType ?: 'unknown type'}, insured vehicle plate: ${policy?.vehiclePlate ?: 'not recorded'},
vehicle: ${policy?.vehicleDescription ?: 'not recorded'}.
Claim as reported by the client:
- what happened: ${incidentType ?: 'not given'}
- when: ${claim.incidentDate}
- where: ${claim.incidentLocation ?: 'not given'}
- description: ${claim.description}
- photos (in order): ${photoLabels ? photoLabels.join('; ') : 'none'}

Answer with JSON only, in this structure:
{
  "summary": "two sentences for the adjuster",
  "overallSeverity": "minor | moderate | severe | unclear",
  "damagedParts": [{"part": "front bumper", "severity": "minor | moderate | severe", "photo": 1}],
  "drivable": "yes | no | unclear",
  "injuryIndicators": "none seen | possible | unclear",
  "plateInPhotos": "the plate as read in the photos, or null",
  "plateMatchesPolicy": "yes | no | unclear",
  "consistency": ["each observation where photos and description agree or disagree"],
  "missingEvidence": ["short requests to the client in ${language}, e.g. a photo of the other vehicle's plate"],
  "suggestedNextStep": "roadside_assistance | partner_garage | adjuster_inspection | police_report | none",
  "reviewFlags": ["anything the adjuster must check in person"]
}"""

def testAnswer = [summary: "Test assessment: minor damage to the front bumper, consistent with the description.",
    overallSeverity: "minor", damagedParts: [[part: "front bumper", severity: "minor", photo: 1]],
    drivable: "yes", injuryIndicators: "none seen", plateInPhotos: policy?.vehiclePlate,
    plateMatchesPolicy: "yes", consistency: ["Damage location matches the description"],
    missingEvidence: ["A photo of the other vehicle's licence plate"],
    suggestedNextStep: "partner_garage", reviewFlags: []]

def assessment
if ('true'.equals(System.getenv('GROWERP_TEST_MODE'))) {
    assessment = testAnswer
} else {
    def GeminiAiUtil = ec.resource.script("component://growerp/service/GeminiAiUtil.groovy", null)
    for (int attempt = 1; ; attempt++) {
        String text = GeminiAiUtil.callLlmApi(ec, prompt, [ownerPartyId: claim.ownerPartyId,
            jsonMode: true, maxOutputTokens: 4096, temperature: 0.2, images: images,
            purpose: "insurance claim triage"])
        try {
            assessment = GeminiAiUtil.parseJsonResponse(text)
            break
        } catch (groovy.json.JsonException e) {
            if (attempt >= 2) throw new Exception("The AI returned invalid JSON: ${e.message?.take(200)}")
        }
    }
}

// read again: staff may have moved the claim on while the AI was thinking
ec.transaction.runRequireNew(60, "Error saving the claim assessment", {
    def current = ec.entity.find("growerp.insurance.Claim").condition("claimId", claimId).forUpdate(true).one()
    current.aiAssessment = JsonOutput.toJson(assessment)
    current.aiAssessedDate = ec.user.nowTimestamp
    if (current.statusId == "InclSubmitted") current.statusId = "InclAiAssessed"
    current.update()
})
