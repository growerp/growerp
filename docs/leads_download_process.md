# Leads Download Process

This section describes the process of downloading leads from the backend (Moqui) to the frontend (Flutter).

## Backend (Moqui)

The backend uses the `ExportServices100.xml` service definitions to handle the export process.

-   **File:** [`moqui/runtime/component/growerp/service/growerp/100/ImportExportServices100.xml`](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/service/growerp/100/ImportExportServices100.xml)

The relevant services are:

-   `export#Users`: Exports user data to a CSV file.
-   `export#CompanyUsers`: Exports company/user relationships to a CSV file.

The `growerp.rest.xml` file defines the REST endpoints for these services.

-   **File:** [`moqui/runtime/component/growerp/service/growerp.rest.xml`](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/service/growerp.rest.xml)

The relevant resource is `Export`, which defines the `GET` methods for the export services.

## Frontend (Flutter)

The frontend uses the `CompanyUserList` widget to initiate the download.

-   **File:** [`flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_list.dart`](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_list.dart)

This widget allows the user to:

1.  **Click a download button:** The user clicks a button to initiate the download process.
2.  **Call the backend REST endpoint:** The frontend calls the appropriate backend REST endpoint to trigger the export service.
3.  **Receive the CSV file:** The backend returns the CSV file as a response.
4.  **Save the file:** The frontend saves the CSV file to the device.

## Data Flow

1.  The user clicks the download button in the `CompanyUserList` widget.
2.  The frontend calls the backend REST endpoint.
3.  The backend REST endpoint calls the appropriate export service in `ImportExportServices100.xml`.
4.  The export service retrieves the data and generates a CSV file.
5.  The backend returns the CSV file to the frontend.
6.  The frontend saves the CSV file to the device.


