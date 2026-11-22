import 'dart:io';

import 'package:flutter_quiz_app/question.dart';
import 'package:flutter_quiz_app/question_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bank = decodeQuestions(
    File('assets/flutter_quiz_300.json').readAsStringSync(),
  );
  test(
    'OCR Vietnamese without accents and line breaks finds the source question',
    () {
      final q = bank[80];
      final query = normalizeStudyText(q.vi).replaceAll(' ', '\n');
      expect(searchStudyQuestions(bank, query).first.question.id, q.id);
    },
  );
  test('English photo with answer options ranks its question first', () {
    final q = bank[212];
    final query = '${q.en}\n${q.choices.map((c) => c.en).join('\n')}';
    expect(searchStudyQuestions(bank, query).first.question.id, q.id);
  });
  test('Empty, stop words and unrelated text do not invent a match', () {
    for (final text in ['', '  ', 'the and trong cua', 'zzqxwvv pppqqzz']) {
      expect(searchStudyQuestions(bank, text), isEmpty);
    }
    expect(
      searchStudyQuestions(bank, 'flutter', limit: 2).length,
      lessThanOrEqualTo(2),
    );
  });
  test('QR supports app question URI and exact reference code', () {
    expect(questionFromStudyQr(bank, 'flutterlab://question/81')?.id, 81);
    expect(questionFromStudyQr(bank, bank.first.referenceCode)?.id, 1);
  });
  test('QR never accepts external URLs, extra query, invalid IDs or fabricated bank codes', () {
    for (final code in [
      'https://example.com/1',
      'javascript:alert(1)',
      'flutterlab://question/999',
      'flutterlab://question/1?prompt=hello',
      'flutterlab://question/1#extra',
      'flutterlab://other/1',
      'flutterlab://user@question/1',
      'K20-999',
      '1',
    ]) {
      expect(questionFromStudyQr(bank, code), isNull, reason: code);
    }
  });
}
