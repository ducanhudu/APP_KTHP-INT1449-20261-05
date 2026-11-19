import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'question.dart';

void main() => runApp(const FlutterLab());

class FlutterLab extends StatelessWidget {
  const FlutterLab({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xff146c59)),
    home: const QuizHome(),
  );
}

class QuizHome extends StatefulWidget {
  const QuizHome({super.key});

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  late final Future<List<Question>> bank = _loadBank();
  QuestionLanguage language = QuestionLanguage.vietnamese;
  int topic = 0;
  int count = 10;

  Future<List<Question>> _loadBank() async => decodeQuestions(
    await rootBundle.loadString('assets/flutter_quiz_300.json'),
  );

  Future<void> _runQuiz(
    List<Question> pool,
    int questionCount, {
    bool exam = false,
  }) async {
    var items = createQuiz(pool, questionCount);
    var timed = exam;
    while (true) {
      if (!mounted) return;
      final result = await Navigator.of(context).push<QuizResult>(
        MaterialPageRoute(
          builder: (_) => QuizPage(
            items: items,
            language: language,
            timed: timed,
            onLanguageChanged: (value) => setState(() => language = value),
          ),
        ),
      );
      if (!mounted || result == null) return;
      final retry = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ResultPage(result: result, language: language),
        ),
      );
      if (retry != true) return;
      final wrong = result.wrongQuestions.toList();
      items = createQuiz(wrong, wrong.length);
      timed = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flutter Lab')),
    body: FutureBuilder(
      future: bank,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Không đọc được ngân hàng câu hỏi.'));
        }
        final questions = snapshot.data;
        if (questions == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final pool = topic == 0
            ? questions
            : questions.where((question) => question.topic == topic).toList();
        final availableCounts = [
          for (final size in [3, 5, 10, 15, 20, 30])
            if (size <= pool.length) size,
        ];
        final practiceCount = availableCounts.contains(count)
            ? count
            : availableCounts.last;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Ôn thi Flutter và Dart',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${questions.length} câu song ngữ · ${topicNames.length} khối kiến thức',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<QuestionLanguage>(
              key: ValueKey(language),
              initialValue: language,
              decoration: const InputDecoration(labelText: 'Ngôn ngữ câu hỏi'),
              items: [
                for (final value in QuestionLanguage.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) => setState(() => language = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: topic,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Khối luyện tập'),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Tất cả các khối'),
                ),
                for (var i = 1; i <= topicNames.length; i++)
                  DropdownMenuItem(value: i, child: Text(topicLabel(i))),
              ],
              onChanged: (value) => setState(() => topic = value!),
            ),
            const SizedBox(height: 16),
            const Text('Số câu luyện tập'),
            Wrap(
              spacing: 8,
              children: [
                for (final size in availableCounts)
                  ChoiceChip(
                    label: Text('$size câu'),
                    selected: practiceCount == size,
                    onSelected: (_) => setState(() => count = size),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _runQuiz(pool, practiceCount),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Bắt đầu luyện tập'),
            ),
            OutlinedButton.icon(
              onPressed: () => _runQuiz(questions, 50, exam: true),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Thi thử · 50 câu · 50 phút'),
            ),
          ],
        );
      },
    ),
  );
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.items,
    required this.language,
    required this.timed,
    required this.onLanguageChanged,
  });

  final List<QuizItem> items;
  final QuestionLanguage language;
  final bool timed;
  final ValueChanged<QuestionLanguage> onLanguageChanged;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final answers = <int, String>{};
  late QuestionLanguage language = widget.language;
  DateTime? deadline;
  Timer? timer;
  int index = 0;
  bool submitted = false;
  int seconds = 50 * 60;

  @override
  void initState() {
    super.initState();
    if (widget.timed) {
      deadline = DateTime.now().add(const Duration(minutes: 50));
      timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    }
  }

  bool _tick() {
    final end = deadline;
    if (end == null || submitted) return submitted;
    final remaining = (end.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil();
    if (remaining <= 0) {
      _submit(expired: true);
      return true;
    }
    if (seconds != remaining) setState(() => seconds = remaining);
    return false;
  }

  void _submit({bool expired = false}) {
    final route = ModalRoute.of(context);
    if (submitted || route == null || !route.isActive) return;
    submitted = true;
    timer?.cancel();
    final navigator = Navigator.of(context);
    navigator.popUntil((candidate) => candidate == route);
    navigator.pop(QuizResult(widget.items, answers, expired: expired));
  }

  void _goTo(int value) {
    if (_tick()) return;
    setState(() => index = value);
  }

  String get clock =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[index];
    final question = item.question;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timed ? 'Thi thử' : 'Luyện tập'),
        actions: [
          if (widget.timed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(clock)),
            ),
          PopupMenuButton<QuestionLanguage>(
            tooltip: 'Đổi ngôn ngữ câu hỏi',
            icon: const Icon(Icons.translate),
            onSelected: (value) {
              if (_tick()) return;
              setState(() => language = value);
              widget.onLanguageChanged(value);
            },
            itemBuilder: (_) => [
              for (final value in QuestionLanguage.values)
                PopupMenuItem(value: value, child: Text(value.label)),
            ],
          ),
        ],
      ),
      body: ListView(
        key: ValueKey(index),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Câu ${index + 1}/${widget.items.length} · Đã chọn ${answers.length}',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: answers.length / widget.items.length),
          const SizedBox(height: 16),
          Text('${topicLabel(question.topic)} · ${question.level}'),
          const SizedBox(height: 8),
          QuestionPrompt(question: question, language: language),
          const SizedBox(height: 16),
          for (final (position, choice) in item.choices.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceChip(
                label: Text(
                  '${String.fromCharCode(65 + position)}. '
                  '${language.display(choice.vi, choice.en)}',
                ),
                selected: answers[question.id] == choice.id,
                onSelected: (selected) {
                  if (_tick()) return;
                  setState(() {
                    if (selected) {
                      answers[question.id] = choice.id;
                    } else {
                      answers.remove(question.id);
                    }
                  });
                },
              ),
            ),
          if (!widget.timed && answers[question.id] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${answers[question.id] == question.correctId ? 'Chính xác' : 'Cần xem lại'}\n'
                  '${language.display(question.explanationVi, question.explanationEn)}',
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Câu trước',
                onPressed: index == 0 ? null : () => _goTo(index - 1),
                icon: const Icon(Icons.navigate_before),
              ),
              FilledButton(
                onPressed: () {
                  if (!_tick()) _submit();
                },
                child: const Text('Nộp bài'),
              ),
              IconButton(
                tooltip: 'Câu tiếp theo',
                onPressed: index == widget.items.length - 1
                    ? null
                    : () => _goTo(index + 1),
                icon: const Icon(Icons.navigate_next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt({
    super.key,
    required this.question,
    required this.language,
  });

  final Question question;
  final QuestionLanguage language;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        language.display(question.vi, question.en),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (question.code.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SelectableText(
            question.code,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
    ],
  );
}

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result, required this.language});

  final QuizResult result;
  final QuestionLanguage language;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final topics = result.byTopic.entries.toList();
    final wrongCount = result.wrongQuestions.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${score.percent}%',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  '${score.correct} đúng · ${score.wrong} sai · ${score.skipped} bỏ trống',
                ),
                if (result.expired) const Text('Hết giờ, bài thi đã được nộp.'),
                if (wrongCount > 0)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Làm lại $wrongCount câu sai'),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Thống kê theo khối',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final entry in topics)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(topicLabel(entry.key)),
                    subtitle: Text(
                      '${entry.value.correct} đúng · ${entry.value.wrong} sai · ${entry.value.skipped} bỏ trống',
                    ),
                    trailing: Text('${entry.value.percent}%'),
                  ),
                const Divider(),
                Text(
                  'Xem lại bài',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            );
          }
          final item = result.items[index - 1];
          final question = item.question;
          final selected = result.answers[question.id];
          final status = switch (selected) {
            null => 'Bỏ trống',
            _ when selected == question.correctId => 'Đúng',
            _ => 'Sai',
          };
          return ExpansionTile(
            title: Text('Câu $index · $status'),
            subtitle: Text(topicLabel(question.topic)),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              QuestionPrompt(question: question, language: language),
              for (final (position, choice) in item.choices.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${String.fromCharCode(65 + position)}. ${language.display(choice.vi, choice.en)}',
                  ),
                  subtitle: choice.id == question.correctId
                      ? Text(
                          choice.id == selected
                              ? 'Đáp án đúng · Bạn đã chọn'
                              : 'Đáp án đúng',
                        )
                      : choice.id == selected
                      ? const Text('Bạn đã chọn')
                      : null,
                ),
              Text(
                language.display(
                  question.explanationVi,
                  question.explanationEn,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
