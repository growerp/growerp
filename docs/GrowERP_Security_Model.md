# GrowERP Security Model

How GrowERP decides who may see a screen and who may call the API behind it.

The short version: **the menu is the security policy**. An organization decides which user
groups see which screens, and the REST API is authorized from that same decision. Hiding a
screen also blocks its endpoints.

- **Part 1** is for organization administrators using Organization → Security.
- **Part 2** is for developers changing screens, endpoints or verticals.

Related: [Dynamic Menu System and Widget Repository](./Dynamic_Menu_System_And_Widget_Repository.md),
[Registration and Login Specification](./Registration_Login_Specification.md).

---

# Part 1 — For organization administrators

## The Security screen

**Organization → Security** lists every screen in the application, one row per screen with its
tabs indented underneath, and one column per user group:

| | Admin | Employee | Other |
|---|---|---|---|
| Orders | write | write | none |
| Accounting | write | view | none |

Each cell is one of:

- **none** — the group does not see the screen, and cannot call its endpoints.
- **view** — the group sees the screen and can read its data.
- **write** — the group can also change data through it.

Tap a row to change it. Write always implies view.

## What to know before you change it

**Revoking a screen also blocks its API.** This is the point of the design: a group that
cannot see the Orders screen also cannot call the order endpoints, whether from another app,
a script, or a direct HTTP request. Hiding a menu entry is no longer cosmetic.

**There is no System column.** `GROWERP_M_SYSTEM` is GrowERP support access, not an
organization's to grant. The screen does not offer it and the server rejects it too, so a
column cannot be added by manipulating the request.

**You cannot remove your own Admin access.** The Security screen is itself a screen in the
grid, so revoking Admin would leave nobody able to undo it. The server refuses.

**Your first save takes a private copy of the menu.** GrowERP ships a default menu for each
application. The first time you change access, your organization gets its own copy. From then
on your menu is yours: later changes GrowERP makes to the shipped menu no longer reach you
automatically. This is what keeps one organization's decisions out of another's.

**Outside users start with almost nothing.** Customers, suppliers and leads (the *Other*
group) see only your company details, read-only. A screen reaches them only when you name
their group explicitly — so a new screen is never exposed to them by accident.

---

# Part 2 — For developers

## Two axes, deliberately separate

A user carries two independent things. Confusing them is the mistake this model exists to
prevent.

| | Field | Values | Means |
|---|---|---|---|
| **Role** | `Party` role type | `OrgInternal`, `Customer`, `Supplier`, `Lead` | The *business* relationship. Grants nothing. |
| **User group** | `UserGroupMember` | `GROWERP_M_SYSTEM`, `_ADMIN`, `_EMPLOYEE`, `_OTHER` | The *security* axis. The only thing that grants access. |

The four group ids are mirrored in Dart by
[`UserGroup`](../flutter/packages/growerp_models/lib/src/models/user_group_model.dart). A user
has exactly one `GROWERP_M_*` group.

`GROWERP_M_CUSTOMER`, `GROWERP_M_LEAD` and `GROWERP_M_SUPPLIER` are **deprecated**. They were
derived from the role, which made the business relationship act as a permission. Outside users
are now `GROWERP_M_OTHER` and keep their role. `growerp.100.SecurityServices100.migrate#UserGroups`
moves any remaining members.

## Menu access

Two fields on `growerp.menu.MenuItem` decide access:

| Field | Meaning |
|---|---|
| `userGroupsJson` | JSON array of groups that may **see** the screen |
| `updateGroupsJson` | JSON array of groups that may **write** through it |

The defaults are where mistakes happen:

| Stored | Sees | Writes |
|---|---|---|
| `userGroupsJson` empty | the internal groups (`SYSTEM`, `ADMIN`, `EMPLOYEE`), **never** `OTHER` | |
| `userGroupsJson` set | exactly the groups listed | |
| `updateGroupsJson` absent | | write follows view, except `OTHER` |
| `updateGroupsJson` `[]` | | nobody |
| `updateGroupsJson` set | | exactly the groups listed |

Three consequences worth internalising:

1. **Outside users are default-deny.** A screen added without a group list is invisible to
   `GROWERP_M_OTHER`. The failure mode goes the safe direction.
2. **Internal users are default-write.** Almost every shipped screen names no writers; if
   absent meant "nobody" the whole application would 403 on save.
3. **Absent is not empty.** `updateGroupsJson` absent means "follow view"; `[]` means
   "read-only for everyone". Setting every group to *view* in the grid stores `[]`, and would
   otherwise read straight back as *write*.

`GROWERP_M_SYSTEM` bypasses the filter entirely — most shipped screens name only
`GROWERP_M_ADMIN`, and support staff would otherwise lose the menu.

These rules are implemented three times and **must agree**:

| Where | What |
|---|---|
| [`MenuServices100.xml`](../backend/service/growerp/100/MenuServices100.xml) `hasAccess` | filters the menu that is served |
| [`SecurityServices100.xml`](../backend/service/growerp/100/SecurityServices100.xml) `allows` / `allowsWrite` | authorizes REST calls |
| [`security_list_styled_data.dart`](../flutter/packages/growerp_core/lib/src/domains/security/widgets/security_list_styled_data.dart) `accessOf` | renders the grid |

If they disagree, the grid lies about what it just saved.

## Three configuration tiers

`get#MenuConfiguration` resolves in this order:

1. **the user's own copy** — `userId` set, `ownerPartyId` set (personal customisation)
2. **the organization's copy** — `userId` null, `ownerPartyId` set (what Security edits)
3. **the shipped seed** — `userId` null, `ownerPartyId` null

`ensure#OwnerMenuConfiguration` creates tier 2 by cloning the seed on the first security edit.
The seed lookup filters `ownerPartyId is null` — without that condition it would happily serve
another tenant's configuration once tier 2 rows exist.

Filtering happens **server-side**, for children as well as top-level items: a screen hidden
from a group must not remain reachable as a tab. The Flutter check in `display_menu_option.dart`
is defence in depth against a stale cached config, not the control.

## Which APIs are open

Moqui serves several REST APIs. Only two of them are open to the applications:

| API | Open to | Enforced by |
|---|---|---|
| `/rest/s1/growerp` | every signed-in user, per organization | `GROWERP_REST_GUARDED` → `check#RestAccess`, below |
| `/rest/s1/pop` | storefront, partly anonymous | `require-authentication` per resource in `pop-rest-store/service/pop.rest.xml` |
| `/rest/s1/moqui` (Tools) | nobody | `AUTHZT_DENY / AUTHZA_ALL` for `ALL_USERS` in [`GrowerpRestApiDisableData.xml`](../backend/data/GrowerpRestApiDisableData.xml) |
| `/rest/s1/mantle` (Mantle USL) | nobody | same |
| `/rest/e1`, `/rest/m1`, `/rest/v1` (Entity, Entity Master) | nobody | same, on the `rest.xml` transitions |

The reason is tenancy. GrowERP separates organizations with `Party.ownerPartyId`, applied by
the `growerp` services. The Entity, Mantle and Tools APIs know nothing about it: they read and
write straight across every organization in the database. An endpoint there cannot be made
safe by authorizing it, so it is closed instead.

The one exception is [`GrowerpRestApiEnableData.xml`](../backend/data/GrowerpRestApiEnableData.xml),
which re-grants `AUTHZT_ALWAYS / AUTHZA_VIEW` — read only — to the framework `ADMIN` group, for
support debugging through the moqui MCP server's `moqui_rest_call`. `ADMIN` here is the Moqui
group holding `SystemSupport`, not `GROWERP_M_ADMIN`: a company administrator is not in it.

**Schema documents follow the same split.** `/rest/entity.swagger`, `/rest/master.swagger`,
`/rest/entity.json`, `/rest/master.json`, `/rest/service.swagger` and `/rest/service.raml`
describe the data model and every endpoint, so they are not public either. `rest.xml` is
declared `require-authentication="false"`, which means its transitions are pushed with
authorization disabled and no `ArtifactAuthz` row is consulted; the check therefore lives in
`RestSchemaUtil.schemaAccessDenied` in the moqui fork. It requires a login, then allows the
APIs named in the `rest_schema_open_apis` System property (`growerp,pop`, set by
[`backend/MoquiConf.xml`](../backend/MoquiConf.xml)) and limits every other document to the
`ADMIN` group. Adding an API that applications may use means adding it there as well.

## REST authorization

### Resolving a request to a domain

```
GET /rest/s1/growerp/100/FinDoc
        │
        │  ArtifactGroup regex patterns          GrowerpRestDomainGroupData.xml
        ▼
   GROWERP_ORDER
        │
        │  does any screen this group can see drive GROWERP_ORDER?
        │      MenuItem.artifactGroupId  (override)
        │      └─ else WidgetDomain[widgetName]    GrowerpRestDomainData.xml
        ▼
   view / write / nothing
```

A screen's domain comes from `MenuItem.artifactGroupId` if set, otherwise from
`growerp.menu.WidgetDomain` keyed on `widgetName`. The map is keyed on the widget rather than
the menu item because the same widget is the same screen in every one of the application
menus: one row secures it everywhere, and a new vertical reusing it inherits the mapping.

### `check#RestAccess`

Wired in through `ArtifactAuthz.authzServiceName` on the `GROWERP_REST_GUARDED` group, so it
runs for every REST leaf:

1. `GROWERP_M_SYSTEM` → allow (superuser).
2. No `GROWERP_M_*` group → deny.
3. Path in no domain → **deny**. An endpoint nobody mapped is unreachable, which is noisy but
   safe; the audit trail below finds it.
4. Domain is `GROWERP_BASE` → allow. **Required**: session, menu and messaging must work
   before menu-derived access can be computed, or login deadlocks against the very
   configuration it needs to read.
5. Otherwise consult the owner's domain access: `AUTHZA_VIEW` needs *see*, anything else needs
   *write*.

**Which menus count for an organization.** A REST call carries no `appId`, so the app set is
the `appId`s of the organization's own configurations plus the one it registered for
(`TenantSetup.applicationId`, `AppAdmin` → `admin`). Without this scoping every shipped menu
would count and a hotel tenant would inherit manufacturing access.

> Not `growerp.PartyApplication`: it is a per-user "seen once" marker written by the client,
> not an entitlement. Authorizing against it would deny a user who simply has not opened the
> app yet.

### Why a service and not rows

`ArtifactAuthz`, `ArtifactGroup` and `UserGroup` have **no `ownerPartyId`**. Moqui's authz
model predates multi-tenancy-by-owner, which in GrowERP is an application convention on
`Party.ownerPartyId`. Static per-tenant grants are therefore impossible: there is no field to
scope them by, they would grow as `owners × domains × groups`, and they are
`use="configuration"` — loaded per user and scanned linearly on every request.
`authzServiceName` moves the decision to request time, where the owner is known.

Four framework mechanics constrain the design; changing any of them breaks enforcement
silently:

- Authz is enforced **only at the leaf** path segment. Intermediate segments never check.
- An inheritable grant on an **ancestor** short-circuits the leaf entirely. This is why the
  guard's pattern is `/growerp/100/.*`, which matches no ancestor, and why the blanket
  `/growerp` grants for `GROWERP_M_ADMIN`, `_EMPLOYEE` and `_OTHER` had to be removed — their
  member was plain `/growerp`, so while they existed nothing below was ever checked.
- `inheritAuthz` controls the **other direction**: whether authorizing an artifact carries
  through to what it *calls*. The guard needs `Y`, because a REST path immediately invokes a
  service, which is itself an artifact. With `N` the endpoint is allowed and then the service
  call is checked separately, finds no `AT_SERVICE` grant, and fails with
  *"not authorized for View on Service growerp.100…"*. The two directions are easy to
  conflate: the pattern keeps the check at the leaf, `inheritAuthz` lets the result flow
  downward.
- `artifactAuthzId` is the **sole primary key**. Two rows sharing an id silently overwrite one
  another.

### Caching

`check#RestAccess` runs on every REST leaf, so both lookups are cached
([`MoquiConf.xml`](../backend/MoquiConf.xml)): `growerp.security.restDomain`,
`growerp.security.restPatterns`, `growerp.security.ownerDomain`.

[`Menu.eecas.xml`](../backend/entity/Menu.eecas.xml) clears them on any create, update or
delete of `MenuItem` or `MenuConfiguration`. It is hung on the **entities**, not on the eleven
menu services, so a new write path cannot forget to invalidate.

## Privilege-escalation guards

**`resolve#GrantableUserGroup`** — `create#User` and `update#User` take `userGroupId` straight
from the client, so it is never trusted: non-admins cannot change a group at all, and admins
cannot grant `GROWERP_M_SYSTEM`.

**`trustGroup`** — registration and tenant creation legitimately choose the group server-side,
and pass this flag to say so. It is an **explicit parameter on purpose**: an earlier attempt
inferred "this is registration" from the absence of a logged-in user, which is wrong, because
an anonymous REST request can run on a pooled request thread that still carries the previous
request's user. Absence of a session proves nothing.

**`set#MenuItemGroups`** — rejects `GROWERP_M_SYSTEM` from a non-system caller, requires the
caller to be an admin, enforces write-implies-view, and refuses to remove `GROWERP_M_ADMIN`
(the grid is itself a screen, so that would be a one-way door).

**`register#WebsiteUser`** is `anonymous-all` and used to pass the caller's `userGroupId`
straight into `create#UserGroupMember` — an anonymous caller could make themselves an admin.
The group is now fixed to `GROWERP_M_OTHER` and the business relationship comes from a `role`
parameter.

## Known gap

The `User` REST resource serves both "my profile" and "list users" on one path, so
`GROWERP_COMPANY` view access lets an outside user list the users of **their own tenant**. It
is owner-scoped and read-only, and writes remain guarded, but splitting it properly needs a
REST path change.

---

# Developer checklist

## Adding a screen

1. Register the widget in the `WidgetRegistry` (see the
   [menu system doc](./Dynamic_Menu_System_And_Widget_Repository.md)).
2. Add a row to [`GrowerpRestDomainData.xml`](../backend/data/GrowerpRestDomainData.xml)
   mapping `widgetName` → domain. **Without it the screen's endpoints are unreachable.**
3. Add the menu item. Set `userGroupsJson` only if it is not for all internal groups; set
   `updateGroupsJson` only to restrict writing further.

## Adding a REST resource

Add it to a domain pattern in
[`GrowerpRestDomainGroupData.xml`](../backend/data/GrowerpRestDomainGroupData.xml). A resource
in no domain is denied to everyone except system users.

Prove nothing is orphaned:

```bash
# every non-anonymous resource must match exactly one domain pattern
grep '^        <resource name=' backend/service/growerp.rest.xml | grep -v anonymous

# every widget used by a menu must have a WidgetDomain row
grep -ho 'widgetName="[^"]*"' backend/data/*.xml | sort -u
```

## Adding a vertical

Its menu widgets need `WidgetDomain` rows. Widgets reused from other apps already have theirs
— that is the point of keying on the widget.

## Deploying to an existing database

Two traps, both silent.

**The load must include `seed-initial`.** `GrowerpSecurityData.xml` — which holds the guard and
every `ArtifactAuthz` — is `type="seed-initial"`. A plain `load types=seed` **skips it** and
says so only in the log:

```
Skipping file [.../GrowerpSecurityData.xml], is a type to skip (seed-initial)
```

The domain files are `type="seed"` and load normally, so the symptom is confusing: domains
update, the guard does not, and authorization behaves as though your change never happened.

```bash
java -jar moqui.war load types=seed,seed-initial no-run-es
```

Always confirm the row actually changed rather than trusting the load ran:

```
moqui_rest_call path=e1/moqui.security.ArtifactGroupMember \
  queryParameters={artifactGroupId:'GROWERP_REST_GUARDED'}
```

**A reload never deletes.** Rows removed from the seed file stay in an upgraded database, so
the old blanket grants would silently leave the whole API open. Run
`growerp.100.SecurityServices100.migrate#RestAuthz` (system user only), or start from
`cleandb`. Verify no `GROWERPAPI_AUTHZ_ADMIN`, `_EMPL` or `_OTHER` rows remain.

## Debugging a 403

Every denial is recorded. Walk the application as the affected group, then:

```
moqui_rest_call path=e1/moqui.security.ArtifactAuthzFailure \
  queryParameters={pageSize:'50', orderByField:'-failureDate'}
```

An empty result after a full walkthrough is the real coverage test. Common causes, in order of
likelihood:

| Symptom | Cause |
|---|---|
| One screen's endpoints fail | widget missing from `WidgetDomain` |
| One endpoint fails everywhere | REST resource in no domain pattern |
| A whole group is blocked | no visible screen drives that domain for them |
| Correct in the grid, wrong over REST | stale cache — check the menu EECA fired |
| Nothing is ever denied | a blanket `/growerp` grant still exists; run `migrate#RestAuthz` |
