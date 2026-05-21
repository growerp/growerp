---
name: moqui-architect
description: Moqui 8-layer architecture guide for Moqui/GrowERP code generation. Use when writing or reviewing Moqui backend code (services, entities, screens, REST, EECA/SECA, templates).
---

You are operating with full awareness of the Moqui 8-layer "Panoramic Knowledge Graph" architecture. Apply this knowledge to every code generation, review, and diagnosis task.

## The 8 Layers

### L0 — Global Boundaries (Component Dependencies)
- **File**: `component.xml`
- **Key**: `<depends-on>` tags define allowed cross-module calls
- **Rule**: Never suggest a call from module A to module B unless B is listed in A's `<depends-on>`. Cross-module circular calls are forbidden.

### L1 — Data Skeleton (Entity/Field/Relation)
- **Files**: `entity/*.xml`
- **Key elements**: `<field>`, `<relationship>`, `require-audit-log`, `use-cache`, `<relationship type="one-nofk">`
- **Rules**:
  - Always inspect `<field>` definitions before assuming a column exists
  - `require-audit-log="true"` entities have change history — never bypass with direct SQL
  - `use-cache="true"` entities are memory-cached — invalidate on write
  - `type="one-nofk"` relationships = master/detail without DB-enforced FK — handle in service layer

### L2 — Core Logic (Service Orchestration)
- **Files**: `service/*.xml`
- **Key elements**: `<entity-find>`, `<service-call>`, `<script>`, `async="true"`
- **Rules**:
  - Trace `<entity-find>` to know which tables a service reads
  - `<script>` blocks contain Groovy — complex calculations live here
  - `async="true"` services run in background — do not assume immediate completion or return values

### L3 — Automation (EECA/SECA Event Triggers)
- **Files**: `eeca/*.xml`, `seca/*.xml`
- **Key elements**: `<eeca>`, `<seca>`, `sendEmail` parameter mapping
- **Rules**:
  - Before writing any entity-update service, check for EECA triggers on that entity — side effects (e.g., inventory deduction on order creation) may fire automatically
  - Before calling a service, check SECA triggers — audit logs, notifications, or chained services may fire
  - Email sends are mediated through screen templates — find the screen before editing email content

### L4 — Interaction & API Layer (Screen/Transition/REST)
- **Files**: `screen/*.xml`, `service/rest.xml`
- **Key elements**: `<transition>`, `<include-screen>`, `<actions>`, `<condition>`, `<form-single>`, `<field>`, `<resource>`, `<method>`
- **Rules**:
  - Every frontend button maps to a `<transition>` which calls a service — trace this chain before modifying UI or backend
  - `<include-screen>` = component nesting — dashboard data sources are loaded in `<actions>` blocks
  - REST endpoints are declared in `service/rest.xml` — never create ad-hoc endpoints outside this file
  - `<condition>` tags in screens = dynamic UI visibility rules (e.g., approval button only in certain states)
  - Form field bindings → service params — changing a field name requires updating both screen and service

### L5 — Metadata Extension (Custom Entity/Service Overrides)
- **Files**: `entity/*.xml`, `service/*.xml`, `data/*Data.xml`
- **Key elements**: `<extend-entity>`, `override="true"`, DataFeed-related tables
- **Rules**:
  - Always check `<extend-entity>` before assuming a base entity's field list is complete — custom fields are injected here
  - `override="true"` on a service = the original core logic has been replaced — read the override, not the base
  - DataFeed entries define real-time data pumps to Kafka/Elasticsearch — check before assuming data is DB-only

### L6 — Enterprise Context (Rules/Roles/Templates/Multi-Tenant)
- **Files**: `data/*Data.xml`, `template/*.ftl`, `MoquiConf.xml`
- **Key elements**: `mantle.rule.RuleSet`, Party/Role identity tables, `.ftl`/`.xsl-fo` template refs, `<tenant>`, `<datasource>`
- **Rules**:
  - Dynamic business logic (promotions, shipping rates) lives in `RuleSet` DB records, not code
  - UserAccount → Party → Role chain defines access control — bridge IT accounts to business entities before writing permission logic
  - PDF invoices and financial reports render via `.ftl` or `.xsl-fo` — find the template before editing output format
  - `<tenant>` + `<datasource>` in `MoquiConf.xml` define physical SaaS isolation — never query across datasource boundaries

### L7 — Ecosystem Monitoring (External Integration & Observability)
- **Files**: `camel/*.xml`, DB CMS tables (`moqui.resource.DbResource`), runtime `ArtifactHit` tables
- **Key elements**: `<route>`, `moqui:` protocol, DbResource, ArtifactHit
- **Rules**:
  - External system integration (FTP, JMS, MQ) flows through Camel routes — trace `<route>` before assuming direct DB writes from external systems
  - Dynamic content (carousel images, homepage assets) may live in `DbResource` DB tables, not the filesystem
  - `ArtifactHit` tables record per-API performance — consult before optimizing; they identify the actual bottlenecks

### L8 — Engineering Defense (Encryption/Timeline/Notifications/Boot)
- **Files**: `entity/*.xml`, `service/*.xml`, file naming conventions
- **Key elements**: `encrypt="true"`, `fromDate`/`thruDate`, WebSocket push services, `*SeedData`/`*DemoData` naming
- **Rules**:
  - Fields marked `encrypt="true"` are AES-encrypted at rest — **never write raw SQL that reads these fields directly**
  - Entities with `fromDate`/`thruDate` are timeline tables — **every query must filter `thruDate IS NULL OR thruDate > now()`** to exclude expired records
  - Real-time frontend notifications (red-dot alerts) go through WebSocket push services — find the service before wiring new backend events to UI
  - `*SeedData.xml` = production dictionary data, loaded in all envs; `*DemoData.xml` = test-only — never put core config in DemoData

## Quick Reference: Where to Look

| I need to... | Look here |
|---|---|
| Understand module dependencies | `component.xml` → `<depends-on>` |
| Know what fields an entity has | `entity/*.xml` → `<field>` + `<extend-entity>` |
| Find what a button does | `screen/*.xml` → `<transition>` → `service/*.xml` |
| Add a REST endpoint | `service/rest.xml` → `<resource>`/`<method>` |
| Understand side effects of saving entity X | `eeca/*.xml` → filter by entity name |
| Query a timeline entity | Add `thruDate IS NULL OR thruDate > now()` |
| Edit an email template | `service/*.xml` → `sendEmail` → screen ref |
| Find dynamic business rules | DB: `mantle.rule.RuleSet` records |
| Add a field to a base entity | `entity/*.xml` → `<extend-entity>` |
| Debug a slow API | DB: `ArtifactHit` table |

## Phase-Based Activation

When working in this codebase, mentally activate layers progressively:
- **Phase 1 (L0–L2)**: Always active. Component scope + entity structure + service flow.
- **Phase 2 (L3–L4)**: Activate when touching automation or UI. Check EECA/SECA + screen transitions.
- **Phase 3 (L5–L8)**: Activate for enterprise features, security, or integration work.
