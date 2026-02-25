# Plan: Marketing/Outreach/Sales Onboarding Course — Updated with Integration Audit

The `course_marketing_sales.md` outline exists and the `CourseMarketingSales` seed data is partially written in `GrowerpCourseData.xml` — but broken. All four packages are wired into the `admin` app's menu system and all models and REST clients are complete. However, several defects and gaps must be addressed alongside the course content work.

---

## Bugs to Fix (Prerequisites)

**1. ✅ DONE — Broken XML in `GrowerpCourseData.xml`**
Fixed. All `CourseMarketingSales` content is now inside the `<entity-facade-xml>` root tag.

**2. ✅ DONE — Duplicate `@POST` annotation in `rest_client.dart`**
Removed the duplicate `@POST("rest/s1/growerp/100/Assessment/Question")` line on `createAssessmentQuestion`. Run `melos build` to regenerate the Retrofit client.

**3. ✅ DONE — Quote/Order conversion from Opportunity implemented in `growerp_sales`**
Implemented as a sales order (`FinDoc`, `docType: order`, `sales: true`, `status: inPreparation`). Changes:
- `opportunity_stages_model.dart`: added `'Closed Won'` and `'Closed Lost'` stages
- `opportunity_event.dart`: added `OpportunityConvertToOrder` event
- `opportunity_state.dart`: added `convertedOrderId` and `convertedPseudoId` fields
- `opportunity_bloc.dart`: implemented `_onOpportunityConvertToOrder` handler
- `opportunity_dialog.dart`: added **Convert to Quote** button (visible on existing records only)
- `translate_bloc_messages.dart`: added `'opportunityConvertSuccess'` case

**4. 🟠 Medium — Undeclared transitive dependencies in `growerp_outreach/pubspec.yaml`**
`bloc_concurrency` and `stream_transform` are used directly in `outreach_message_bloc.dart` but not declared as direct dependencies. Add them explicitly to avoid breakage if `growerp_core` ever removes them.

**5. 🟠 Medium — Version misalignment**
`growerp_outreach` and `growerp_courses` are at `0.0.1` while the ecosystem is at `1.9.0+`. Bump both to `1.9.0` (aligning with melos ecosystem version) before any publishing/release.

---

## Course Content Steps

**6. ✅ DONE — `GrowerpCourseData.xml` fully written**
14 lessons across 5 modules. XML validates clean (`xmllint --noout`). Record counts: 2 courses, 10 modules, 23 lessons total.

| Module | Lessons |
|---|---|
| M1: Foundation | L1.1 Growth Ecosystem, L1.2 Navigation |
| M2: Marketing | L2.1 Personas, L2.2 Landing Pages, L2.3 Assessments, L2.4 Content/Social |
| M3: Outreach | L3.1 Platform Config, L3.2 Campaigns, L3.3 Message Sequences, L3.4 Automation |
| M4: Sales | L4.1 Creating Opportunities, L4.2 Working the Pipeline, L4.3 Convert to Quote |
| M5: Capstone | Full 9-step end-to-end walkthrough |

---

## Completed Tasks (all bugs resolved)

- ✅ Bug #4: Added `bloc_concurrency: ^0.3.0` and `stream_transform: ^2.1.0` to `growerp_outreach/pubspec.yaml`
- ✅ Bug #5: Bumped `growerp_outreach` and `growerp_courses` versions from `0.0.1` to `1.9.0`

---

## Verification

- Run `./gradlew cleandb && java -jar moqui.war load types=seed,seed-initial,install no-run-es` from `moqui/`
- Open the admin app → Courses → confirm `CourseMarketingSales` appears with 5 modules and 14 lessons
- Confirm lesson Markdown renders and key points display in `CourseViewer`
- Open an existing Opportunity → confirm **Convert to Quote** button is visible → tap it → confirm a green success snackbar with the new order pseudoId
- Navigate to Orders → confirm the new order appears in Preparation status
- Run `melos build` after fixing the duplicate `@POST` annotation
- Manually navigate each package's main screens in the admin app to confirm menus load (already wired in `admin/lib/main.dart`)

---

## Notes & Decisions

- Quote is implemented as a sales order in `inPreparation` status — no new document type
- Course audience is end-users (what to click, not BLoC internals)
- Seed as `type=seed`, `ownerPartyId="_NA_"` — available to all companies on the instance
- `growerp_outreach` and `growerp_sales` have no compile-time dependency on `growerp_marketing` — cross-funnel flows (e.g. landing page ID referenced in a campaign) are loose string references only; type safety is a known architectural limitation
- The LinkedIn platform adapter uses the MCP browser bridge (`FlutterMcpBrowserService`) and requires the companion browser extension to be installed — called out in the Platform Configuration lesson (M3 L3.1)
- Hardcoded `growerp.com` base URL bug in `OutreachServices100.xml` line 1016 documented in the Automation lesson (M3 L3.4)
