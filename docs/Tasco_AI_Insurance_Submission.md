# GrowERP Insurance: an AI renewal engine for TNDS

Submission to the BeyondPilot *AI for Insurance* challenge with Tasco (October 2026), updated
after the 7 October briefing.

## 1. Customer problem

TNDS is the same cover at the same regulated price everywhere. Customers renew late, renew with
whoever reminds them at the right moment, or let the cover lapse. Discounts are not allowed and
are not the answer. Renewal is won on **timing, clarity and an easy next step**, with a person
available when the customer wants one.

## 2. Solution: one renewal journey across VETC, Zalo and telesales

| Briefing track | In the working demo (synthetic data) |
|---|---|
| **B. Lead scoring and enrichment** | Explainable score per customer due within 60 days. It uses renewal history, reactions to earlier reminders, consent, profile completeness and timing, and shows plain reasons and missing fields. It recommends the next best channel and the time of day the customer usually reads messages. |
| **C. Renewal engine** | AI drafts the reminder in Vietnamese from policy facts only: no urgency, no discounts, one next step, how to stop. It is sent on the consented channel (Zalo, VETC push, SMS, email). Zalo and VETC are shown as phone previews until connected. A private renewal page needs no app and no login: confirm the car by plate, then renew, ask for a call, or "sold / stop". |
| **A. AI voice bot** | Vietnamese AI call: asks permission, confirms the vehicle, answers from the policy only, and hands over to telesales with a summary, transcript and CRM outcome code. Opt-out works at every step. |
| **D. Value beyond discount** | The renewal page offers service, not price: a digital certificate with a live QR check, guided claims with photo triage, and roadside and service-centre help. Specific offers are marked as needing compliance review. |
| **Telesales and impact** | A queue of call requests, AI hand-overs and renewal requests, with outcome codes ("Renewed" renews the policy). A funnel by stage, channel and score band. |

Claims (guided claim, AI photo triage, timeline), the digital certificate and a client assistant
are already built and form phase 2.

## 3. Impact and measures

Measured per channel and score band against Tasco's week-1 baselines:

- **Renewal rate before expiry:** target +5 to +10 points.
- **Reminder → renewal-page visit:** target 25% or more.
- **Telesales calls per renewal:** target −30%.
- **AI hand-overs rated useful by telesales:** target 80% or more.
- **Opt-out rate:** must not rise.

These targets are hypotheses until the baselines are in.

## 4. Fit: data, consent, integration, people

- **Data fields:** policy number, insurer, dates, plate and vehicle; name, phone and email;
  consent per channel (date and source); reminder and renewal events; call outcomes. The demo
  uses synthetic data; the pilot starts on masked data.
- **Consent (Decree 13/2023):** we contact customers only on consented channels, honour "stop"
  everywhere, and use a private renewal link with a plate check.
- **Integration dependencies, not assumed APIs:** Zalo OA, VETC push and deep link, SMS,
  telephony for the AI call, CRM outcome codes, and the issuance hand-off. Each has a manual
  fallback for the PoC.
- **People:** staff issue renewals and own outcomes. The AI scores, drafts, explains and hands over.

## 5. Speed and cost

- **4-week PoC:** scope and baselines, then a live masked segment, then reminders and calls,
  then measurement and a recommendation.
- **GrowERP is free and open source (Apache 2.0).** Tasco pays only for the production
  environment, enhancements (integrations) and support. AI usage is passed through at cost,
  logged per tenant under a monthly budget.

## 6. Try it

- **Hosted demo:** https://tasco.growerp.net: a short landing page; **Open the demo** starts the staff app
  (Renewals → Cockpit and Telesales), already loaded in the background while you read.
  - Agency login: test150296@example.com / qqqqqq9!
  - Customer pages open from the cockpit: a reminder's **Open preview**, **Renewal page** and
    **AI call** (allow the microphone, Chrome).
- **Demo video (renewal):** https://youtu.be/Dc9yygkDWfs. Earlier claims video:
  https://www.youtube.com/watch?v=3j92jqFwI_Y
- **Source:** https://github.com/growerp/growerp (branch `tasco`), Apache 2.0.
- **Contact:** Hans Bakker · h.bakker@antwebsystems.com · +66-81-7523157
