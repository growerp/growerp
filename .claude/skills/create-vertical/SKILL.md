---
name: create-vertical
description: Create a new GrowERP vertical app or extend an existing one from building blocks. Use when the user says "create a new vertical", "new GrowERP app", "add a block to <app>", or wants to scaffold/extend an end-user app.
---

# Create or extend a GrowERP vertical

Follow [docs/AI_Assisted_Vertical_Creation_Guide.md](../../../docs/AI_Assisted_Vertical_Creation_Guide.md)
end to end. It contains the interview script, the extend-vs-new decision, the exact
commands with expected output, the contract checklist, and troubleshooting.

Quick reference:

1. **Interview** the user to pick building blocks (baseline: `user_company` +
   `catalog` + `order_accounting`).
2. **Decide** extend an existing app (Recipe A — cheaper, no new package) vs create a
   new one (Recipe B). Default to extend if an existing `appId` fits.
3. **New vertical**:
   ```bash
   cd flutter/packages/growerp
   dart run bin/growerp.dart createApp <name> -b <blocks> -d /data/growerp
   ```
   (or `createApp --describe "<business>"` with `GOOGLE_API_KEY` set).
4. **Verify** the contract checklist: applicationId triple, every `MenuItem.widgetName`
   registered, package in both `flutter/pubspec.yaml` lists, `dart analyze` clean, seed
   loads (`GET rest/e1/growerp.menu.MenuConfiguration/<UPPER>_DEFAULT`).

The block registry (verified widget names, provider signatures, delegates, default menu
rows) is `flutter/packages/growerp/lib/src/growerp/app_blocks.dart` — never invent a
`widgetName`; a wrong one fails silently until the menu item is tapped.
