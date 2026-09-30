# GrowERP Insurance: insurance you are glad to hold

Submission to the BeyondPilot *AI for Insurance* challenge with Tasco (September–October 2026).

## 1. Problem framing

Compulsory motor insurance in Vietnam is the same product at the same price from every insurer.
Customers buy it only to comply, and then:

- **They carry paper.** It gets lost, and a roadside check turns into an argument.
- **They find out too late that it expired.** Renewal is easy to forget.
- **They don't know what they are covered for.** The policy wording is legal text.
- **Claiming after an accident is stressful and slow.** Photos, documents, calls and a long wait,
  with no view of where the claim stands.
- **Every question goes to a hotline.**

**Who we help**
- The driver, from the first purchase to a paid claim.
- The agency and insurance staff, who get complete claims with photos and fewer status calls.

**Which friction we solve.** All three phases of the brief:

- **Buy:** plain-language cover, and a quote request with no pricing tricks.
- **Carry:** a verifiable digital card and calm renewal reminders.
- **Claim:** guided first notice of loss, AI photo triage for the adjuster, and a live status timeline.

A 24/7 assistant runs across all three.

There are **no discounts, cashback or price incentives** anywhere in the product or its messages.

## 2. The prototype

It is a working prototype on GrowERP, an open-source ERP with a Flutter frontend (web/PWA,
Android, iOS, desktop) and a Moqui backend. It is multi-tenant: one agency or insurer per tenant.

| Journey | What the customer gets | How it works |
|---|---|---|
| **Carry** | Digital policy card: plate, validity, cover, QR code | The QR opens `https://<host>/verify/<token>`, a public page in Vietnamese and English. It shows a green *Còn hiệu lực* / red *Hết hiệu lực* banner with the live status. The plate is masked (51K-\*\*\*.46). No name, address, premium or claims are shown. The token is random, one per policy term. |
| **Carry** | Renewal reminders at 30, 7 and 1 days before expiry | Neutral wording ("your policy ends on…"), no countdown pressure. There is a one-tap *Request renewal* button. The staff member handling the policy is emailed and the request is flagged in the staff renewal list. A person renews it with the insurer. |
| **Buy** | *Explain my cover in plain words* | The LLM explains the policy's own coverages, limits and deductibles in the app language (Vietnamese, English and others). It is instructed to invent nothing. The answer is cached per policy and language, and regenerated when the policy changes. |
| **Buy** | *Get insured* form on the agency website | Creates a lead for the agency: vehicle, plate, contact. Staff prepare the quote. No automated pricing. |
| **Claim** | Four-step guided claim: what happened → when and where → photo checklist → review and consent | Plain incident types (collision, parked, flood, theft…). The *Someone was hurt* option first shows 115/113. The photo checklist covers plate, whole vehicle, damage close-up, and the other vehicle or scene. Photos are resized on the phone. |
| **Claim** | Faster assessment | After the claim is saved, a vision model triages the photos in the background. It reports damaged parts, severity, whether the vehicle is drivable, whether the plate in the photos matches the policy, consistency with the description, missing evidence, and a suggested next step (roadside assistance, partner garage, inspection). **It is advice for the adjuster only.** The AI never approves, denies or prices a claim. |
| **Claim** | Transparency | A status timeline with a plain explanation of every step, and an email on every status change. The customer also sees what extra evidence is requested. |
| **Support** | *Ask a question*, 24/7 | Answers from the customer's own policies and claims plus the agency's knowledge base. It runs *as the customer*, so it can never see anyone else's data. No prices, no claim decisions. When a person is needed, the agency is emailed and the customer is told. |

Staff use the same app: policies, renewals, claims with the photo gallery and AI triage panel,
commissions and accounting.

## 3. Impact and assumptions

| Metric | Today (assumed) | Target in pilot | Assumption |
|---|---|---|---|
| Time to report a claim | Phone call plus a visit, hours | < 10 minutes in the app | Customers have a smartphone with a camera |
| Claims complete at first submission | Low: photos and documents chased afterwards | > 70% with the required photos | Photo checklist and AI missing-evidence prompts |
| Adjuster time to first decision | Days | Same day for simple damage | Adjusters use the triage panel as a first read |
| "Where is my claim?" calls | High | −50% | Timeline plus status emails |
| On-time renewals | Unknown | +10 points | Reminders plus one-tap request, no price incentive |
| Roadside proof disputes | Paper lost or forgotten | Zero with the digital card | Police and garages scan a QR with any phone camera |

These are hypotheses to measure in the pilot, not claims. The pilot plan (section 6) defines
how each is measured.

## 4. Implementation needs from Tasco

| Need | Why | Pilot-week fallback |
|---|---|---|
| Policy feed (motor TNDS policies of a pilot segment) | Cards, reminders and claims on real policies | CSV import (GrowERP has CSV import) |
| Claim status updates from the insurer's system | Live timeline | Staff update the status in the app |
| VETC plate and vehicle data (with consent) | Pre-filled vehicle data, plate check in triage | Customer or staff enters the plate |
| Garage / roadside assistance booking API | Act on "suggested next step" | Staff call the garage |
| SMS / Zalo OA for reminders | Customers read Zalo more than email | Email and in-app |
| Knowledge documents (policy wording, claim rules) | Assistant answers | Upload through the Knowledge screen |
| LLM provider choice and data residency | Compliance | Gemini by default, switchable per tenant (Anthropic, OpenAI) |

## 5. Responsible design

- **Consent.** The claim wizard needs explicit consent: the claim and photos are shared with the
  agency and insurer and checked with the help of AI, and a person makes every decision. The
  quote form states its purpose. This is designed for Decree 13/2023/NĐ-CP on personal data
  protection. A legal review with Tasco is part of pilot week 1.
- **Data minimisation.** The public verify page shows only what proves cover. The plate is
  masked, and a new token is issued at every renewal. The assistant only receives the asking
  customer's own records.
- **Human in the loop.** The AI is advisory at every step. Staff review:
  - every claim decision and amount,
  - AI triage flags such as a plate mismatch or inconsistent damage,
  - renewal requests,
  - questions the assistant escalated.
- **Accurate communication.** No artificial urgency in reminders, no pricing or incentives in
  any AI prompt or output. The AI prompts forbid inventing exclusions or rules.
- **Auditability.** Claim and policy status changes are audit-logged, and they drive the
  customer's timeline. Every LLM call is logged with tokens and purpose, and a per-tenant
  monthly allowance applies.
- **Failure behaviour.** If the AI is unavailable, the claim simply stays *Submitted* and is
  handled as before.
- **Seasonal demand.** Renewals and travel peak around Tết, and accident claims peak with the
  holidays and the rainy season (floods). Triage runs asynchronously in a queue, so peaks delay
  advice, not claim intake. Reminders are spread over 30/7/1 days.

## 6. Pilot plan (4 weeks)

1. **Scope lock.**
   - One pilot segment, for example TNDS customers of one Tasco Auto dealer.
   - Sign the NDA, agree the data-sharing and consent texts, and confirm the metrics above.
2. **Build on real context.**
   - Import the policy feed.
   - Brand the tenant.
   - Load the knowledge documents.
   - Vietnamese copy review with Tasco staff.
3. **Integrate.**
   - Claim status sync, or a staff workflow.
   - Zalo/SMS reminders if approved.
   - Mid-point review.
4. **Test with operational users.**
   - Adjusters use the triage panel on live claims.
   - Measure claim completeness, time to first decision, status calls and renewal requests.

## 7. Where to look

- Hosted demo: https://tasco.growerp.net
  - Agency staff: `test970444@example.com` / `qqqqqq9!`: policies, renewals, claims with the AI
    triage panel, commissions.
  - Customer (choose *Tiếng Việt* on the login screen): `lan.970445@example.com` / `qqqqqq9!`:
    My Policies, the digital card, *explain my cover*, the claim wizard, the assistant.
  - Public proof of insurance (what the QR code opens):
    https://tasco-backend.growerp.net/verify/68d8c0d06cbe423a92f1d3492cad9e70
- Demo video: https://www.youtube.com/watch?v=3j92jqFwI_Y (2 min 48 s). The claim photos in it are AI-generated illustrations.
- Source: https://github.com/growerp/growerp (branch `tasco`), Apache 2.0.
