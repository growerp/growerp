# GrowERP Content Voice Guide

Everything the AI writes for you — newsletter issues, X threads, Substack Notes, outreach
messages — goes out under your name. This page defines how it should sound, and where that
definition lives so you can change it.

**Where it lives:** **System Setup → AI → Writing style**. The text in that field is injected
into every content prompt of your tenant. Leave it empty and the built-in default applies
(`DEFAULT_HOUSE_VOICE` in `backend/service/GeminiAiUtil.groovy`).

**Where it comes from:** press **Generate from my writing…**, select up to 20 documents you
wrote (`.md`, `.txt`), and the AI derives the voice from them. Review the result, edit it, then
**Save AI Settings**. Nothing is stored until you save.

---

## The GrowERP voice

Derived from the 2024 run of the weekly email — 52 issues, the most consistent stretch in the
archive.

| Axis | What it means |
|---|---|
| **Title** | A plain statement or a question. *"Got stuck while programming?"*, *"Low Code in ERP?"* No hook engineering. |
| **Opening** | A builder's log: what you are working on this week and the problem it ran into. Not a sales hook. |
| **Person** | "I" for the work, "we" for the project and the reader. The founder writing, not a brand. |
| **Register** | Plain, direct, modest. No hype, no superlatives, no manufactured urgency. |
| **Substance** | Concrete names and numbers. Show the reasoning including the dead ends; say plainly when something is still uncertain. |
| **Shape** | Short intro paragraph → sub-headings → numbered lists of practical steps. Links where a claim needs backing. |
| **Close** | An offer of help, then: *"Thanks for reading, see you next week!"* Long form only. |
| **Avoid** | Subject-line options, pain agitation, "My controversial opinion?", PS lines. Also: do not imitate the archive's typos — voice, not mistakes. |

## Before and after

**Opening — wrong:**
> You probably know that soul-crushing feeling when your business runs on a spreadsheet nobody
> understands. It is a slow, agonizing death by a thousand papercuts.

**Opening — right:**
> While working on the SAGE50 conversion this week I ran into the same thing twice: the
> customer's real system is not the accounting package, it is one spreadsheet on one laptop.

**Claim — wrong:**
> GrowERP is the complete, powerful, all-in-one ERP solution that transforms your business
> overnight.

**Claim — right:**
> GrowERP puts orders, stock, invoices and accounting in one system. Live in a day, free for two
> weeks, no credit card. Whether it fits a 5-person business is the part I am still testing.

**Close — wrong:**
> Stop wasting your weekends. Click here now!
>
> Talk soon, Hans, founder. PS: don't miss this.

**Close — right:**
> If you have any suggestions, or you need help, use our support email address at
> support@growerp.com
>
> Thanks for reading, see you next week!

## Per-channel differences

The voice is the same everywhere; the shape is not. Format rules live in code
(`getAdaptationRules` in `GeminiAiUtil.groovy`), not in the writing-style field:

- **Substack article / email** — the full shape above, sign-off included.
- **X thread** — blank-line separated blocks, each at most 280 characters. The hook is the first
  block. No sign-off. A block over 280 characters fails the publish rather than being truncated.
- **Substack Note** — one idea, under 500 characters, no headline and no sign-off.
- **LinkedIn DM** — short, specific, ends on a question, carries no URL.

## When the voice drifts

The generated text is only as good as the instruction block. If pieces come back sounding
generic, sharpen the field rather than editing each piece: name the thing that is wrong
("no rhetorical questions in the opening", "never use the word *seamless*") and save. The next
generated piece picks it up — no redeploy, and it applies to every channel at once.
