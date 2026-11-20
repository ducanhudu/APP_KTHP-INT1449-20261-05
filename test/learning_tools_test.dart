import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_theme.dart';
import 'package:flutter_quiz_app/learning_tools.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AI panel dùng lời giải gốc khi chưa cấu hình AI_API_URL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final question = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    ).first;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLearningTool(
                context,
                LearningTool.assistant,
                question: question,
                language: QuestionLanguage.english,
              ),
              child: const Text('Mở AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở AI'));
    await tester.pumpAndSettle();

    // Giữ nguyên ngữ cảnh câu hỏi.
    expect(find.text(question.en), findsOneWidget);
    // Không cấu hình URL nên phải rơi về lời giải gốc, có nhãn nói rõ nguồn.
    expect(find.text('Giải thích AI'), findsOneWidget);
    expect(find.text('Lời giải gốc'), findsOneWidget);
    expect(find.text(question.explanationEn), findsOneWidget);
    // Nút đọc lời giải và hỏi lại đều có mặt và bấm được.
    expect(
      find.widgetWithText(OutlinedButton, 'Nghe lời giải'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Hỏi lại'), findsOneWidget);
    // Không còn ô nhập / nút gửi của bản giữ chỗ cũ.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Gửi câu hỏi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI panel đóng được và không để lại màn hình', (tester) async {
    final question = decodeQuestions(
      File('assets/flutter_quiz_300.json').readAsStringSync(),
    ).first;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLearningTool(
                context,
                LearningTool.assistant,
                question: question,
                language: QuestionLanguage.vietnamese,
              ),
              child: const Text('Mở AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở AI'));
    await tester.pumpAndSettle();
    expect(find.text('Giải thích AI'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Giải thích AI'), findsNothing);
    expect(find.text('Mở AI'), findsOneWidget);
  });

  testWidgets(
    'Camera preview can be closed and capture actions stay inactive',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showLearningTool(context, LearningTool.camera),
                child: const Text('Mở camera'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở camera'));
      await tester.pumpAndSettle();
      expect(find.text('Camera học tập'), findsOneWidget);
      expect(find.text('Sắp có'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Quét mã QR'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Mở camera'), findsOneWidget);
      expect(find.text('Camera học tập'), findsNothing);
    },
  );
}
