# Plan: Dynamic GenUI Cards & Missing Widget Fallback

## 1. Overview and Objectives
GrowERP is transitioning to a GenUI (Generative UI) architecture where full-screen static forms are replaced by contextual, dynamic widget cards embedded within a human-textual (chat) interface. 

This plan outlines the architecture for handling scenarios where the AI requests a UI widget that does not yet exist in the compiled Flutter app, and how to eventually evolve this into a fully Server-Driven UI (SDUI) system.

## 2. Phase 1: Graceful Fallback & Developer DX (The "Missing Card")
Instead of throwing a red-screen error when an unknown widget is requested by the backend, the Flutter frontend will catch the missing widget and render a helpful fallback.

### Mechanism
1. **Update the Widget Registry:** The factory method mapping string names to Widgets (e.g., `"InventoryStockCard" -> InventoryStockCard()`) will be wrapped in a safety check.
2. **MissingGenUiCard Component:** If the lookup fails, return `MissingGenUiCard(widgetName, payload)`.

### User Interface for `MissingGenUiCard`
* **Warning Banner:** Clearly states the widget is not implemented.
* **Payload Viewer:** A collapsible section showing the JSON data the AI passed. This serves as a specification for what data the new widget needs to support.
* **"Generate Code Prompt" Action:** A button that generates an AI prompt containing the required widget name, payload schema, and context, allowing the developer to easily paste it into an AI assistant to generate the Dart code.

## 3. Phase 2: True Dynamic UI via Server-Driven UI (SDUI)
To enable the AI to generate actual UI layouts on the fly without requiring the developer to write Dart code, compile, and deploy, the system will use Server-Driven UI.

### Mechanism
Since Dart cannot be evaluated directly at runtime in a production Flutter app, the AI will not generate Dart code. Instead, it will generate a **JSON declarative UI tree**.

### Proposed Workflow
1. **The Request:** AI decides it needs an `InventoryStockCard`.
2. **The Miss:** App identifies the card is missing from its local registry.
3. **The SDUI Request:** The app automatically (or via user prompt) asks the AI to generate the UI layout in JSON format for the missing card, passing the data payload.
4. **The Render:** The Flutter app uses an SDUI engine to parse the returned JSON and renders the native widgets dynamically in the chat feed.

### Recommended Technology Stack
Evaluate the following Flutter packages for the SDUI engine:
* **`rfw` (Remote Flutter Widgets):** Official Google/Flutter team package. Secure, performant, uses a custom declarative text format.
* **`mirai`:** Robust JSON-to-Flutter-Widget engine. Excellent support for Material Design components out of the box.
* **`json_dynamic_widget`:** Another strong option for defining widget trees via JSON.

## 4. Potential Use Cases for Dynamic UI in GrowERP
* **One-off Customer Requirements:** Rendering a highly specific shipping calculation card that only applies to one unique edge case.
* **Rapid Prototyping:** Developers can chat with the app to generate new screens and modules instantly in JSON, test the UX, and only write the hardcoded Dart version later if needed for maximum performance.
* **Proactive Dashboards:** "Show me sales for last month" -> AI builds a custom `ChartCard` with the exact metrics requested, dynamically constructed via JSON.

## 5. Next Steps
1. Create the `MissingGenUiCard` widget in `growerp_core`.
2. Update the main GenUI widget registry parser to implement the fallback.
3. Spike/POC integrating an SDUI package (e.g., `rfw` or `mirai`) into the GrowERP chat interface to prove out Phase 2.
