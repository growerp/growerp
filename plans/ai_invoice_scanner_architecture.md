# AI Invoice Scanner & Templating Architecture

## Objective
Provide a way in Flutter to scan a physical invoice, use its visual design as a template, and inject new data to print customized invoices matching that design.

## The Architecture Pipeline

### 1. Image Capture
*   **Action:** Capture an image of the physical invoice.
*   **Tools/Packages:** Use `image_picker` for basic camera access, or specialized packages like `cunning_document_scanner` to detect document edges, crop, and deskew the image.

### 2. AI Template Generation (Layout Extraction)
*   **Action:** Reverse-engineer the visual design into a semantic, reusable format (HTML/CSS).
*   **Tools/Packages:** Use a multimodal LLM like Google Gemini (via the `google_generative_ai` package) or GPT-4o.
*   **Prompt Example:** *"Analyze the layout and design of this invoice. Write HTML and CSS that replicates this exact visual layout. Replace the specific text values with Mustache template variables like `{{invoice_number}}`, `{{company_logo}}`, `{{items}}`, and `{{total}}`. Return ONLY the HTML code."*
*   **Result:** A blank HTML string that perfectly mimics the original invoice design. This is saved to the database as a template.

### 3. Dynamic Data Injection (Templating)
*   **Action:** Merge the saved HTML template with new invoice data.
*   **Tools/Packages:** Use a templating engine package like `mustache_template`.
*   **Process:** Pass the new data (e.g., new line items, new customer details) into the Mustache engine to replace the `{{variables}}` in the HTML string with real data.

### 4. PDF Conversion and Printing
*   **Action:** Convert the finalized HTML into a printable document.
*   **Tools/Packages:** 
    *   `flutter_html_to_pdf` (converts HTML string to a PDF file).
    *   `printing` (sends the PDF to a physical printer or native print preview).

---

## Technical Decision: Why HTML instead of raw PDF?

Generating raw PDF strings via AI is not viable for the following reasons:

### 1. The "Byte-Offset" Problem (File Corruption)
PDF is a compiled binary format, not a simple markup language. It relies on a Cross-Reference Table (XREF) that maps the exact byte offset of every element. If you replace a template variable like `{{invoice_number}}` (17 bytes) with `123` (3 bytes), the entire document shifts. The XREF table becomes invalid, instantly corrupting the PDF file.

### 2. Absolute Positioning vs. Flow Layout
PDF uses absolute X/Y coordinates for presentation. It has no concept of "flowing text" or "tables." If an invoice template was generated from an image with 3 line items, adding 50 line items dynamically would require manually calculating the math for new Y coordinates and handling page breaks. HTML (`<table>`) automatically handles flowing content, expanding heights, and pagination when converted to PDF.

### 3. AI Capabilities
Large Language Models excel at generating semantic markup like HTML/CSS because they are trained on billions of web pages. They hallucinate and fail almost constantly when asked to generate raw PDF syntax due to the strict mathematical constraints and uncompressed byte stream requirements.

### Conclusion
*   **HTML/CSS** serves as the human-readable and AI-readable "source code."
*   **PDF** serves as the compiled "binary executable."
*   The HTML-to-PDF library acts as the compiler, bridging the gap between flexible layouts and static printable files.
