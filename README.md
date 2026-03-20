# IC Lot Tracking Sync (ICLTS)

**Publisher:** DynamITVectorK  
**Extension ID:** d9b4e1f2-3a5c-4d7e-8f9a-0b1c2d3e4f50  
**BC Platform:** 24.0 · Runtime 13.0 · Target: Cloud (SaaS)  
**Object range:** 50300 – 50399

---

## Overview

The native Business Central Intercompany (IC) module transfers sales and purchase documents between IC partner companies but **does not propagate item-tracking data** (lot numbers, serial numbers, or item variant codes).  This means that when Company A ships a lot-tracked item to its IC partner Company B, the resulting purchase order in Company B arrives with no lot or serial information.  Finance and warehouse teams must re-enter tracking data manually, which is error-prone and time-consuming.

**IC Lot Tracking Sync** closes this gap by automatically:

1. Capturing lot/serial tracking lines from an outbound IC sales document and writing them to a per-company buffer table (`ICLTS Tracking Buffer`).
2. Applying those buffered tracking lines to the matching inbound IC purchase order as BC `Reservation Entry` records with `Reservation Status::Surplus`, ready for receiving.

The extension is built entirely on **event subscribers** hooked to public `OnAfter*` events in the standard BC `IC Outbox Mgt.` and `IC Inbox Mgt.` codeunits.  No standard BC object is extended or modified.

---

## Modules

| Module | Field | Description |
|--------|-------|-------------|
| **MOD-01** | `MOD-01 Enabled` | Propagates lot numbers and serial numbers on IC documents. Enabled by default on first access. |
| **MOD-02** | `MOD-02 Enabled` | Reserved for future item-variant-code propagation. |

Each module is independently enabled or disabled per company on the **IC Lot Tracking Sync Setup** page (Page 50300).

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Standard BC Events                                              │
│  IC Outbox Mgt. :: OnAfterSendICDocument                        │
│  IC Outbox Mgt. :: OnAfterCreateICOutboxSalesDocFromSalesHeader  │
│  IC Inbox Mgt.  :: OnAfterCreatePurchDocFromICInboxDoc          │
│  IC Inbox Mgt.  :: OnAfterICInboxSalesDocToPurchOrder           │
└────────────────────────┬─────────────────────────────────────────┘
                         │ EventSubscriber (no OnBefore* events)
             ┌───────────┴───────────┐
             │ ICLTS Outbound        │  ICLTS Inbound
             │ Subscriber (50304)    │  Subscriber (50305)
             └───────────┬───────────┘
                         │ module guard → ICLTSSetupMgt.IsModuleEnabled
                         │ exception guard → [TryFunction] + Gap Log
                         ▼
             ┌─────────────────────────────┐
             │  ICLTS Tracking Engine      │  (Codeunit 50303)
             │  CaptureOutboundTracking()  │
             │  ApplyInboundTracking()     │
             └──────────────┬──────────────┘
                            │ all ICLTS table I/O
                            ▼
             ┌─────────────────────────────┐
             │  ICLTS Repository           │  (Codeunit 50301)
             │  InsertTrackingBuffer()     │
             │  GetPendingTrackingLines()  │
             │  MarkTrackingLinesProcessed │
             │  InsertGapLogEntry()        │
             └──────────────┬──────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                  ▼
  Table 50300         Table 50301        Table 50302
  ICLTS Setup     ICLTS Tracking      ICLTS Gap Log
                     Buffer              Entry
```

### Codeunits

| ID | Name | Access | Responsibility |
|----|------|--------|----------------|
| 50300 | ICLTS Setup Mgt. | Public | Safe singleton accessor for the setup record |
| 50301 | ICLTS Repository | Public | **Only** codeunit permitted to read/write ICLTS tables |
| 50302 | ICLTS Gap Log Mgt. | Public | Exception-safe wrapper for gap log insertion |
| 50303 | ICLTS Tracking Engine | Public | Business logic: capture outbound & apply inbound tracking |
| 50304 | ICLTS Outbound Subscriber | Internal | Event subscriber for IC outbox events |
| 50305 | ICLTS Inbound Subscriber | Internal | Event subscriber for IC inbox events |
| 50306 | ICLTS OAuth Mgt. | Public | IsolatedStorage-based OAuth2 credential management |

### Tables

| ID | Name | Description |
|----|------|-------------|
| 50300 | ICLTS Setup | Per-company configuration — one record per company |
| 50301 | ICLTS Tracking Buffer | Lot/serial lines buffered from outbound, consumed on inbound |
| 50302 | ICLTS Gap Log Entry | Errors and warnings written by the extension |

### Pages

| ID | Name | Type | Source |
|----|------|------|--------|
| 50300 | ICLTS Setup | Card | ICLTS Setup |
| 50301 | ICLTS Gap Log Entries | List | ICLTS Gap Log Entry |
| 50302 | ICLTS Tracking Buffer | List | ICLTS Tracking Buffer |

### Enums

| ID | Name | Values |
|----|------|--------|
| 50300 | ICLTS Module Code | MOD-01, MOD-02 |
| 50301 | ICLTS Log Entry Type | Success, Warning, Error |

---

## Setup

1. Search for **IC Lot Tracking Sync Setup** in the Business Central Role Centre.
2. Enable **Item Tracking Sync Enabled** (MOD-01).
3. Set **Log Retention (Days)** to the desired number of days before processed buffer lines and gap log entries are purged (default: 30).
4. If the IC partner company resides in a different Azure AD tenant, enter the partner tenant's BC API endpoint in **API Base URL** and configure OAuth2 credentials via `ICLTS OAuth Mgt.` (Codeunit 50306).

> **Note:** Both IC partner companies must have the extension installed and MOD-01 enabled for end-to-end propagation to work.

---

## Architecture rules enforced

| Rule | Status |
|------|--------|
| A-01 — No standard BC object modified directly | ✅ Only EventSubscriber and infrastructure codeunits; no TableExtension/PageExtension on standard objects |
| A-02 — EventSubscribers use OnAfter\* events only | ✅ All four subscribers hook OnAfter\* events |
| A-03 — Module guard on every subscriber | ✅ Every subscriber method begins with `ICLTSSetupMgt.IsModuleEnabled(...)` |
| A-04 — Top-level exception catch in every subscriber | ✅ `[TryFunction]` delegates catch all exceptions; errors are written to the Gap Log and never re-raised |
| A-05 — No direct ICLTS table access outside the Repository | ✅ Subscribers use `ICLTSSetupMgt`; Engine calls `ICLTSRepository.GetPendingTrackingLines()` which performs `FindSet()` internally |
| A-06 — No secrets in table fields | ✅ OAuth2 client secret, tenant ID, client ID, and token URL are stored in `IsolatedStorage` with `DataScope::Company` |
| A-07 — XMLDoc on all public methods | ✅ Every public procedure in every codeunit carries `/// <summary>` documentation |

---

## Maintenance

### Purging old data

Use the actions on the monitoring pages or call the repository methods directly from a Job Queue entry:

```al
// Delete processed tracking buffer lines older than the retention period
ICLTSRepository.DeleteProcessedTrackingLines(ICLTSSetup."Log Retention Days");

// Delete gap log entries older than the retention period
ICLTSRepository.DeleteOldGapLogEntries(ICLTSSetup."Log Retention Days");
```

### Monitoring

Open **ICLTS Gap Log Entries** (Page 50301) to review errors and warnings.  
Open **ICLTS Tracking Buffer** (Page 50302) to inspect pending or processed tracking lines.

---

## Contributing

Please read [AL-Go contribution guidelines](https://github.com/microsoft/AL-Go/blob/main/Scenarios/Contribute.md) before submitting a pull request.

