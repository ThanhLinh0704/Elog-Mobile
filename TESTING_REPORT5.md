# Report 5 mobile E2E handoff

## What is ready

- `integration_test/report5_l4_mobile_test.dart` implements `L4-MOB-AUTH-01` against the real Android-emulator backend address `http://10.0.2.2:8080`.
- The test signs in with the existing driver fixture through the visible login form, then asserts arrival at My Trips. It does not stub or intercept network traffic.
- `integration_test` is declared under `dev_dependencies` in `pubspec.yaml`.
- Latest executed result: Pass on `emulator-5554` with Flutter 3.44.9.

## Run from Android Studio or terminal

1. Start the Spring Boot backend on port `8080`.
2. Start an Android emulator and select it as the deployment target.
3. Run `integration_test/report5_l4_mobile_test.dart`, or use:

   ```powershell
   D:\Elog\AuditToolchains\flutter\bin\flutter.bat test -d <emulator-id> integration_test\report5_l4_mobile_test.dart
   ```

The test needs the driver fixture `driver01` / `Dev@2025` to remain valid. The other seven mobile L4 Test IDs still need their own UI journeys.
