import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/app_theme.dart';
import 'package:flutter_quiz_app/learning_tools.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AI preview keeps question context and send controls inactive', (
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
    expect(find.text(question.en), findsOneWidget);
    expect(find.text('Sắp có'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    final send = find.widgetWithText(FilledButton, 'Gửi câu hỏi');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    expect(tester.takeException(), isNull);
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
