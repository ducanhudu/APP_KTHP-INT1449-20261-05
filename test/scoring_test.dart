import 'dart:math';

import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kiểm thử chấm điểm (Scoring): đúng, sai và bỏ trống', () {
    // Tạo 3 câu hỏi mẫu độc lập để kiểm thử logic chấm điểm
    final q1 = Question.fromJson({
      'id': 1,
      'topic': 1,
      'level': 'easy',
      'question_vi': 'Câu hỏi 1',
      'question_en': 'Question 1',
      'explanation_vi': 'Giải thích 1',
      'explanation_en': 'Explanation 1',
      'correct_answer': 'A',
      'options': [
        {'id': 'A', 'vi': 'Đáp án A', 'en': 'Option A'},
        {'id': 'B', 'vi': 'Đáp án B', 'en': 'Option B'},
        {'id': 'C', 'vi': 'Đáp án C', 'en': 'Option C'},
        {'id': 'D', 'vi': 'Đáp án D', 'en': 'Option D'},
      ],
    });

    final q2 = Question.fromJson({
      'id': 2,
      'topic': 1,
      'level': 'medium',
      'question_vi': 'Câu hỏi 2',
      'question_en': 'Question 2',
      'explanation_vi': 'Giải thích 2',
      'explanation_en': 'Explanation 2',
      'correct_answer': 'B',
      'options': [
        {'id': 'A', 'vi': 'Đáp án A', 'en': 'Option A'},
        {'id': 'B', 'vi': 'Đáp án B', 'en': 'Option B'},
        {'id': 'C', 'vi': 'Đáp án C', 'en': 'Option C'},
        {'id': 'D', 'vi': 'Đáp án D', 'en': 'Option D'},
      ],
    });

    final q3 = Question.fromJson({
      'id': 3,
      'topic': 2,
      'level': 'hard',
      'question_vi': 'Câu hỏi 3',
      'question_en': 'Question 3',
      'explanation_vi': 'Giải thích 3',
      'explanation_en': 'Explanation 3',
      'correct_answer': 'C',
      'options': [
        {'id': 'A', 'vi': 'Đáp án A', 'en': 'Option A'},
        {'id': 'B', 'vi': 'Đáp án B', 'en': 'Option B'},
        {'id': 'C', 'vi': 'Đáp án C', 'en': 'Option C'},
        {'id': 'D', 'vi': 'Đáp án D', 'en': 'Option D'},
      ],
    });

    final items = [
      QuizItem(q1, Random(1)),
      QuizItem(q2, Random(2)),
      QuizItem(q3, Random(3)),
    ];

    test('Chấm bài gồm 1 câu đúng, 1 câu sai và 1 câu bỏ trống', () {
      // Giả lập câu trả lời của người dùng:
      // - Câu 1: chọn 'A' (Đúng)
      // - Câu 2: chọn 'C' (Sai, đáp án đúng là 'B')
      // - Câu 3: không chọn (Bỏ trống)
      final userAnswers = <int, String>{
        1: 'A',
        2: 'C',
        // 3 không có trong map -> bỏ trống
      };

      final result = QuizResult(items, userAnswers);

      // Kiểm tra điểm tổng thể
      expect(result.score.total, 3, reason: 'Tổng số câu phải là 3');
      expect(result.score.correct, 1, reason: 'Phải có đúng 1 câu đúng');
      expect(result.score.wrong, 1, reason: 'Phải có đúng 1 câu sai');
      expect(result.score.skipped, 1, reason: 'Phải có đúng 1 câu bỏ trống');
      expect(result.score.percent, 33, reason: '1/3 câu đúng làm tròn là 33%');

      // Danh sách câu sai để làm lại / tạo flashcard
      final wrongList = result.wrongQuestions.toList();
      expect(wrongList, hasLength(1));
      expect(wrongList.first.id, 2, reason: 'Chỉ câu 2 là câu trả lời sai');

      // Kiểm tra thống kê theo topic
      final byTopic = result.byTopic;
      // Topic 1 có 2 câu (1 đúng, 1 sai)
      expect(byTopic[1]!.total, 2);
      expect(byTopic[1]!.correct, 1);
      expect(byTopic[1]!.wrong, 1);
      expect(byTopic[1]!.skipped, 0);

      // Topic 2 có 1 câu (0 đúng, 0 sai, 1 bỏ trống)
      expect(byTopic[2]!.total, 1);
      expect(byTopic[2]!.correct, 0);
      expect(byTopic[2]!.wrong, 0);
      expect(byTopic[2]!.skipped, 1);
    });

    test('Nộp bài trắng: tất cả các câu đều là bỏ trống', () {
      final result = QuizResult(items, {});

      expect(result.score.correct, 0);
      expect(result.score.wrong, 0);
      expect(result.score.skipped, 3);
      expect(result.score.percent, 0);
      expect(result.wrongQuestions, isEmpty);
    });

    test('Nộp bài đúng 100%', () {
      final result = QuizResult(items, {1: 'A', 2: 'B', 3: 'C'});

      expect(result.score.correct, 3);
      expect(result.score.wrong, 0);
      expect(result.score.skipped, 0);
      expect(result.score.percent, 100);
      expect(result.wrongQuestions, isEmpty);
    });

    test('Tổng số liệu theo khối (byTopic) luôn khớp chính xác với điểm tổng của lượt vừa nộp', () {
      final result = QuizResult(items, {1: 'A', 2: 'C'});

      final byTopic = result.byTopic;
      final sumCorrect = byTopic.values.fold(0, (sum, s) => sum + s.correct);
      final sumWrong = byTopic.values.fold(0, (sum, s) => sum + s.wrong);
      final sumSkipped = byTopic.values.fold(0, (sum, s) => sum + s.skipped);
      final sumTotal = byTopic.values.fold(0, (sum, s) => sum + s.total);

      expect(sumCorrect, result.score.correct, reason: 'Tổng đúng phải khớp');
      expect(sumWrong, result.score.wrong, reason: 'Tổng sai phải khớp');
      expect(
        sumSkipped,
        result.score.skipped,
        reason: 'Tổng bỏ trống phải khớp',
      );
      expect(sumTotal, result.score.total, reason: 'Tổng số câu phải khớp');
      expect(sumTotal, items.length);
    });

    test('Quy ước khối K01..K20 đồng nhất và đúng 20 chủ đề kiến thức', () {
      expect(topicNames, hasLength(20));
      for (var i = 1; i <= 20; i++) {
        final label = topicLabel(i);
        final expectedPrefix = 'K${i.toString().padLeft(2, '0')} · ';
        expect(label.startsWith(expectedPrefix), isTrue);
        expect(label, '$expectedPrefix${topicNames[i - 1]}');
      }
      expect(topicLabel(1), 'K01 · Dart căn bản');
      expect(topicLabel(20), 'K20 · Flutter và AI');
    });
  });
}
