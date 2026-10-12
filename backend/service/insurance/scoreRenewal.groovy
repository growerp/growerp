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

// Renewal lead score of a policy, run by get#RenewalCandidates. Explainable on purpose: a
// handful of rules a telesales lead can read and argue with, each adding or removing points
// with a plain reason. No black box, no personal data beyond the policy and its contacts.
// In: policy (Policy value), touches (RenewalTouch list, oldest first), consents (Map
// channelEnumId -> granted Y/N), contact (Map hasPhone, hasEmail), now (Timestamp).
// Out: result Map: score 0..100, band High|Medium|Low|Done|Stop, reasons, nextChannelEnumId,
// nextAction, nextTime, completeness 0..100, missing, stage.

long day = 24L * 3600L * 1000L
int daysToExpiry = Math.floorDiv(policy.expirationDate.time - now.time, day) as int
List reasons = []
int score = 40

def events = touches*.eventEnumId
def outcomes = touches*.outcomeEnumId.findAll { it }
def lastOutcome = outcomes ? outcomes[-1] : null
def sentTouches = touches.findAll { it.eventEnumId == 'InevSent' }
boolean renewed = policy.statusId == 'InpsRenewed' || 'InevRenewed' in events || lastOutcome == 'InocRenewed'

// where the customer is in the journey: the furthest step reached this cycle
def stageOrder = ['InevSent', 'InevOpened', 'InevVisited', 'InevConfirmed', 'InevRenewRequested', 'InevRenewed', 'InevIssued']
String stage = stageOrder.findAll { it in events }.with { it ? it[-1] : 'InevNone' }

Map result = [daysToExpiry: daysToExpiry, stage: stage]
if (renewed) {
    return result + [score: 100, band: 'Done', reasons: ['Already renewed'], nextAction: 'None',
                     nextChannelEnumId: null, nextTime: null, completeness: 100, missing: []]
}
if ('InevOptOut' in events || lastOutcome in ['InocOptOut', 'InocSoldVehicle']) {
    String why = lastOutcome == 'InocSoldVehicle' ? 'Sold the vehicle' : 'Asked for no more contact'
    return result + [score: 0, band: 'Stop', reasons: [why], nextAction: 'Do not contact',
                     nextChannelEnumId: null, nextTime: null, completeness: 0, missing: []]
}

// 1. loyalty: a policy that is itself a renewal renewed before
if (policy.renewedFromPolicyId) { score += 20; reasons.add('Renewed with us before (+20)') }
else reasons.add('First year with us (+0)')

// 2. engagement in this cycle
if ('InevRenewRequested' in events) { score += 30; reasons.add('Asked to renew (+30)') }
else if ('InevConfirmed' in events) { score += 20; reasons.add('Confirmed the vehicle (+20)') }
else if ('InevVisited' in events) { score += 15; reasons.add('Opened the renewal page (+15)') }
else if ('InevOpened' in events) { score += 8; reasons.add('Read the reminder (+8)') }
else if (sentTouches.size() >= 2) { score -= 10; reasons.add("No reaction to ${sentTouches.size()} reminders (-10)") }
if ('InevCallback' in events) { score += 10; reasons.add('Asked for a call (+10)') }

// 3. call outcomes
switch (lastOutcome) {
    case 'InocInterested': score += 15; reasons.add('Interested on the last call (+15)'); break
    case 'InocNotInterested': score -= 25; reasons.add('Not interested on the last call (-25)'); break
    case 'InocInsuredElsewhere': score -= 30; reasons.add('Insured elsewhere (-30)'); break
    case 'InocWrongNumber': score -= 15; reasons.add('Wrong number (-15)'); break
    case 'InocNoAnswer': score -= 5; reasons.add('Did not answer (-5)'); break
}

// 4. timing
if (daysToExpiry < 0) { score -= 10; reasons.add("Lapsed ${-daysToExpiry} days ago (-10)") }
else if (daysToExpiry <= 14) { score += 5; reasons.add("Expires in ${daysToExpiry} days (+5)") }

// 5. reachability (enrichment): what we know and may use
List consented = consents.findAll { it.value == 'Y' }.collect { it.key }
List missing = []
if (!contact.hasPhone) missing.add('phone')
if (!contact.hasEmail) missing.add('email')
if (!policy.vehiclePlate) missing.add('plate')
if (!consented) { missing.add('consent'); score -= 15; reasons.add('No consent to contact (-15)') }
int completeness = (int) Math.round(100 * (4 - missing.size()) / 4)
if (completeness == 100) { score += 5; reasons.add('Complete profile (+5)') }

score = Math.max(0, Math.min(99, score))
String band = score >= 70 ? 'High' : score >= 40 ? 'Medium' : 'Low'

// next best channel: the consented one this customer reacted to most, else the usual order
def reactedOn = touches.findAll { it.eventEnumId in ['InevOpened', 'InevVisited', 'InevConfirmed'] }*.channelEnumId
List preference = ['InchZalo', 'InchVetc', 'InchSms', 'InchEmail']
String nextChannel = consented.findAll { it in preference }
        .sort { a, b -> (reactedOn.count(b) <=> reactedOn.count(a)) ?: (preference.indexOf(a) <=> preference.indexOf(b)) }
        .with { it ? it[0] : null }
long lastSent = sentTouches ? sentTouches[-1].touchDate.time : 0L
String nextAction
if ('InevRenewRequested' in events) nextAction = 'Issue the renewal'
else if ('InevCallback' in events || lastOutcome == 'InocInterested') nextAction = 'Telesales call'
else if (!nextChannel) nextAction = consents.InchCall == 'Y' ? 'Telesales call' : 'Ask consent at next visit'
else if (now.time - lastSent < 3 * day) nextAction = 'Wait, reminded recently'
else if (sentTouches.size() >= 2 && score >= 40 && consents.InchCall == 'Y') nextAction = 'AI voice call'
else nextAction = 'Send reminder'
if (nextAction == 'AI voice call') nextChannel = 'InchVoiceBot'
if (nextAction == 'Telesales call') nextChannel = 'InchCall'

// time of day: when this customer opened earlier reminders (local time), else early evening
def openHours = touches.findAll { it.eventEnumId == 'InevOpened' }.collect {
    java.time.Instant.ofEpochMilli(it.touchDate.time).atZone(java.time.ZoneId.of('Asia/Ho_Chi_Minh')).hour }
String nextTime = openHours ? String.format('%02d:00', openHours.groupBy { it }.max { it.value.size() }.key) : '19:00'

return result + [score: score, band: band, reasons: reasons, nextChannelEnumId: nextChannel,
                 nextAction: nextAction, nextTime: nextTime, completeness: completeness, missing: missing]
