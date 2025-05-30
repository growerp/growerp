# Leads Upload Process

This document describes the process of uploading leads from the frontend (Flutter) to the backend (Moqui).

## Frontend (Flutter)

The frontend uses the `CompanyUserFilesDialog` widget to handle the file upload.

-   **File:** [`flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_files_dialog.dart`](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_files_dialog.dart)

This widget allows the user to:

1.  **Select a CSV file:** The `file_picker` package is used to select a CSV file from the device.
2.  **Read the file contents:** The contents of the CSV file are read as a string.
3.  **Dispatch a `CompanyUserUpload` event:** The file contents are then passed to the `CompanyUserBloc` by dispatching a `CompanyUserUpload` event.

The `CompanyUserList` widget uses the `CompanyUserFilesDialog` when the user is managing leads.

-   **File:** [`flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_list.dart`](https://github.com/growerp/growerp/blob/master/flutter/packages/growerp_user_company/lib/src/company_user/views/company_user_list.dart)

## Backend (Moqui)

The backend uses the `ImportExportServices100.xml` service definitions to handle the import process.

-   **File:** [`moqui/runtime/component/growerp/service/growerp/100/ImportExportServices100.xml`](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/service/growerp/100/ImportExportServices100.xml)

The relevant services are:

-   `import#Users`: Imports user data from the CSV file.
-   `import#CompanyUsers`: Imports company/user relationships from the CSV file.

The `growerp.rest.xml` file defines the REST endpoints for these services.

-   **File:** [`moqui/runtime/component/growerp/service/growerp.rest.xml`](https://github.com/growerp/growerp/blob/master/moqui/runtime/component/growerp/service/growerp.rest.xml)

The relevant resource is `ImportExport`, which defines the `POST` methods for the import services.

## Data Flow

1.  The user selects a CSV file in the `CompanyUserFilesDialog`.
2.  The file contents are read and sent to the `CompanyUserBloc`.
3.  The `CompanyUserBloc` dispatches an action to the backend REST endpoint.
4.  The backend REST endpoint calls the appropriate import service in `ImportExportServices100.xml`.
5.  The import service processes the data and creates/updates the corresponding entities in the database.

