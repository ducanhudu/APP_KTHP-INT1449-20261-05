import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_theme.dart';
import 'package:flutter_quiz_app/main.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Question makeLongQuestion(int id) {
    return Question.fromJson({
      'id': id,
      'topic': 4,
      'level': 'understand',
      'question_vi': 'Công thức tạo hiệu ứng thị sai (parallax) khi cuộn trong tài liệu Flutter dùng Flow với một FlowDelegate nhận repaint: scrollable.position. Vì sao chọn cách này?',
      'question_en': 'The parallax scrolling recipe in Flutter documentation uses Flow with a FlowDelegate that listens to repaint: scrollable.position. Why?',
      'explanation_vi': 'FlowDelegate cho phép biến đổi (transform) con ở thời điểm vẽ (paint phase); khi truyền scrollable.position vào repaint, mỗi lần cuộn chỉ cần vẽ lại với ma trận dịch chuyển mới mà không cần gọi setState hay dựng lại cây widget (rebuild). Điều này giúp giữ 60fps ổn định ngay cả khi danh sách dài và có nhiều ảnh lớn.',
      'explanation_en': 'FlowDelegate transforms children during the paint phase without triggering widget rebuilds.',
      'correct_answer': 'B',
      'options': [
        {
          'id': 'A',
          'vi': 'Vì Flow tự tạo một ScrollController riêng để điều khiển tất cả các widget con bên trong Viewport',
          'en': 'Because Flow creates its own ScrollController',
        },
        {
          'id': 'B',
          'vi': 'Để tính lại vị trí ảnh nền ngay ở pha paint khi cuộn mà không phải rebuild lại toàn bộ cây widget',
          'en':
              'To recalculate background position during paint without rebuild',
        },
        {
          'id': 'C',
          'vi': 'Vì Flow tải và giải mã ảnh mạng nhanh hơn nhiều lần so với Image.network thông thường',
          'en': 'Because Flow decodes network images faster',
        },
        {
          'id': 'D',
          'vi': 'Vì Flow là một sliver, nên mới đặt trực tiếp được vào bên trong CustomScrollView cùng các sliver khác',
          'en': 'Because Flow is a sliver',
        },
      ],
    });
  }

  Question makeShortQuestion(int id) {
    return Question.fromJson({
      'id': id,
      'topic': 5,
      'level': 'remember',
      'question_vi': 'Widget nào cung cấp bố cục trang Material cơ bản, với các vị trí dành sẵn cho appBar, body, drawer và floatingActionButton?',
      'question_en': 'Which widget provides the basic Material Design visual layout structure?',
      'explanation_vi': 'Scaffold hiện thực cấu trúc bố cục trực quan cơ bản của Material Design cho một màn hình, với các khe appBar, body, drawer, bottomNavigationBar, floatingActionButton. MaterialApp bao bọc ứng dụng ở cấp cao hơn.',
      'explanation_en': 'Scaffold implements the basic Material Design visual layout structure.',
      'correct_answer': 'B',
      'options': [
        {'id': 'A', 'vi': 'Material', 'en': 'Material'},
        {'id': 'B', 'vi': 'Scaffold', 'en': 'Scaffold'},
        {'id': 'C', 'vi': 'MaterialApp', 'en': 'MaterialApp'},
        {'id': 'D', 'vi': 'Container', 'en': 'Container'},
      ],
    });
  }

  Future<void> pumpQuizAtSize(
    WidgetTester tester, {
    required Size size,
    required List<QuizItem> items,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: QuizPage(
          items: items,
          language: QuestionLanguage.vietnamese,
          timed: false,
          onLanguageChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Kiểm thử responsive màn hình Luyện tập (QuizPage)', () {
    testWidgets(
      'Màn hình hẹp (320x640): đáp án dài tự xuống dòng, không tràn và cuộn đọc hết giải thích',
      (tester) async {
        final qLong = makeLongQuestion(1);
        final qShort = makeShortQuestion(2);
        final items = [QuizItem(qLong, Random(0)), QuizItem(qShort, Random(0))];

        await pumpQuizAtSize(tester, size: const Size(320, 640), items: items);

        expect(tester.takeException(), isNull);

        // Kiểm tra tất cả 4 lựa chọn theo đúng thứ tự hiển thị (cuộn qua từng lựa chọn trên màn hình 320x640)
        // đều giãn đều theo chiều rộng khả dụng (320 - 16*2 = 288) và tự xuống dòng.
        final widths = <double>{};
        for (final choice in items.first.choices) {
          final choiceTextFinder = find.text(choice.vi);
          await tester.scrollUntilVisible(
            choiceTextFinder,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          final tileFinder = find.ancestor(
            of: choiceTextFinder,
            matching: find.byType(QuizOptionTile),
          );
          expect(tileFinder, findsOneWidget);
          final rect = tester.getRect(tileFinder);
          widths.add(rect.width);
          expect(rect.left, greaterThanOrEqualTo(16.0));
          expect(rect.right, lessThanOrEqualTo(304.0));
          // Đáp án dài phải tự xuống dòng nên chiều cao > 1 dòng đơn (~50px).
          expect(rect.height, greaterThan(56.0));
        }
        expect(widths, hasLength(1));
        expect(widths.single, closeTo(288.0, 0.5));

        // Cuộn lên lại để chọn đáp án sai -> hiện thẻ giải thích "Cần xem lại".
        final wrongChoice = items.first.choices.firstWhere(
          (c) => c.id != qLong.correctId,
        );
        final wrongChoiceFinder = find.text(wrongChoice.vi);
        await tester.scrollUntilVisible(
          wrongChoiceFinder,
          -100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(wrongChoiceFinder);
        await tester.pumpAndSettle();

        // Cuộn xuống để thấy tiêu đề và toàn bộ nội dung thẻ giải thích.
        final verdictFinder = find.text('Cần xem lại');
        await tester.scrollUntilVisible(
          verdictFinder,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(verdictFinder, findsOneWidget);

        // Cuộn xuống hết nội dung để đọc toàn bộ giải thích.
        final explanationFinder = find.textContaining('60fps ổn định');
        await tester.scrollUntilVisible(
          explanationFinder,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final explanationRect = tester.getRect(explanationFinder);
        final submitRect = tester.getRect(find.text('Nộp bài'));
        expect(
          explanationRect.bottom,
          lessThanOrEqualTo(submitRect.top),
          reason:
              'Nội dung giải thích phải nằm phía trên thanh điều hướng dưới',
        );

        // Chuyển sang câu 2 và chọn đáp án.
        await tester.tap(find.byTooltip('Câu tiếp theo'));
        await tester.pumpAndSettle();
        expect(find.text('Câu 2/2 · Đã chọn 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Màn hình điện thoại chuẩn (390x844): đáp án ngắn thẳng hàng đồng nhất, không bị thu nhỏ giữa màn hình',
      (tester) async {
        final qShort = makeShortQuestion(1);
        final items = [QuizItem(qShort, Random(0))];

        await pumpQuizAtSize(tester, size: const Size(390, 844), items: items);

        final optionTiles = find.byType(QuizOptionTile);
        expect(optionTiles, findsNWidgets(4));

        // 390 - 20*2 = 350 cho cả 4 đáp án ngắn.
        for (var i = 0; i < 4; i++) {
          final rect = tester.getRect(optionTiles.at(i));
          expect(rect.width, closeTo(350.0, 0.5));
          expect(rect.left, closeTo(20.0, 0.5));
        }

        // Chọn đáp án đúng ('Scaffold') -> hiện "Chính xác" và giải thích đầy đủ.
        await tester.tap(find.text('Scaffold'));
        await tester.pumpAndSettle();
        expect(find.text('Chính xác'), findsOneWidget);
        expect(find.textContaining('MaterialApp bao bọc'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Màn hình tablet/desktop (1024x768): nội dung căn giữa với chiều rộng tối đa 720px',
      (tester) async {
        final items = [QuizItem(makeLongQuestion(1), Random(0))];

        await pumpQuizAtSize(tester, size: const Size(1024, 768), items: items);

        final firstOptionRect = tester.getRect(
          find.byType(QuizOptionTile).first,
        );
        expect(firstOptionRect.width, closeTo(720.0, 0.5));
        expect(firstOptionRect.left, closeTo((1024 - 720) / 2, 0.5));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
