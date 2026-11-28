import 'package:flutter/material.dart';
import 'package:flutter_quiz_app/ai_service.dart';
import 'package:flutter_quiz_app/app_strings.dart';
import 'package:flutter_quiz_app/ask_ai_page.dart';
import 'package:flutter_quiz_app/learning_tools.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sends the typed question and displays the AI answer', (
    tester,
  ) async {
    String? sentQuestion;
    QuestionLanguage? sentLanguage;
    await tester.pumpWidget(
      MaterialApp(
        home: AskAiPage(
          language: QuestionLanguage.vietnamese,
          sender: (question, language) async {
            sentQuestion = question;
            sentLanguage = language;
            return const AiResult(
              text: 'Flutter là bộ công cụ giao diện đa nền tảng.',
              fromFallback: false,
            );
          },
        ),
      ),
    );

    expect(find.text('Ví dụ: Flutter là gì?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Flutter là gì?');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Flutter là gì?',
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              AppStrings.vietnamese.aiAskButton,
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text(AppStrings.vietnamese.aiAskButton));
    await tester.pumpAndSettle();

    expect(sentQuestion, 'Flutter là gì?');
    expect(sentLanguage, QuestionLanguage.vietnamese);
    expect(
      find.text('Flutter là bộ công cụ giao diện đa nền tảng.'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.vietnamese.aiAskAnswerTitle), findsOneWidget);
  });

  testWidgets('Shows an actionable error if the AI request fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AskAiPage(
          language: QuestionLanguage.english,
          sender: (_, _) async => null,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'What is Flutter?');
    await tester.pump();
    await tester.tap(find.text(AppStrings.english.aiAskButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.english.aiAskFailed), findsOneWidget);
  });

  testWidgets('Free-question page cannot open without login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLearningTool(
                context,
                LearningTool.askAi,
                language: QuestionLanguage.english,
              ),
              child: const Text('Open locked AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open locked AI'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.english.aiAskPageTitle), findsNothing);
  });

  testWidgets('AI tools cannot open the free-question page before login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLearningTool(
                context,
                LearningTool.askAi,
                language: QuestionLanguage.english,
              ),
              child: const Text('Open locked AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open locked AI'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.english.aiAskPageTitle), findsNothing);
  });

  testWidgets('AI tools entry opens the free-question page after login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLearningTool(
                context,
                LearningTool.askAi,
                language: QuestionLanguage.english,
                isAuthenticated: true,
              ),
              child: const Text('Open open-question AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open open-question AI'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.english.aiAskPageTitle), findsOneWidget);
    expect(find.text(AppStrings.english.aiAskInputLabel), findsOneWidget);
  });
}
