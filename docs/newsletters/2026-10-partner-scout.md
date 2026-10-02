---
subject: An agent that looks for ERP partners, and what it taught me about agents
preheader: The Partner Scout searches the web for implementation freelancers, writes a first message, and never sends it.
date: 2026-10-05
---

# An agent that looks for ERP partners

This week I built an agent for a job I kept postponing: finding people who would implement
GrowERP for small companies in their own country. I can't visit every country, and
the best partners are usually not looking for a new platform. They are independent
consultants already helping small businesses with Odoo, ERPNext or Dolibarr.

## What the Partner Scout does

You give it a country. It searches the web for independent ERP consultants and small
implementation firms, scores each one from 1 to 10, and skips anyone already in your CRM.
For every good candidate it stores a lead and an opportunity in your CRM. The opportunity
holds the evidence links and a personal draft message of at most 150 words.

The first test run on Thailand took under two minutes and came back with two Odoo
consultants. Both drafts opened with something specific from the person's own profile, and
I would have sent either one after a small edit.

It never sends anything itself. The instruction forbids it, and the agent has no tool that
could. Writing to a person stays a human decision.

The pitch is the [revenue-first sequence](https://www.growerp.org/content/revenue-first): start a small company with
its website, leads and sales pipeline, and add accounting and stock once the system is
already earning money. For a consultant that means small first projects, quick results for
the client, and no licence fees eating into their margin.

## What it took to make it work

The agent is one file you upload in **Agent Control → AI Agents**. Making it work changed
the agent platform itself, and those changes help every agent, not just this one:

1. **Search the web** is a new switch on any agent. Until now agents only saw what was
   inside GrowERP.
2. **Max AI calls per run** is now a setting per agent. Each agent used to stop after 10 calls
   to keep costs predictable. That is fine for a daily digest, but not enough for research:
   one candidate needs a search, a duplicate check and two saves.
3. **Agents now act as your company's AI Agent user.** This was the real bug. Agents used
   to run under a system account, so some records they created ended up outside your
   company and never showed in your CRM. Everything an agent creates is now owned by your
   company and assigned to its AI Agent user, so you can see and reassign it.

The third one I only found because the first test run "succeeded" while the CRM stayed
empty. Five opportunities existed, just not in the right company. Check where the data
lands, not only that the run said done.

## Trying it yourself

The [Partner Scout user guide](https://github.com/growerp/growerp/blob/master/docs/Partner_Scout_Agent_User_Guide.md)
covers installing the file, setting a schedule per country, working through the drafts, and
the error messages you may hit. You need your own Gemini API key: a run uses up to 40 AI
calls, more than the free monthly allowance covers.

You can also point it at a different question. The instruction has plain sections for
targets, scoring and rules, so recruiting resellers or local accountants instead is mostly a
matter of editing the TARGETS section.

## If you implement ERP for small companies

Maybe you are one of the people this agent is looking for. If you implement ERP for small
businesses and the revenue-first approach makes sense to you, reply to this mail. I would
rather hear from you directly than have the agent find you.

If you have any suggestions, or you need help, use our support email address at
support@growerp.com

Thanks for reading, see you next week!
