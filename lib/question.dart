import 'dart:convert';
import 'dart:math';

enum QuestionLanguage {
  vietnamese('Tiếng Việt'),
  english('English'),
  bilingual('Việt + English');

  const QuestionLanguage(this.label);
  final String label;

  String display(String vietnamese, String english) => switch (this) {
    QuestionLanguage.vietnamese => vietnamese,
    QuestionLanguage.english => english,
    QuestionLanguage.bilingual =>
      vietnamese == english ? vietnamese : '$vietnamese\n\n$english',
  };
}

const topicNames = [
  'Dart căn bản',
  'Công cụ và môi trường',
  'Widget và vòng đời',
  'Bố cục giao diện',
  'Material và Cupertino',
  'Thiết kế thích ứng',
  'Tương tác và biểu mẫu',
  'Hình ảnh và tài nguyên',
  'Điều hướng',
  'Hoạt ảnh',
  'Trợ năng',
  'Quản lý trạng thái',
  'Dữ liệu và bất đồng bộ',
  'Kiến trúc ứng dụng',
  'Package và plugin',
  'Kiểm thử',
  'Hiệu năng',
  'Flutter đa nền tảng',
  'Cấu hình và bảo mật',
  'Flutter và AI',
];

/// Tên khối bằng tiếng Anh, cùng thứ tự với [topicNames].
const topicNamesEn = [
  'Dart basics',
  'Tools and environment',
  'Widgets and lifecycle',
  'Layout',
  'Material and Cupertino',
  'Responsive design',
  'Interaction and forms',
  'Images and assets',
  'Navigation',
  'Animation',
  'Accessibility',
  'State management',
  'Data and async',
  'App architecture',
  'Packages and plugins',
  'Testing',
  'Performance',
  'Cross-platform Flutter',
  'Configuration and security',
  'Flutter and AI',
];

/// Tên khối theo ngôn ngữ nhãn giao diện. Chế độ song ngữ dùng tiếng Việt,
/// giống cách [AppStrings] chọn bộ nhãn.
String topicName(int topic, QuestionLanguage language) {
  final names = language == QuestionLanguage.english
      ? topicNamesEn
      : topicNames;
  if (topic < 1 || topic > names.length) {
    return 'K${topic.toString().padLeft(2, '0')}';
  }
  return names[topic - 1];
}

String topicLabel(int topic, QuestionLanguage language) {
  final code = 'K${topic.toString().padLeft(2, '0')}';
  final names = language == QuestionLanguage.english
      ? topicNamesEn
      : topicNames;
  if (topic < 1 || topic > names.length) return code;
  return '$code · ${names[topic - 1]}';
}

class Choice {
  const Choice(this.id, this.vi, this.en);
  final String id;
  final String vi;
  final String en;
}

class Question {
  Question.fromJson(Map<String, Object?> json)
    : id = json['id'] as int,
      referenceCode = json['code'] as String? ?? '',
      topic = json['topic'] as int,
      level = json['level'] as String,
      vi = json['question_vi'] as String,
      en = json['question_en'] as String,
      code = json['code_snippet'] as String? ?? '',
      explanationVi = json['explanation_vi'] as String,
      explanationEn = json['explanation_en'] as String,
      correctId = json['correct_answer'] as String,
      choices = List.unmodifiable(
        (json['options'] as List).cast<Map<String, Object?>>().map(
          (option) => Choice(
            option['id'] as String,
            option['vi'] as String,
            option['en'] as String,
          ),
        ),
      );

  final int id;
  final String referenceCode;
  final int topic;
  final String level;
  final String vi;
  final String en;
  final String code;
  final String explanationVi;
  final String explanationEn;
  final String correctId;
  final List<Choice> choices;
}

List<Question> decodeQuestions(String source) {
  final questions = (jsonDecode(source) as List)
      .cast<Map<String, Object?>>()
      .map(Question.fromJson)
      .toList();
  final ids = <int>{};
  if (questions.length != 300 ||
      questions.any((question) {
        final choiceIds = question.choices.map((choice) => choice.id).toSet();
        return !ids.add(question.id) ||
            question.topic < 1 ||
            question.topic > topicNames.length ||
            question.choices.length != 4 ||
            choiceIds.length != 4 ||
            [
              question.vi,
              question.en,
              question.explanationVi,
              question.explanationEn,
              question.level,
              for (final choice in question.choices) ...[
                choice.id,
                choice.vi,
                choice.en,
              ],
            ].any((text) => text.trim().isEmpty) ||
            !choiceIds.contains(question.correctId);
      })) {
    throw const FormatException('Ngân hàng câu hỏi không hợp lệ.');
  }
  return List.unmodifiable(questions);
}

class QuizItem {
  QuizItem(this.question, Random random)
    : choices = List.unmodifiable([...question.choices]..shuffle(random));

  final Question question;
  final List<Choice> choices;
}

List<QuizItem> createQuiz(
  Iterable<Question> pool,
  int count, {
  Random? random,
}) {
  final rng = random ?? Random();
  final questions = pool.toList()..shuffle(rng);
  RangeError.checkValueInInterval(count, 1, questions.length, 'count');
  return List.unmodifiable(
    questions.take(count).map((question) => QuizItem(question, rng)),
  );
}

class Score {
  const Score({this.correct = 0, this.wrong = 0, this.skipped = 0});

  final int correct;
  final int wrong;
  final int skipped;
  int get total => correct + wrong + skipped;
  int get percent => total == 0 ? 0 : (100 * correct / total).round();

  Score add(Question question, String? answer) => Score(
    correct: correct + (answer == question.correctId ? 1 : 0),
    wrong: wrong + (answer != null && answer != question.correctId ? 1 : 0),
    skipped: skipped + (answer == null ? 1 : 0),
  );
}

class QuizResult {
  QuizResult(
    List<QuizItem> items,
    Map<int, String> answers, {
    this.expired = false,
  }) : items = List.unmodifiable(items),
       answers = Map.unmodifiable(answers);

  final List<QuizItem> items;
  final Map<int, String> answers;
  final bool expired;

  Iterable<Question> get wrongQuestions => items
      .map((item) => item.question)
      .where(
        (question) =>
            answers.containsKey(question.id) &&
            answers[question.id] != question.correctId,
      );

  Score get score => items.fold(
    const Score(),
    (total, item) => total.add(item.question, answers[item.question.id]),
  );

  Map<int, Score> get byTopic {
    final totals = <int, Score>{};
    for (final item in items) {
      final question = item.question;
      totals.update(
        question.topic,
        (score) => score.add(question, answers[question.id]),
        ifAbsent: () => const Score().add(question, answers[question.id]),
      );
    }
    final topics = totals.keys.toList()..sort();
    return {for (final topic in topics) topic: totals[topic]!};
  }
}

class QuestionCard {
  const QuestionCard({
    required this.id,
    required this.questionId,
    this.note = '',
  });

  final String id;
  final int questionId;
  final String note;

  Question? resolve(Iterable<Question> bank) {
    for (final question in bank) {
      if (question.id == questionId) return question;
    }
    return null;
  }
}

QuizResult createSampleResult(List<Question> bank) {
  if (bank.length < 3) {
    throw ArgumentError('Ngân hàng câu hỏi cần ít nhất 3 câu.');
  }
  final sampleQuestions = bank.take(3).toList();
  final items = [
    QuizItem(sampleQuestions[0], Random(1)),
    QuizItem(sampleQuestions[1], Random(1)),
    QuizItem(sampleQuestions[2], Random(1)),
  ];

  final q1 = sampleQuestions[0];
  final q2 = sampleQuestions[1];
  final wrongChoice = q2.choices.firstWhere((c) => c.id != q2.correctId);

  final answers = <int, String>{
    q1.id: q1.correctId, // 1 câu đúng
    q2.id: wrongChoice.id, // 1 câu sai
    // q3.id không có trong map -> 1 câu bỏ trống
  };

  return QuizResult(items, answers);
}
