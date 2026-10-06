# Questions for the Tasco briefing (Wed 7 Oct 2026, 15:30 GMT+7, Zoom)

## Context
GenAI Fund's Head of Programs (Eugene) invited applicants to a live Q&A with Tasco's business
team. Submissions close 15 Oct; 10 teams pitch on 22 Oct. Our submission is built and hosted:
- Digital card with QR proof, plain-language cover, guided claim with AI photo triage, status
  timeline, assistant and renewal reminders, in Vietnamese.
- Deliverables: proposal PDF, 16-slide deck, demo video, tasco.growerp.net.

Our weakest points are **assumptions** we made without Tasco's input:
- the pilot segment and its size;
- the baselines behind our impact targets;
- the channels (email, not Zalo);
- data and integrations (CSV fallbacks);
- how Tasco actually splits work between insurer, agency and service centre;
- whether Tasco cares more about customer-facing or back-office pain. The email stresses
  back-office and legacy systems, which our deck barely covers.

The questions below are ranked so the first ones fit even if we get only 2–3 questions.
Next to each is what the answer would change in our deck, proposal or demo.

## Must ask (top 5)
1. **Where does it hurt most today: claims intake, assessment, renewals or back-office processing?**
   Which one step would you fix first if you could? This decides which journey leads the pitch
   (claim triage vs. renewal vs. back-office) and the order of the deck.
2. **What does a TNDS claim look like today, end to end?** Who takes the first notice (hotline,
   dealer, service centre, app)? How long until an adjuster decides, and what causes most
   delays? This gives real baselines for the impact table instead of "Tasco data, week 1".
3. **Which systems hold policies and claims, and how do they exchange data today?** Core
   insurance system, Excel, partner insurers' portals. What could be exported for a 4-week
   pilot? This firms up "what we need from Tasco" and whether CSV import is realistic.
4. **Is Tasco the insurer, the agent/broker, or both, for TNDS?** Who owns the customer
   relationship and the claim decision? This changes our framing (agency vs. insurer) and who
   the "adjuster" is in the demo.
5. **How would you measure success for a one-month pilot?** Which 2–3 numbers would convince
   your leadership to scale? We would replace our hypothetical KPIs with theirs, verbatim.

## Customer journey (buy · carry · claim)
6. How do customers buy TNDS today: at the dealer with the car, online, at VETC or service
   points? What share renews with Tasco? This tests whether renewal is a real lever.
7. Do police and CSGT already accept the electronic certificate (Decree 67/2023)? Is a
   QR-verifiable card useful, or is the e-certificate already solved? This decides whether the
   QR proof stays a headline feature.
8. Which channel reaches customers best: Zalo OA, SMS, the Tasco/VETC app, email? Can a
   pilot use Zalo? This sets the reminder and status channel in the proposal.
9. Would a customer-facing feature live best inside an existing Tasco app (VETC, Tasco Auto)
   or stand alone? This changes the integration story (embed vs. standalone PWA).

## Claims and AI
10. Who assesses motor damage today: in-house adjusters, the service centre or third-party
    assessors? Do they work from photos already? This shows where AI triage saves time.
11. How sensitive is fraud versus speed? Would the AI's consistency flags (plate mismatch,
    vehicle model, damage vs. description) be valuable or noise? This sets the emphasis in the
    triage slide.
12. Any constraints on AI: cloud LLMs allowed, data must stay in Vietnam, approved vendors
    (Azure via the Microsoft partnership)? This decides the model and hosting choice in the
    proposal.
13. Are there regulatory or internal rules about automated decisions on claims, or on customer
    communication? This confirms our "advice only, people decide" stance.

## Back-office and operations (new angle from the email)
14. Which back-office tasks eat the most staff time: data entry from paper or PDFs, policy
    issuance, reconciliation with insurers, commission statements, claim documents? Our ERP
    already does policies, commissions and accounting, so we could add a document-extraction
    or reconciliation use case.
15. How many policies and claims per month in the pilot segment, and how many staff handle
    them? This sizes value and cost (VND per policy) credibly.

## Pilot logistics
16. Which dealer, branch or segment would you offer for the pilot, and who would use it daily
    (agents, adjusters, call centre)? This replaces our assumed "one dealer, 300–1,000 policies".
17. What data can be shared under NDA in week 1, and what is the consent or legal process for
    customer data (Decree 13/2023)? This makes the week-1 plan realistic.
18. Who on Tasco's side owns the pilot decision on 5 December, and what would make it a "scale"?

## Pitch format (if time allows; otherwise ask GenAI Fund by email)
19. How long is the 22 October pitch, live demo allowed, and which language: English, or
    Vietnamese slides welcome?
20. What do the judges weigh most between practical impact, feasibility and scale potential?

## How we use the answers (after the call)
- Rewrite the impact table and success criteria with Tasco's own numbers and KPIs, in the
  proposal (`docs/tasco/Tasco_Proposal.html`) and the deck's impact slide.
- Re-order the deck so the pain Tasco names first leads (deck: claude.ai/artifact/QRVsn3Jpt8Wa7NQsiq2D4d).
- If back-office pain dominates: add one slide and a proposal paragraph on a back-office use
  case, for example AI extraction of claim and policy documents into the system, or insurer
  reconciliation.
- Adjust channels (Zalo), the integration table and the pilot segment to what they say.
- Re-export the deck PDF and re-render the proposal PDF (2 pages) before 15 Oct.

## Verification
The output is the question list above; no code changes. After the call, check every assumption
marked "[assumed]" or "Tasco data, week 1" in the proposal and deck against the answers.
