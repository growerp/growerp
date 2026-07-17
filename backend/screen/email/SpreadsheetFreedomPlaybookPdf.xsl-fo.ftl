<!--
XSL-FO template for the Spreadsheet Freedom Playbook PDF
Content source: docs/marketing/spreadsheet-freedom-playbook.md
Delivered as attachment of EmailTemplate SPREADSHEET_FREEDOM_GUIDE
-->
<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Helvetica, Arial, sans-serif">
    <fo:layout-master-set>
        <fo:simple-page-master master-name="main" page-height="29.7cm" page-width="21cm"
                               margin-top="1.5cm" margin-bottom="1.5cm"
                               margin-left="2cm" margin-right="2cm">
            <fo:region-body margin-top="0.4in" margin-bottom="0.4in"/>
            <fo:region-before extent="0.4in"/>
            <fo:region-after extent="0.4in"/>
        </fo:simple-page-master>
    </fo:layout-master-set>

    <fo:page-sequence master-reference="main">
        <fo:static-content flow-name="xsl-region-before">
            <fo:block text-align="center" font-size="9pt" color="#718096">
                The Complete Spreadsheet Freedom Playbook
            </fo:block>
        </fo:static-content>
        <fo:static-content flow-name="xsl-region-after">
            <fo:block text-align="center" font-size="9pt" color="#718096">
                © ${ec.l10n.format(ec.user.nowTimestamp, 'yyyy')} GrowERP — open-source ERP for growing businesses — growerp.com — page <fo:page-number/>
            </fo:block>
        </fo:static-content>

        <fo:flow flow-name="xsl-region-body">

            <!-- ═══ COVER / TITLE ═══ -->
            <fo:block background-color="#667EEA" color="white" padding="24pt" margin-bottom="18pt">
                <fo:block font-size="26pt" font-weight="bold" margin-bottom="8pt">
                    The Complete Spreadsheet Freedom Playbook
                </fo:block>
                <fo:block font-size="13pt" line-height="1.5">
                    A practical, plain-English guide for SMB owners who are ready to stop
                    firefighting data and start making decisions with confidence.
                </fo:block>
            </fo:block>

            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="18pt">
                No fluff, no vendor pitch disguised as a guide. Work through the five parts in
                order — most owners finish the whole playbook in under an hour, and the 30-day
                plan in exactly that: 30 days.
            </fo:block>

            <!-- ═══ PART 1 ═══ -->
            <fo:block font-size="17pt" font-weight="bold" color="#2D3748" margin-bottom="10pt"
                      border-bottom="2pt solid #667EEA" padding-bottom="4pt" keep-with-next="always">
                Part 1 — Why Double-Entry Is Silently Killing Your Growth
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="10pt">
                Every time you copy a number from an invoice into a spreadsheet, you are not just
                losing a minute. You are creating a crack in your data foundation — and cracks compound.
            </fo:block>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                The real cost of manual re-entry
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="4pt">
                • <fo:inline font-weight="bold">Time:</fo:inline> a typical 5–50 person business re-keys the
                same data 3–5 times (quote, invoice, stock sheet, cash sheet, month-end report). At 5+ hours
                per week that is 250+ hours per year — six full working weeks.
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="4pt">
                • <fo:inline font-weight="bold">Errors:</fo:inline> industry studies consistently find 1–4% of
                manually entered cells contain an error. One wrong stock count or price cell propagates into
                every report built on it.
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="4pt">
                • <fo:inline font-weight="bold">Trust:</fo:inline> once the team catches one wrong number,
                every number is doubted. Decisions slow down or get made on gut feel instead.
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="10pt">
                • <fo:inline font-weight="bold">Key-person risk:</fo:inline> the "spreadsheet wizard" becomes a
                single point of failure. When they are on holiday, month-end stalls.
            </fo:block>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                When "good enough" becomes dangerous
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="6pt">
                Spreadsheets are fine when one person sells one product line. They become a business
                risk when any of these are true:
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="2pt">• Two or more people edit the same file (version chaos, silent overwrites).</fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="2pt">• You cannot answer "what is in stock right now?" without calling someone.</fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="2pt">• Month-end takes more than one day of reconciliation.</fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="8pt">• Your cash position is a guess between bank-statement checks.</fo:block>
            <fo:block background-color="#EBF4FF" border="1pt solid #BEE3F8" padding="10pt" margin-bottom="18pt">
                <fo:block font-size="10.5pt" color="#2C5282" line-height="1.6">
                    <fo:inline font-weight="bold">Self-check:</fo:inline> if two or more bullets above describe
                    you, you have passed the tipping point. Part 3 of this playbook is your way out.
                </fo:block>
            </fo:block>

            <!-- ═══ PART 2 ═══ -->
            <fo:block font-size="17pt" font-weight="bold" color="#2D3748" margin-bottom="10pt"
                      border-bottom="2pt solid #667EEA" padding-bottom="4pt" keep-with-next="always">
                Part 2 — The Self-Assessment: Are You Ready to Ditch Spreadsheets?
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="8pt">
                Score each statement: <fo:inline font-weight="bold">0 = never true, 1 = sometimes,
                2 = weekly, 3 = daily.</fo:inline>
            </fo:block>
            <fo:table table-layout="fixed" width="100%" margin-bottom="10pt" border="1pt solid #E2E8F0">
                <fo:table-column column-width="8%"/>
                <fo:table-column column-width="74%"/>
                <fo:table-column column-width="18%"/>
                <fo:table-header>
                    <fo:table-row background-color="#667EEA" color="white" font-weight="bold" font-size="10.5pt">
                        <fo:table-cell padding="5pt"><fo:block>#</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt"><fo:block>Statement</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt"><fo:block>Score (0–3)</fo:block></fo:table-cell>
                    </fo:table-row>
                </fo:table-header>
                <fo:table-body font-size="10.5pt" color="#4A5568">
                    <#assign statements = [
                        "The same data gets typed into more than one place",
                        "We find errors in reports after decisions were already made",
                        "Nobody knows the exact stock level without checking physically",
                        "Our cash position is only clear right after bank reconciliation",
                        "Month-end reporting takes more than one working day",
                        "Only one person really understands our spreadsheets",
                        "Customer, order and invoice data live in separate files or tools",
                        "We delay decisions because we don't trust the numbers"]>
                    <#list statements as s>
                    <fo:table-row <#if s?index % 2 == 1>background-color="#F7FAFC"</#if>>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>${s?index + 1}</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>${s?xml}</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>____</fo:block></fo:table-cell>
                    </fo:table-row>
                    </#list>
                </fo:table-body>
            </fo:table>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                Your score
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="3pt">
                • <fo:inline font-weight="bold">0–6 — Watchful.</fo:inline> Spreadsheets still serve you.
                Keep this playbook and re-score every quarter.
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="3pt">
                • <fo:inline font-weight="bold">7–13 — Leaking.</fo:inline> You are paying a hidden data tax
                every week. Start the 30-day plan (Part 3) within this quarter.
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-left="12pt" margin-bottom="10pt">
                • <fo:inline font-weight="bold">14–24 — Bleeding.</fo:inline> Double-entry is actively
                constraining growth. Start the 30-day plan now — it is designed to run without disrupting
                daily operations.
            </fo:block>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                Map where your data lives
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="18pt">
                Before any migration, list every place business data is kept. For each one write down: what
                it holds, who updates it, and where its numbers get re-typed. Typical list: quoting sheet,
                invoice tool, stock sheet, bank export, contact list, month-end master sheet. This map
                <fo:inline font-style="italic">is</fo:inline> your migration scope — most businesses find
                5–9 sources and 10–20 re-entry touchpoints.
            </fo:block>

            <!-- ═══ PART 3 ═══ -->
            <fo:block font-size="17pt" font-weight="bold" color="#2D3748" margin-bottom="10pt"
                      border-bottom="2pt solid #667EEA" padding-bottom="4pt" keep-with-next="always">
                Part 3 — The 30-Day Migration Plan (Without Disrupting Operations)
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="10pt">
                The single biggest migration mistake is "big bang": switching everything at once. The
                low-risk path is three phases run in parallel with normal business — the spreadsheets stay
                alive until the system has proven itself.
            </fo:block>

            <#assign weeks = [
                {"title": "Week 1 — Assess &amp; Map", "items": [
                    "Complete the self-assessment (Part 2) and the data-source map.",
                    "Mark the Core Three flows: inventory, sales, cash. Everything else waits.",
                    "Pick your system (use the vendor questions in Part 4).",
                    "Create your company in the new system; invite yourself only.",
                    "Load master data: products, customers, suppliers. Export from your spreadsheets — do not re-type."]},
                {"title": "Week 2 — Connect the Core Three", "items": [
                    "Enter opening stock counts and current price lists.",
                    "From Monday: create every NEW quote, order and invoice in the system (historical data stays in the old sheets — do not migrate history).",
                    "Record payments against invoices as they arrive; your cash position is now live.",
                    "Run the old spreadsheet in parallel as a safety net. Compare totals on Friday. Investigate every mismatch — it is almost always the sheet."]},
                {"title": "Week 3 — Eliminate the Chaos", "items": [
                    "Invite the rest of the team; one 30-minute walkthrough each.",
                    "Turn on automated reports: stock below reorder level, open invoices, weekly sales, cash summary.",
                    "Do the first system-generated month-end (or week-end) close. Time it — then compare with your old process.",
                    "Retire the parallel spreadsheets one by one. Rule: a sheet dies when the system has matched it two weeks in a row."]},
                {"title": "Week 4 — Scale With Confidence", "items": [
                    "Freeze the last spreadsheet as read-only archive.",
                    "Reinvest the reclaimed 5+ hours: pipeline follow-up, supplier renegotiation, or simply going home on time.",
                    "Extend beyond the Core Three only now: accounting integration, website orders, warehouse locations — one module per month, never more.",
                    "Book a 15-minute monthly numbers review — with data you finally trust."]}]>
            <#list weeks as week>
            <fo:block background-color="#F7FAFC" border="1pt solid #E2E8F0" padding="12pt" margin-bottom="10pt">
                <fo:block font-size="12.5pt" font-weight="bold" color="#667EEA" margin-bottom="6pt" keep-with-next="always">
                    ${week.title}
                </fo:block>
                <#list week.items as item>
                <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">
                    [&#160;&#160;]&#160;&#160;${item?xml}
                </fo:block>
                </#list>
            </fo:block>
            </#list>
            <fo:block background-color="#EBF4FF" border="1pt solid #BEE3F8" padding="10pt" margin-bottom="18pt">
                <fo:block font-size="10.5pt" color="#2C5282" line-height="1.6">
                    <fo:inline font-weight="bold">Rule of thumb:</fo:inline> if any week slips, let it slip.
                    Never skip the parallel-run safety net to catch up.
                </fo:block>
            </fo:block>

            <!-- ═══ PART 4 ═══ -->
            <fo:block font-size="17pt" font-weight="bold" color="#2D3748" margin-bottom="10pt"
                      border-bottom="2pt solid #667EEA" padding-bottom="4pt" keep-with-next="always">
                Part 4 — Questions to Ask Any ERP Vendor Before You Sign
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="10pt">
                Ask these verbatim. Vague answers are answers.
            </fo:block>
            <fo:block font-size="12.5pt" font-weight="bold" color="#667EEA" margin-bottom="5pt" keep-with-next="always">Cost &amp; lock-in</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">1. What is the TOTAL first-year cost for my team size — licences, implementation, training, support?</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">2. What does it cost to leave? Can I export ALL my data (not a PDF dump) in an open format at any time?</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="8pt">3. Is the software open source? If you disappear, can someone else run it?</fo:block>
            <fo:block font-size="12.5pt" font-weight="bold" color="#667EEA" margin-bottom="5pt" keep-with-next="always">Fit &amp; scope</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">4. Can I start with only inventory, sales and cash — and add modules later?</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">5. What does a 5–50 person company implementation actually look like? Talk me through the last one you did.</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="8pt">6. Does it run on the devices we use (web, phone, tablet, desktop)?</fo:block>
            <fo:block font-size="12.5pt" font-weight="bold" color="#667EEA" margin-bottom="5pt" keep-with-next="always">Operations</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">7. How do updates happen, and have they ever broken a customer's workflow?</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="3pt">8. Where is my data hosted, who can see it, and how is it backed up?</fo:block>
            <fo:block font-size="10.5pt" color="#4A5568" line-height="1.55" margin-left="10pt" margin-bottom="8pt">9. What happens to my price when I grow from 5 users to 25?</fo:block>
            <fo:block background-color="#FFF5F5" border="1pt solid #FEB2B2" padding="10pt" margin-bottom="18pt">
                <fo:block font-size="10.5pt" color="#9B2C2C" line-height="1.6">
                    <fo:inline font-weight="bold">Red flags:</fo:inline> multi-year contracts before a pilot,
                    per-module pricing that doubles the quote, "we'll need to scope that" for question 1, and
                    any vendor who cannot demo YOUR workflow live.
                </fo:block>
            </fo:block>

            <!-- ═══ PART 5 ═══ -->
            <fo:block font-size="17pt" font-weight="bold" color="#2D3748" margin-bottom="10pt"
                      border-bottom="2pt solid #667EEA" padding-bottom="4pt" keep-with-next="always">
                Part 5 — Calculate Your ROI Before You Commit
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="10pt">
                Use last month's real numbers. Conservative estimates only.
            </fo:block>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                Step 1 — What spreadsheets cost you today (per month)
            </fo:block>
            <fo:table table-layout="fixed" width="100%" margin-bottom="10pt" border="1pt solid #E2E8F0">
                <fo:table-column column-width="26%"/>
                <fo:table-column column-width="44%"/>
                <fo:table-column column-width="30%"/>
                <fo:table-header>
                    <fo:table-row background-color="#667EEA" color="white" font-weight="bold" font-size="10.5pt">
                        <fo:table-cell padding="5pt"><fo:block>Item</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt"><fo:block>How to estimate</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt"><fo:block>Example</fo:block></fo:table-cell>
                    </fo:table-row>
                </fo:table-header>
                <fo:table-body font-size="10.5pt" color="#4A5568">
                    <fo:table-row>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>Re-entry time</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>hours/week × hourly cost × 4.3</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>5 h × €35 × 4.3 = €752</fo:block></fo:table-cell>
                    </fo:table-row>
                    <fo:table-row background-color="#F7FAFC">
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>Error correction</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>incidents × hours to fix × hourly cost</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>3 × 2 h × €35 = €210</fo:block></fo:table-cell>
                    </fo:table-row>
                    <fo:table-row>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>Stock misses</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>stock-outs or overstock write-offs / month</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>€300</fo:block></fo:table-cell>
                    </fo:table-row>
                    <fo:table-row background-color="#F7FAFC">
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>Month-end overrun</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>extra days × day cost</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #E2E8F0"><fo:block>1 × €280 = €280</fo:block></fo:table-cell>
                    </fo:table-row>
                    <fo:table-row font-weight="bold" color="#2D3748">
                        <fo:table-cell padding="5pt" border-top="1pt solid #CBD5E0"><fo:block>Total hidden cost</fo:block></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #CBD5E0"><fo:block/></fo:table-cell>
                        <fo:table-cell padding="5pt" border-top="1pt solid #CBD5E0"><fo:block>€1,542 / month</fo:block></fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                Step 2 — What the system costs (per month)
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="10pt">
                Licence/hosting + (one-time setup ÷ 24 months). For an open-source system in this
                example: €150 + €50 = <fo:inline font-weight="bold">€200 / month</fo:inline>.
            </fo:block>
            <fo:block font-size="13pt" font-weight="bold" color="#2D3748" margin-bottom="6pt" keep-with-next="always">
                Step 3 — The verdict
            </fo:block>
            <fo:block background-color="#F7FAFC" border="1pt solid #E2E8F0" padding="10pt"
                      font-family="Courier, monospace" font-size="10pt" color="#2D3748"
                      line-height="1.6" margin-bottom="8pt">
                <fo:block>ROI = (hidden cost recovered - system cost) ÷ system cost</fo:block>
                <fo:block>&#160;&#160;&#160;&#160;= (1,542 - 200) ÷ 200&#160;&#160;=&#160;&#160;6.7×&#160;&#160;— payback in the first month</fo:block>
            </fo:block>
            <fo:block font-size="11pt" color="#4A5568" line-height="1.6" margin-bottom="18pt">
                If your own numbers show payback longer than 6 months, stay on spreadsheets and re-score
                quarterly. Most businesses past the Part 2 tipping point see payback in 4–8 weeks.
            </fo:block>

            <!-- ═══ CLOSING ═══ -->
            <fo:block background-color="#667EEA" color="white" padding="16pt" margin-top="8pt">
                <fo:block font-size="15pt" font-weight="bold" margin-bottom="8pt">What Now?</fo:block>
                <fo:block font-size="11pt" line-height="1.6" margin-bottom="8pt">
                    You have the assessment, the map, the 30-day plan, the vendor questions and your ROI
                    number. The only remaining step is picking the system to run the plan on.
                </fo:block>
                <fo:block font-size="11pt" line-height="1.6" margin-bottom="8pt">
                    GrowERP is open-source ERP built for exactly this migration: start with inventory,
                    sales and cash on day one, add modules when you are ready, export everything at any
                    time, and run it on web, phone, tablet or desktop.
                </fo:block>
                <fo:block font-size="12pt" font-weight="bold">
                    Try it free at https://growerp.com — or reply to the email that delivered this
                    playbook and we will help you plan Week 1.
                </fo:block>
            </fo:block>

        </fo:flow>
    </fo:page-sequence>
</fo:root>
