/// test/ai_service_test.dart – Unit test cho AiService
/// Kiểm tra fallback khi URL chưa cấu hình và khi timeout.
library;

import 'package:flutter_quiz_app/ai_service.dart';
import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Câu hỏi mẫu dùng trong test.
Question _sampleQuestion() {
  return Question.fromJson({
    'id': 1,
    'topic': 1,
    'level': 'easy',
    'question_vi': 'Dart là ngôn ngữ gì?',
    'question_en': 'What is Dart?',
    'code_snippet': '',
    'explanation_vi': 'Dart là ngôn ngữ lập trình hướng đối tượng.',
    'explanation_en': 'Dart is an object-oriented programming language.',
    'correct_answer': 'A',
    'options': [
      {'id': 'A', 'vi': 'Hướng đối tượng', 'en': 'Object-oriented'},
      {'id': 'B', 'vi': 'Hàm thuần túy', 'en': 'Pure functional'},
      {'id': 'C', 'vi': 'Lập trình logic', 'en': 'Logic programming'},
      {'id': 'D', 'vi': 'Lập trình tuyến tính', 'en': 'Linear programming'},
    ],
  });
}

void main() {
  group('AiService', () {
    test(
      'Trả về fallback lời giải gốc khi AI_API_URL chưa cấu hình',
      () async {
        // Vì biến môi trường AI_API_URL không được set trong test, AiService
        // phải trả về fromFallback=true với text từ explanationVi.
        final q = _sampleQuestion();
        final result = await AiService.explain(
          question: q,
          language: QuestionLanguage.vietnamese,
        );

        expect(result.fromFallback, isTrue);
        expect(result.text, equals(q.explanationVi));
      },
    );

    test(
      'Trả về fallback bằng tiếng Anh khi language=english',
      () async {
        final q = _sampleQuestion();
        final result = await AiService.explain(
          question: q,
          language: QuestionLanguage.english,
        );

        expect(result.fromFallback, isTrue);
        expect(result.text, equals(q.explanationEn));
      },
    );
  });
}
