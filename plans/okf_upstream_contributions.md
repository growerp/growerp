# OKF upstream contribution drafts (Phase 5)

Findings from running the reference implementation (GoogleCloudPlatform/knowledge-catalog)
against the GrowERP OKF bundle (Phase 4). Posting to the public repo was intentionally left
to a human — review and file/post these under your own judgment.
`gh` is already authenticated as hansbak.

## 1. Comment on existing issue #48 (absolute links → 0 edges)

Issue: "visualize: 0 edges for spec-recommended absolute links and CommonMark link titles"
(also related: #157). Our independent repro adds producer-side weight:

```
gh issue comment 48 --repo GoogleCloudPlatform/knowledge-catalog --body-file - <<'EOF'
Independent confirmation from another producer: we generate an OKF bundle from a live ERP
data model (444 entity concepts, one .md per entity with relationship links). Following
SPEC.md §5.1 we first emitted absolute bundle-relative links (`/tables/OrderHeader.md`)
and `visualize` produced **446 concepts, 0 edges** — every edge silently dropped by the
`target.startswith("/")` guard in `viewer/generator.py`. Switching the exporter to
relative links gives 2438 edges.

The sample bundles in this repo also use relative links only, so §5.1 absolute links are
spec-recommended but unusable with the reference tooling. Either resolving them in
`_extract_links` (strip the leading `/` against bundle root) or demoting them in the spec
would remove the trap for new producers.
EOF
```

## 2. New issue: visualizer type palette hardcoded to BigQuery types

No duplicate found (searched "palette", "visualizer color").

Title: `visualize: _TYPE_PALETTE only colors BigQuery types — all other concept types render the default gray`

Body draft:
> `viewer/generator.py` maps colors via `_TYPE_PALETTE = {"BigQuery Dataset", "BigQuery
> Table", "Reference"}`; every other `type` falls back to `_DEFAULT_NODE_COLOR`. The spec
> deliberately allows producer-defined types (consumers MUST tolerate unknown types), so
> non-BigQuery bundles — in our case 444 `Moqui Entity` concepts from an ERP data model —
> render as an undifferentiated gray graph.
>
> Suggestion: assign stable colors to unknown types (hash of the type string into a qualitative
> palette), keeping the explicit entries as overrides. Happy to PR this if wanted.

## 3. (Later, once GrowERP's OKF code is pushed) ecosystem entry

Issue #166 proposes a "Community & ecosystem tools" README section — once the GrowERP
exporter/consumer is public, a one-line entry (Moqui/GrowERP ERP entity-model producer +
MCP consumer) is a genuine ecosystem data point. Do not post before the code is public.

## 4. Possible PR: non-BigQuery Source example

`reference-agent enrich` supports only `--source bq`. A minimal `Source` implementation
example over a REST/entity-model backend (patterned on our exporter) would demonstrate the
source plugin surface. Larger effort — only if upstream shows interest via #2/#1.
