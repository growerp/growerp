# Owner data backup and transfer

An owner (tenant) can download all of its data as one zip file, as a backup or to move
the company to another GrowERP system. System support can upload such a file on any
system that has the seed data and the GROWERP owner loaded: it becomes a **new** owner,
next to the owners already there.

## Using it

Every tenant, in every app: System Setup → **Backup** tab, or the Backup part of the
System Setup page in apps without tabs (`SystemSetupBackupView`):

- **Download company data**: any administrator (`GROWERP_M_ADMIN`). It runs in the
  background, the tab shows the progress and opens the file in the browser when it is
  done; **Save the file** opens it again for 24 hours.
- **Upload company data**: only shown to, and only allowed for, system support
  (`GROWERP_M_SYSTEM`). The result shows the id of the new owner.

System support, in the support app → **Owners**: the download icon of a row downloads that
owner, the upload button loads a file as a new owner (`OwnerDataDialog`).

The file holds everything, including the mail server password, AI keys and the users'
password hashes. Keep it safe.

Users keep their passwords. An upload is refused (nothing is written) when a user name or
email address of the file is already used on the system, so restoring a copy onto the
system it came from needs those users renamed first. Data of the owner that also belongs
to another owner (for example the GROWERP subscription invoices of a tenant) is left out
of the download and listed in `manifest.json` under `leftOut`.

## File format

```
manifest.json                 formatVersion, ownerPartyId, exportDate, counts, files, leftOut
entities/<entityName>.xml     standard Moqui data (entity-facade-xml), one file per entity
files/<path>                  the dbresource:// files the records refer to
```

The entity files are written by Moqui's `EntityValue.writeXmlText`, the same format as the
seed data. They can be read, diffed or checked with the Moqui tools; loading one as-is
only makes sense on an empty database, because the ids are those of the source system.

## Size

Both ways stream, so the size of a company is limited by disk, not memory or requests:

- **Download**: the zip is written to `runtime/ownerData/<id>.zip`; the link
  `/ownerData/download?t=<token>` (screen `ownerData.xml`, valid 24 hours) streams it, the
  browser saves it on every platform.
- **Upload**: the app reads the file as a stream and sends it in 8 MB multipart chunks
  (proxies limit a request to 20 MB), appended on disk. A new upload gives up one not
  finished.
- **Server**: the download keeps only keys and references in memory and writes the records
  straight into the zip; the upload reads the zip from disk (SAX), keeps only the old → new
  ids, and loads 5000 records at a time. Moqui records every entity operation of a call for
  its hot spot report, that history is dropped per batch.
- Measured on the test database (H2): 101,000 records download in 8 s, upload in 14 s, the
  heap grows about 25 MB per 100,000 records loaded (one transaction).
- Files are removed a week after they were made.

## How it works

The work is done by [`backend/service/OwnerDataTransfer.groovy`](../backend/service/OwnerDataTransfer.groovy),
called by [`OwnerDataServices100.xml`](../backend/service/growerp/100/OwnerDataServices100.xml)
(background jobs in `growerp.general.OwnerDataTransfer`, REST resource `OwnerData`).

**Which entities.** [`backend/ci/owner_data_entities.py`](../backend/ci/owner_data_entities.py)
scans the GrowERP programs: the services and Groovy files of the GrowERP components, the
mantle and moqui services they call and the ECAs those trigger. Every entity read or written
on the way is classified in [`backend/service/ownerDataEntities.json`](../backend/service/ownerDataEntities.json):

| list | meaning |
|---|---|
| `tenant` | can hold owner data: has `ownerPartyId` or a relationship chain to `Party` |
| `global` | seed and configuration shared by all owners, present on every system |
| `excluded` | logs, history, sessions, jobs: not transferred |
| `pullIn` | taken only when an owner record points at it (own GL accounts, wiki spaces) |
| `ownerKeyed` | keyed by the owner id without a relationship (`EmailServer`) |
| `implicitRelations` | id fields without a relationship that point at a record by name (`*PartyId`, `*UserId`, `<pk>Id`) |

A new entity used by GrowERP fails the CI step `owner_data_entities.py --check`. Rerun the
script without `--check` and review where it landed; moving an entity to another list by
hand is kept on the next run. `fieldOverrides` (entity → field → entity) adds references the
scan cannot see.

Background jobs: `growerp.general.OwnerDataTransfer` (status UPLOADING, QUEUED, RUNNING,
DONE, FAILED). REST: `POST OwnerData/Export` (start a download, support may pass
`ownerPartyId`), `GET OwnerData` (progress, `downloadPath` when done), `POST OwnerData/Import`
(multipart chunk: `file`, `fileName`, `offset`, `last`, `ownerDataTransferId` after the first).

**Download.** Starting from the owner, its parties and every row with its `ownerPartyId`,
each row of a tenant entity that points at an already selected row is taken, until nothing
new is found. Records only reached through a reference (ContactMech, GlAccount) come along
when a selected row points at them. Rows that also point at another owner's data are left
out, and with them the rows depending on them.

**Upload.** Every record gets a new id (a sequenced one, or the new owner id where the old
id held the owner id: `AGENT_<owner>`, `<owner>-<sequence>`, `emailServerId`). Every
reference is rewritten to the new ids; a reference to a record not in the file is kept when
that record exists on the system (seed data), else cleared. dbresource top directories that
exist already get a new name (`C<company>` follows the new company id). The result is
loaded by Moqui's `EntityDataLoader`, parents first (dummy foreign keys only where references go round) and without entity ECAs, in one
transaction: when it fails nothing is left behind.

## Known limits

- Ids written inside text (FTL, website content, JSON fields) are not rewritten.
- Entities in `excluded` are not transferred, among them `ServiceJob`: agent schedules
  have to be set again.
- Binary entity fields go through the Moqui XML format as the seed data does.
- An upload is one database transaction: a very large company needs a database that can
  hold that (Postgres can).

## Tests

[`OwnerDataServicesTests.groovy`](../backend/src/test/groovy/OwnerDataServicesTests.groovy)
downloads a tenant with demo data, checks the files with Moqui's data check, uploads it as
a new owner and compares the record counts per entity, the ids, the files and a login.
