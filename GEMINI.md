# Scan Invoice

This document outlines the process for creating an invoice by scanning an image file.

## Workflow

1.  **Scan Invoice Image:**
    Scan the invoice image from a file.

2.  **Validation Checks:**
    a. Check if the recipient is your company.
    b. Check if the supplier exists in your system.
    c. Check if the products exist in your system.

3.  **Information Extraction:**
    Retrieve all other information from the invoice.

4.  **Approval:**
    Present the retrieved information with the validation checks and ask for approval.

5.  **Processing (If Approved):**
    a. If the supplier does not exist, create the supplier.
    b. If any products do not exist, create the products.
    c. Enter the invoice.
        - If an error occurs, show an error message.
        - If successful, show a "message entry successful" message.
    d. Exit.

6.  **Corrections (If Not Approved):**
    a. Ask for corrections.
    b. If the corrections are approved, go back to step 5.

## Company Roles
In this system, companies can be assigned different roles. The role determines how the company interacts with the system and what actions can be performed. The possible roles are:

*   **Supplier:** A vendor providing goods or services.
*   **Customer:** A client purchasing goods or services.
*   **Lead:** A potential customer or supplier.
*   **Company:** The company itself.
