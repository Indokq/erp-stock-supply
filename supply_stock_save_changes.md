# Supply Stock Save Flow Updates

## Overview
- Enabled the edit screen to persist both header and detail records using the supplied stored procedures.
- Propagated backend metadata (IDs, sequence numbers, unit IDs) through every detail item so saves can target existing rows.
- Aligned the create workflow to preserve that metadata during browse/edit cycles.
- Added a delete pathway from the supply list so an entire header (and its details) can be removed via the new `spInv_StockSupply_Delete` endpoint.

## File Highlights
- `lib/features/supply_stock/models/supply_detail_item.dart`
  - Added optional `itemId`, `seqId`, `unitId`, and `raw` fields plus `copyWith` support so detail rows retain server identifiers.
- `lib/features/supply_stock/create_supply_page.dart`
  - Cloning/initialising detail rows now keeps `size`, `itemId`, `seqId`, `unitId`, and `raw` data.
  - `_DetailItemRow` emits edits via `copyWith`, preserving metadata while users tweak values.
- `lib/features/supply_stock/edit_supply_page.dart`
  - Hydrates additional header state (orders, signatories, templates) and keeps UI controllers in sync.
  - Normalises API payload parsing so detail rows capture sequence numbers, IDs, and raw maps regardless of column naming.
  - Implements `_saveAll` to call `ApiService.saveSupplyHeader`, iterate `saveSupplyDetail`, and surface granular validation/errors.
  - Adds helper utilities for date formatting, numeric parsing, ID resolution, and API response handling.
  - Manages `SAVE` button state via `_isSaving` to prevent duplicate submissions.
  - Provides in-place detail deletion that confirms intent, invokes `deleteSupply` when a persisted row is removed, and prevents header deletes from failing.
- `lib/features/supply_stock/supply_stock_page.dart`
  - Adds delete affordance on each card, confirms intent, and orchestrates record/line removals before refreshing the list.
- `lib/features/shared/services/api_service.dart`
  - Updated `deleteSupply` helper for `spInv_StockSupply_Delete` to match backend signature by removing `@User_Entry` from the call and API.

## Save Flow (Edit Screen)
- `_saveAll` gathers form values, formats the date, validates warehouses, and blocks parallel submissions with `_isSaving`.
- The header payload is sent to `saveSupplyHeader`, mirroring the stored proc signature and defaulting to `'AUTO'` when no number is supplied.
- If the header response returns a new `Supply_ID`, `_extractSupplyIdFromResponse` refreshes local state so detail saves reference the correct ID.
- Detail rows are filtered for non-empty codes and positive quantities, sequence/unit/item IDs are resolved, and each row is saved via `saveSupplyDetail` with per-row error feedback.
- Success feedback pops the screen after all rows persist; failures leave the form open with contextual snackbars.

## Detail Metadata Handling
- `SupplyDetailItem` stores backend identifiers and raw payloads so edit/add flows can round-trip metadata.
- `_mapRow`, `_resolveSeqId`, `_resolveItemId`, and `_resolveUnitId` recover IDs from mixed API schemas, keeping saves resilient even when users edit fields.
- The create workflow mirrors this by cloning items with the new metadata properties and emitting edits via `copyWith`.

## Delete Flow
- The supply list prompts for confirmation, fetches detail sequence IDs, deletes each line via `deleteSupply` (no `userEntry` arg), then clears the header with `Seq_ID = '0'`.
- Success and failure snackbars echo the backend response, and the list refreshes automatically after a successful purge.

## Follow-ups / TODOs
- Run `dart format .` once the Flutter/Dart toolchain is available (touches updated files).
- Execute `flutter test` and a manual save/delete round-trip against the backend to validate the new workflows.

## Verification
- Tests not run; local environment lacks the Flutter/Dart SDK in this workspace.
