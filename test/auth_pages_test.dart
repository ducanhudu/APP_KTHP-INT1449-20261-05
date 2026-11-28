import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/auth_controller.dart';
import 'package:flutter_quiz_app/auth_pages.dart';
import 'package:flutter_quiz_app/auth_service.dart';
import 'package:flutter_quiz_app/profile_page.dart';
import 'package:flutter_test/flutter_test.dart';

AuthController demoController() =>
    AuthController(DemoAuthService(store: MemoryAuthStore()));

/// Dùng khung hình cao để các nút bấm không bị đẩy ra ngoài màn hình trong test.
void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> pumpLogin(WidgetTester tester, AuthController controller) async {
  useTallViewport(tester);
  await tester.pumpWidget(MaterialApp(home: LoginPage(controller: controller)));
}

void main() {
  testWidgets('Trang đăng nhập hiện đủ trường và điều hướng đăng ký', (
    tester,
  ) async {
    await pumpLogin(tester, demoController());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Chưa có tài khoản?'), findsOneWidget);
    expect(find.textContaining('demo@example.com'), findsNothing);
    expect(find.textContaining('Demo123!'), findsNothing);
  });

  testWidgets('Đăng nhập trống hiển thị lỗi cho các trường bắt buộc', (
    tester,
  ) async {
    await pumpLogin(tester, demoController());
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('Nút hiện/ẩn mật khẩu đổi trạng thái ẩn hiện', (tester) async {
    await pumpLogin(tester, demoController());
    final passwordField = find.byType(TextFormField).at(1);
    EditableText editable() => tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(editable().obscureText, isTrue);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });

  testWidgets('Đăng nhập demo thành công chuyển sang trang hồ sơ', (
    tester,
  ) async {
    await pumpLogin(tester, demoController());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'demo@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Demo123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin thành viên'), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@example.com'), findsOneWidget);
  });

  testWidgets('Trang đăng ký kiểm tra mật khẩu khớp nhau', (tester) async {
    final controller = demoController();
    useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: RegisterPage(controller: controller)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
    await tester.enterText(find.byType(TextFormField).at(1), 'an@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'MatKhau123!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Khac123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
  });

  testWidgets('Trang hồ sơ hiện thông tin và đăng xuất về trang đăng nhập', (
    tester,
  ) async {
    useTallViewport(tester);
    final controller = demoController();
    await controller.signIn(email: 'demo@example.com', password: 'Demo123!');
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông tin thành viên'), findsOneWidget);
    expect(find.text('demo@example.com'), findsOneWidget);
    expect(find.text('Ngày tham gia'), findsOneWidget);
    expect(find.text('Tài khoản mẫu'), findsOneWidget);

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsWidgets);
  });

  testWidgets('Trang hồ sơ chuyển về đăng nhập khi chưa đăng nhập', (
    tester,
  ) async {
    useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(controller: demoController())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsWidgets);
  });

  testWidgets('Nút Google báo chưa cấu hình thay vì giả mạo thành công', (
    tester,
  ) async {
    await pumpLogin(tester, demoController());
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được cấu hình'), findsOneWidget);
  });
}
