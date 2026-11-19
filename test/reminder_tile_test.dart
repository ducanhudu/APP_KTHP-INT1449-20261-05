import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/reminder_service.dart';
import 'package:flutter_quiz_app/reminder_tile.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_reminder_service.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    FakeReminderService service,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReminderTile(service: service)),
      ),
    );
    await tester.pump();
  }

  testWidgets('Mặc định tắt: hiện lời mời bật nhắc ôn', (tester) async {
    await pumpTile(tester, FakeReminderService());
    expect(find.text('Nhắc ôn hằng ngày'), findsOneWidget);
    expect(find.text('Nhận thông báo khi có thẻ đến hạn'), findsOneWidget);
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
  });

  testWidgets('Bật nhắc ôn: gọi service và hiện giờ nhắc', (tester) async {
    final service = FakeReminderService();
    await pumpTile(tester, service);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pump();

    expect(service.enableCalls, 1);
    expect(service.lastHour, 20);
    expect(find.text('Nhắc lúc 20:00 mỗi ngày'), findsOneWidget);
    expect(find.text('Đã bật nhắc ôn lúc 20:00 mỗi ngày.'), findsOneWidget);
  });

  testWidgets('Chưa có quyền thông báo: công tắc vẫn tắt và có hướng dẫn', (
    tester,
  ) async {
    final service = FakeReminderService(
      result: ReminderResult.permissionDenied,
    );
    await pumpTile(tester, service);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pump();

    expect(service.enableCalls, 1);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.textContaining('Chưa có quyền thông báo'), findsOneWidget);
  });

  testWidgets('Đang bật thì tắt được và gọi disable', (tester) async {
    final service = FakeReminderService(enabled: true);
    await pumpTile(tester, service);
    expect(find.text('Nhắc lúc 20:00 mỗi ngày'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.pump();

    expect(service.disableCalls, 1);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(find.text('Đã tắt nhắc ôn hằng ngày.'), findsOneWidget);
  });
}
