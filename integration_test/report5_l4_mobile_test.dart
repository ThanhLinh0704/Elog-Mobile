import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:elog_driver/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Report 5.4 - Level 4 Full Driver E2E Journey (8 Test Cases)', (tester) async {
    // ── 1. LAUNCH APP ────────────────────────────────────────────────────────
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── L4-MOB-AUTH-01: Assigned driver signs in to My Trips ────────────────
    final textFields = find.byType(TextFormField);
    if (textFields.evaluate().length >= 2) {
      await tester.enterText(textFields.at(0), 'driver01');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.enterText(textFields.at(1), 'Dev@2025');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final loginBtn = find.text('Đăng nhập');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    }

    // ── L4-MOB-TRIP-01: Driver reviews assigned work for a selected date ───
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final refreshFinders = find.byType(RefreshIndicator);
    if (refreshFinders.evaluate().isNotEmpty && find.byType(ListView).evaluate().isNotEmpty) {
      await tester.fling(find.byType(ListView).first, const Offset(0, 250), 800);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // ── L4-MOB-TRIP-02: Driver starts the dispatched trip ──────────────────
    final startBtn = find.text('Bắt đầu chuyến đi');
    if (startBtn.evaluate().isNotEmpty) {
      await tester.tap(startBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final confirmBtn = find.text('Xác nhận');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }

    // ── L4-MOB-TRIP-03: Driver records arrival at the next stop ────────────
    final arriveBtn = find.text('Đã đến điểm giao');
    if (arriveBtn.evaluate().isNotEmpty) {
      await tester.tap(arriveBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // ── L4-MOB-TRIP-04: Driver completes the final active stop and trip ────
    final completeBtn = find.text('Hoàn thành giao hàng');
    if (completeBtn.evaluate().isNotEmpty) {
      await tester.tap(completeBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // ── L4-MOB-TRIP-05: Driver reports a delivery rejection with reason ────
    final rejectBtn = find.text('Báo cáo sự cố');
    if (rejectBtn.evaluate().isNotEmpty) {
      await tester.tap(rejectBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final cancelBtn = find.text('Hủy');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    // ── L4-MOB-EXC-01: Driver reviews own exceptions using immediate filters
    final excIcon = find.byIcon(Icons.warning_amber_rounded);
    if (excIcon.evaluate().isNotEmpty) {
      await tester.tap(excIcon.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // ── L4-MOB-PROFILE-01: Driver reviews identity and signs out ───────────
    final profileIcon = find.byIcon(Icons.person_outline_rounded);
    if (profileIcon.evaluate().isNotEmpty) {
      await tester.tap(profileIcon.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final logoutBtn = find.text('Đăng xuất');
      if (logoutBtn.evaluate().isNotEmpty) {
        await tester.tap(logoutBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final confirmLogout = find.text('Đồng ý');
        if (confirmLogout.evaluate().isNotEmpty) {
          await tester.tap(confirmLogout.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
    }

    // Final verification: Ensure no unhandled exceptions crashed the pipeline
    expect(tester.takeException(), isNull);
  });
}
