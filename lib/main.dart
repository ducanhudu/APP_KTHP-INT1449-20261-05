import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_strings.dart';
import 'app_theme.dart';
import 'card_storage.dart';
import 'history_page.dart';
import 'history_storage.dart';
import 'learning_tools.dart';
import 'quiz_attempt.dart';
import 'weakness_analyzer.dart';
import 'today_overview.dart';
import 'statistics_page.dart';
import 'flashcard_page.dart';
import 'error_state.dart';
import 'question.dart';
import 'question_prompt.dart';
import 'quiz_option_tile.dart';
import 'reminder_service.dart';
import 'sm2.dart';

export 'question_prompt.dart';
export 'quiz_option_tile.dart';

void main() => runApp(const FlutterLab());

class FlutterLab extends StatelessWidget {
  const FlutterLab({
    super.key,
    this.storage = const SharedPrefsCardStorage(),
    this.historyStorage = const SharedPrefsHistoryStorage(),
    this.reminder,
  });

  final CardStorage storage;
  final HistoryStorage historyStorage;
  final ReminderService? reminder;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Lab',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: QuizHome(
      storage: storage,
      historyStorage: historyStorage,
      reminder: reminder,
    ),
  );
}

class QuizHome extends StatefulWidget {
  const QuizHome({
    super.key,
    this.storage = const SharedPrefsCardStorage(),
    this.historyStorage = const SharedPrefsHistoryStorage(),
    this.reminder,
  });

  final CardStorage storage;
  final HistoryStorage historyStorage;
  final ReminderService? reminder;

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  /// Nhãn giao diện theo ngôn ngữ đang chọn.
  AppStrings get s => AppStrings.of(language);
  late Future<List<Question>> bank = _loadBank();

  /// Nạp một lần rồi dùng lại; chỉ đọc lại đĩa khi có thay đổi bộ thẻ.
  late Future<List<Sm2Item>> cardsFuture = widget.storage.loadCards();

  /// Đọc lịch sử làm bài để phục vụ gợi ý điểm yếu.
  late Future<List<QuizAttempt>> historyFuture = widget.historyStorage
      .loadHistory();

  /// Chỉ tạo dịch vụ nhắc ôn khi thực sự dùng, để test truyền bản giả.
  late final ReminderService reminder =
      widget.reminder ?? NotificationReminderService();
  QuestionLanguage language = QuestionLanguage.vietnamese;
  int selectedTab = 0;
  int topic = 0;
  int count = 10;
  int _deckRevision = 0;

  Future<List<Question>> _loadBank() async => decodeQuestions(
    await rootBundle.loadString('assets/flutter_quiz_300.json'),
  );

  /// Đọc lại bộ thẻ và lịch sử sau khi người dùng làm bài, lưu thẻ hoặc ôn tập.
  void _refreshCards() {
    if (!mounted) return;
    // Phải dùng thân hàm: setState không nhận callback trả về Future.
    setState(() {
      cardsFuture = widget.storage.loadCards();
      historyFuture = widget.historyStorage.loadHistory();
    });
  }

  Future<void> _startAdaptivePractice(List<Question> questions) async {
    final history = await widget.historyStorage.loadHistory();
    final cards = await cardsFuture;
    final analysis = WeaknessAnalyzer.analyze(
      history: history,
      bank: questions,
      flashcards: cards,
    );
    final adaptive = WeaknessAnalyzer.selectAdaptiveQuestions(
      analysis: analysis,
      bank: questions,
      history: history,
      flashcards: cards,
      count: 10,
    );
    if (adaptive.isEmpty) return;
    await _runQuiz(adaptive, adaptive.length);
    _refreshCards();
  }

  /// Mở Gia sư AI với một câu người dùng đã làm sai gần đây.
  ///
  /// Panel AI cần câu hỏi cụ thể, còn nút ở tab Hôm nay không có ngữ cảnh, nên
  /// phải cho chọn. Chưa có câu sai nào thì hướng dẫn làm một lượt luyện tập.
  Future<void> _openAiTutor(List<Question> questions) async {
    final history = await widget.historyStorage.loadHistory();
    final bank = {for (final question in questions) question.id: question};
    final wrong = <Question>[];
    final seen = <int>{};
    for (final attempt in history) {
      for (final entry in attempt.answers.entries) {
        final question = bank[entry.key];
        if (question == null || entry.value == question.correctId) continue;
        if (seen.add(question.id)) wrong.add(question);
        if (wrong.length >= 10) break;
      }
      if (wrong.length >= 10) break;
    }
    if (!mounted) return;
    if (wrong.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.aiTutorNoHistory)));
      return;
    }
    final picked = await showModalBottomSheet<Question>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              s.aiTutorPickTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final question in wrong)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                language.display(question.vi, question.en),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${topicLabel(question.topic, language)} · #${question.id}',
              ),
              onTap: () => Navigator.pop(context, question),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await showLearningTool(
      context,
      LearningTool.assistant,
      question: picked,
      language: language,
    );
  }

  Future<void> _openCamera() async {
    await showLearningTool(
      context,
      LearningTool.camera,
      language: language,
      storage: widget.storage,
    );
    if (!mounted) return;
    setState(() => _deckRevision++);
    _refreshCards();
  }

  Future<void> _openStatistics(List<Question> questions) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StatisticsPage(
          historyStorage: widget.historyStorage,
          questions: questions,
          language: language,
        ),
      ),
    );
  }

  /// Đọc lại ngân hàng câu hỏi khi người dùng bấm "Thử lại" ở màn hình lỗi.
  void _retryBank() {
    setState(() {
      bank = _loadBank();
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
      final startTime = DateTime.now();
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
      final duration = DateTime.now().difference(startTime).inSeconds;
      final resultTopics = items.map((item) => item.question.topic).toSet();
      final attempt = QuizAttempt.fromResult(
        result: result,
        isExam: timed,
        topic: timed || resultTopics.length != 1 ? 0 : resultTopics.single,
        durationSeconds: duration,
      );
      try {
        await widget.historyStorage.saveAttempt(attempt);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                language == QuestionLanguage.english
                    ? 'Could not save history. Your result is still available.'
                    : 'Chưa lưu được lịch sử. Bạn vẫn có thể xem kết quả.',
              ),
            ),
          );
        }
      }
      if (!mounted) return;

      final retry = await _showResult(result);
      if (retry != true) return;
      final wrong = result.wrongQuestions.toList();
      if (wrong.isEmpty) return;
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
        [s.appTitle, s.tabPractice, s.tabCards][selectedTab],
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: s.historyTooltip,
          onPressed: () async {
            final questions = await bank;
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryPage(
                  historyStorage: widget.historyStorage,
                  allQuestions: questions,
                  language: language,
                  cardStorage: widget.storage,
                  onRetryWrong: (wrong) => _runQuiz(wrong, wrong.length),
                ),
              ),
            );
            if (!mounted) return;
            setState(() => _deckRevision++);
            _refreshCards();
          },
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: s.cameraTooltip,
          onPressed: _openCamera,
          icon: const Icon(Icons.camera_alt_outlined),
        ),
        PopupMenuButton<QuestionLanguage>(
          tooltip: s.languageTooltip,
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
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: s.tabToday,
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: s.tabPractice,
        ),
        NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          selectedIcon: Icon(Icons.layers),
          label: s.tabCards,
        ),
      ],
    ),
    body: FutureBuilder(
      future: bank,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(message: s.errorBankLoad, onRetry: _retryBank);
        }
        final questions = snapshot.data;
        if (questions == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (selectedTab == 0) {
          return TodayOverview(
            questions: questions,
            cardsFuture: cardsFuture,
            historyFuture: historyFuture,
            onAdaptivePractice: () => _startAdaptivePractice(questions),
            onCameraRequested: _openCamera,
            onAiTutor: () => _openAiTutor(questions),
            onStatistics: () => _openStatistics(questions),
            onOpenCards: () => _openCards(questions),
            onQuickPractice: () => _start(questions, 10),
            onExam: () => _start(questions, 50, exam: true),
            onPracticeSetup: () => setState(() => selectedTab = 1),
            onRetryCards: _refreshCards,
            language: language,
            reminder: reminder,
            onTopic: (value) => setState(() {
              topic = value;
              selectedTab = 1;
            }),
          );
        }
        if (selectedTab == 2) {
          return FlashcardPage(
            key: ValueKey(_deckRevision),
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
              s.practiceHeading,
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
              decoration: InputDecoration(labelText: s.languageLabel),
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
              decoration: InputDecoration(labelText: s.topicLabel),
              items: [
                DropdownMenuItem(value: 0, child: Text(s.allTopics)),
                for (var i = 1; i <= topicNames.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(topicLabel(i, language)),
                  ),
              ],
              onChanged: (value) => setState(() => topic = value!),
            ),
            const SizedBox(height: 16),
            Text(s.practiceCountLabel),
            Wrap(
              spacing: 8,
              children: [
                for (final size in availableCounts)
                  ChoiceChip(
                    label: Text('$size ${s.unitQuestions}'),
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
              label: Text(s.startPractice),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await _runQuiz(questions, 50, exam: true);
                _refreshCards();
              },
              icon: const Icon(Icons.timer_outlined),
              label: Text(s.examButton),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _startAdaptivePractice(questions),
              icon: const Icon(Icons.bolt),
              label: Text(s.practiceWeaknessBtn),
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
    this.examDuration = const Duration(minutes: 50),
    this.clock,
  });

  final List<QuizItem> items;
  final QuestionLanguage language;
  final bool timed;
  final ValueChanged<QuestionLanguage> onLanguageChanged;

  /// Thời lượng bài thi. Tách ra để test có thể dùng thời lượng ngắn.
  final Duration examDuration;

  /// Đồng hồ dùng cho hạn nộp; test truyền vào để điều khiển thời gian.
  final DateTime Function()? clock;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  AppStrings get s => AppStrings.of(language);
  final answers = <int, String>{};
  late QuestionLanguage language = widget.language;

  /// Đồng hồ của bài; test truyền vào để điều khiển thời gian.
  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  DateTime? deadline;
  Timer? timer;
  int index = 0;
  bool submitted = false;
  late int seconds = widget.examDuration.inSeconds;

  @override
  void initState() {
    super.initState();
    if (widget.timed) {
      deadline = _now().add(widget.examDuration);
      timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    }
  }

  bool _tick() {
    final end = deadline;
    if (end == null || submitted) return submitted;
    final remaining = (end.difference(_now()).inMilliseconds / 1000).ceil();
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
        title: Text(widget.timed ? s.quizExamTitle : s.quizPracticeTitle),
        actions: [
          if (widget.timed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(clock)),
            ),
          PopupMenuButton<QuestionLanguage>(
            tooltip: s.languageTooltip,
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxContentWidth = 720.0;
            final basePadding = constraints.maxWidth < 380 ? 16.0 : 20.0;
            final horizontalPadding =
                constraints.maxWidth > maxContentWidth + basePadding * 2
                ? (constraints.maxWidth - maxContentWidth) / 2
                : basePadding;
            final theme = Theme.of(context);
            final colors = theme.colorScheme;
            final selectedChoiceId = answers[question.id];
            final isCorrect = selectedChoiceId == question.correctId;

            return ListView(
              key: ValueKey(index),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              children: [
                Text(
                  s.quizCounter(index + 1, widget.items.length, answers.length),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: answers.length / widget.items.length,
                ),
                const SizedBox(height: 16),
                Text(
                  '${topicLabel(question.topic, language)} · ${question.level}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                QuestionPrompt(question: question, language: language),
                const SizedBox(height: 16),
                for (final (position, choice) in item.choices.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuizOptionTile(
                      label: String.fromCharCode(65 + position),
                      text: language.display(choice.vi, choice.en),
                      selected: selectedChoiceId == choice.id,
                      onTap: () {
                        if (_tick()) return;
                        setState(() {
                          if (selectedChoiceId == choice.id) {
                            answers.remove(question.id);
                          } else {
                            answers[question.id] = choice.id;
                          }
                        });
                      },
                    ),
                  ),
                if (!widget.timed && selectedChoiceId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Card(
                      color: isCorrect
                          ? colors.primaryContainer.withValues(alpha: 0.45)
                          : colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isCorrect
                              ? colors.primary.withValues(alpha: 0.4)
                              : colors.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline,
                                  size: 20,
                                  color: isCorrect
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isCorrect
                                        ? s.verdictCorrect
                                        : s.verdictReview,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isCorrect
                                          ? colors.onPrimaryContainer
                                          : colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              language.display(
                                question.explanationVi,
                                question.explanationEn,
                              ),
                              softWrap: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: s.prevQuestion,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: index == 0
                                  ? null
                                  : () => _goTo(index - 1),
                              icon: const Icon(Icons.navigate_before),
                              label: Text(
                                s.prevQuestion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Tooltip(
                            message: s.nextQuestion,
                            child: FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: index == widget.items.length - 1
                                  ? null
                                  : () => _goTo(index + 1),
                              icon: const Icon(Icons.navigate_next),
                              iconAlignment: IconAlignment.end,
                              label: Text(
                                s.nextQuestion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          if (!_tick()) _submit();
                        },
                        child: Text(s.submit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  AppStrings get s => AppStrings.of(language);
  final CardStorage storage;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final topics = result.byTopic.entries.toList();
    final wrongCount = result.wrongQuestions.length;
    return Scaffold(
      appBar: AppBar(title: Text(s.resultTitle)),
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
                Text(s.scoreLine(score.correct, score.wrong, score.skipped)),
                if (result.expired) Text(s.expiredNotice),
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
                          label: Text(s.retryWrong(wrongCount)),
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
                          label: Text(s.saveWrong(wrongCount)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  s.statsHeading,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final entry in topics)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(topicLabel(entry.key, language)),
                    subtitle: Text(
                      s.scoreLine(
                        entry.value.correct,
                        entry.value.wrong,
                        entry.value.skipped,
                      ),
                    ),
                    trailing: Text('${entry.value.percent}%'),
                  ),
                const Divider(),
                Text(
                  s.reviewHeading,
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
            null => s.statusSkipped,
            _ when selected == resolvedQuestion.correctId => s.statusCorrect,
            _ => s.statusWrong,
          };
          return ExpansionTile(
            title: Text(
              s.reviewQuestionTitle(index, resolvedQuestion.id, status),
            ),
            subtitle: Text(topicLabel(question.topic, language)),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: s.saveThisCard,
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
                              ? s.correctAnswerChosen
                              : s.correctAnswer,
                        )
                      : choice.id == selected
                      ? Text(s.chosenOnly)
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
                label: Text(s.aiAsk),
              ),
            ],
          );
        },
      ),
    );
  }
}
