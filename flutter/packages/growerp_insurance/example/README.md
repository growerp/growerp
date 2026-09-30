# growerp_insurance_example

Example app and integration test of the growerp_insurance building block.
It registers companies as `AppInsurance`, so the backend grants them the
insurance screens of the `INSURANCE_DEFAULT` menu.

```bash
flutter test integration_test --dart-define=BACKEND_PORT=8080
```
