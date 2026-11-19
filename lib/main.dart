import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'card_storage.dart';
import 'learning_tools.dart';
import 'today_overview.dart';
import 'flashcard_page.dart';
import 'question.dart';
import 'question_prompt.dart';
import 'sm2.dart';

export 'question_prompt.dart';

void main() => runApp(const FlutterLab());

class FlutterLab extends StatelessWidget {
  const FlutterLab({super.key, this.storage = const SharedPrefsCardStorage()});

  final CardStorage storage;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Lab',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: QuizHome(storage: storage),
  );
}

class QuizHome extends StatefulWidget {
  const QuizHome({super.key, this.storage = const SharedPrefsCardStorage()});

  final CardStorage storage;

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  late final Future<List<Question>> bank = _loadBank();

  /// Nạp một lần rồi dùng lại; chỉ đọc lại đĩa khi có thay đổi bộ thẻ.
  late Future<List<Sm2Item>> cardsFuture = widget.storage.loadCards();
  QuestionLanguage language = QuestionLanguage.vietnamese;
  int selectedTab = 0;
  int topic = 0;
  int count = 10;

  Future<List<Question>> _loadBank() async => decodeQuestions(
    await rootBundle.loadString('assets/flutter_quiz_300.json'),
  );

  /// Đọc lại bộ thẻ sau khi người dùng lưu thẻ hoặc ôn tập.
  void _refreshCards() {
    if (!mounted) return;
    // Phải dùng thân hàm: setState không nhận callback trả về Future.
    setState(() {
      cardsFuture = widget.storage.loadCards();
    });
  }

  Future<bool?> _showResult(QuizResult result) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            result: result,
            language: language,
            storage: widget.storage,
          ),
        ),
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
      final retry = await _showResult(result);
      if (retry != true) return;
      final wrong = result.wrongQuestions.toList();
      items = createQuiz(wrong, wrong.length);
      timed = false;
    }
  }

  Future<void> _openCards(List<Question> questions) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardPage(
          allQuestions: questions,
          storage: widget.storage,
          language: language,
        ),
      ),
    );
    _refreshCards();
  }

  Future<void> _start(
    List<Question> pool,
    int size, {
    bool exam = false,
  }) async {
    await _runQuiz(pool, size, exam: exam);
    _refreshCards();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        ['Flutter Lab', 'Luyện tập', 'Thẻ ôn'][selectedTab],
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Camera học tập · Sắp có',
          onPressed: () => showLearningTool(context, LearningTool.camera),
          icon: const Icon(Icons.camera_alt_outlined),
        ),
        PopupMenuButton<QuestionLanguage>(
          tooltip: 'Ngôn ngữ câu hỏi',
          initialValue: language,
          onSelected: (value) => setState(() => language = value),
          icon: const Icon(Icons.translate),
          itemBuilder: (_) => [
            for (final value in QuestionLanguage.values)
              PopupMenuItem(value: value, child: Text(value.label)),
          ],
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selectedTab,
      onDestinationSelected: (value) {
        setState(() => selectedTab = value);
        _refreshCards();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Hôm nay',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Luyện tập',
        ),
        NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          selectedIcon: Icon(Icons.layers),
          label: 'Thẻ ôn',
        ),
      ],
    ),
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
        if (selectedTab == 0) {
          return TodayOverview(
            questions: questions,
            cardsFuture: cardsFuture,
            onOpenCards: () => _openCards(questions),
            onQuickPractice: () => _start(questions, 10),
            onExam: () => _start(questions, 50, exam: true),
            onPracticeSetup: () => setState(() => selectedTab = 1),
            onTopic: (value) => setState(() {
              topic = value;
              selectedTab = 1;
            }),
          );
        }
        if (selectedTab == 2) {
          return FlashcardPage(
            allQuestions: questions,
            storage: widget.storage,
            language: language,
            embedded: true,
            onCardsChanged: _refreshCards,
            onPracticeRequested: () => setState(() => selectedTab = 1),
          );
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
              onPressed: () async {
                await _runQuiz(pool, practiceCount);
                _refreshCards();
              },
              icon: const Icon(Icons.school_outlined),
              label: const Text('Bắt đầu luyện tập'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await _runQuiz(questions, 50, exam: true);
                _refreshCards();
              },
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Thi thử · 50 câu · 50 phút'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final sampleResult = createSampleResult(questions);
                final retry = await _showResult(sampleResult);
                if (!mounted) return;
                if (retry == true) {
                  final wrong = sampleResult.wrongQuestions.toList();
                  await _runQuiz(wrong, wrong.length);
                }
                _refreshCards();
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text(
                'Xem lượt kết quả mẫu (1 đúng, 1 sai, 1 bỏ trống)',
              ),
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
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.language,
    this.storage = const SharedPrefsCardStorage(),
  });

  final QuizResult result;
  final QuestionLanguage language;
  final CardStorage storage;

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
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: const Icon(Icons.replay),
                          label: Text('Làm lại $wrongCount câu sai'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final added = await storage.addCards(
                              result.wrongQuestions.map((q) => q.id),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added > 0
                                        ? 'Đã lưu $added câu sai vào bộ thẻ ôn tập!'
                                        : 'Tất cả câu sai này đã có sẵn trong bộ thẻ.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text('Lưu $wrongCount câu sai vào thẻ'),
                        ),
                      ],
                    ),
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
          final card = QuestionCard(
            id: 'card_${question.id}',
            questionId: question.id,
          );
          final resolvedQuestion =
              card.resolve(result.items.map((i) => i.question)) ?? question;

          final selected = result.answers[resolvedQuestion.id];
          final status = switch (selected) {
            null => 'Bỏ trống',
            _ when selected == resolvedQuestion.correctId => 'Đúng',
            _ => 'Sai',
          };
          return ExpansionTile(
            title: Text('Câu $index [Mã #${resolvedQuestion.id}] · $status'),
            subtitle: Text(topicLabel(question.topic)),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: 'Lưu câu này vào bộ thẻ',
              onPressed: () async {
                final added = await storage.addCards([question.id]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added > 0
                            ? 'Đã lưu câu #${question.id} vào bộ thẻ ôn tập!'
                            : 'Câu #${question.id} đã có trong bộ thẻ.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              QuestionPrompt(question: resolvedQuestion, language: language),
              for (final (position, choice) in item.choices.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${String.fromCharCode(65 + position)}. ${language.display(choice.vi, choice.en)}',
                  ),
                  subtitle: choice.id == resolvedQuestion.correctId
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
                  resolvedQuestion.explanationVi,
                  resolvedQuestion.explanationEn,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => showLearningTool(
                  context,
                  LearningTool.assistant,
                  question: resolvedQuestion,
                  language: language,
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Hỏi AI về câu này · Sắp có'),
              ),
            ],
          );
        },
      ),
    );
  }
}
