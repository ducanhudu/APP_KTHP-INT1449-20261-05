import 'question.dart';

/// Chuỗi giao diện hai ngôn ngữ (Việt / Anh).
///
/// Nội dung câu hỏi đã song ngữ sẵn trong JSON; lớp này lo phần **nhãn giao
/// diện** để khi chọn English thì cả app đổi ngôn ngữ, không chỉ nội dung.
class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.tabToday,
    required this.tabPractice,
    required this.tabCards,
    required this.cameraTooltip,
    required this.languageTooltip,
    required this.practiceHeading,
    required this.languageLabel,
    required this.topicLabel,
    required this.allTopics,
    required this.practiceCountLabel,
    required this.unitQuestions,
    required this.loadingCards,
    required this.cardsDue,
    required this.cardsSaved,
    required this.bankSummary,
    required this.startPractice,
    required this.examButton,
    required this.quizPracticeTitle,
    required this.quizExamTitle,
    required this.quizCounter,
    required this.prevQuestion,
    required this.submit,
    required this.nextQuestion,
    required this.verdictCorrect,
    required this.verdictReview,
    required this.saveThisCard,
    required this.aiAsk,
    required this.resultTitle,
    required this.scoreLine,
    required this.expiredNotice,
    required this.retryWrong,
    required this.saveWrong,
    required this.statsHeading,
    required this.reviewHeading,
    required this.reviewQuestionTitle,
    required this.statusCorrect,
    required this.statusWrong,
    required this.statusSkipped,
    required this.correctAnswer,
    required this.correctAnswerChosen,
    required this.chosenOnly,
    required this.cancelButton,
    required this.todaySubtitle,
    required this.todayHeading,
    required this.cardsTitle,
    required this.cardsRetry,
    required this.openCardsDue,
    required this.openCards,
    required this.practiceSection,
    required this.quickPractice,
    required this.examShort,
    required this.pickTopic,
    required this.all,
    required this.toolsHeading,
    required this.aiTutor,
    required this.aiTutorSubtitle,
    required this.cameraTool,
    required this.cameraSubtitle,
    required this.soon,
    required this.reminderTitle,
    required this.reminderOn,
    required this.reminderOff,
    required this.reminderEnabled,
    required this.reminderDisabled,
    required this.reminderDenied,
    required this.reminderFailed,
    required this.cardsPageTitle,
    required this.cardCounter,
    required this.dueTab,
    required this.allTab,
    required this.revealAnswer,
    required this.gradeForgot,
    required this.gradeHard,
    required this.gradeGood,
    required this.gradeEasy,
    required this.deleteCard,
    required this.cardDeleted,
    required this.backToPractice,
    required this.studyAll,
    required this.cardNotFound,
    required this.deleteBrokenCard,
    required this.retry,
    required this.errorBankLoad,
    required this.historyTitle,
    required this.historyTooltip,
    required this.emptyHistory,
    required this.clearHistory,
    required this.confirmClearHistory,
    required this.confirmClearHistoryContent,
    required this.historyFilterAll,
    required this.historyFilterPractice,
    required this.historyFilterExam,
    required this.historyDeleteAttempt,
    required this.historyAttemptDeleted,
    required this.historyExamLabel,
    required this.historyPracticeLabel,
    required this.historyDuration,
    required this.errorHistoryLoad,
    required this.historyReviewUnavailable,
    required this.weaknessHeading,
    required this.weaknessSubtitle,
    required this.practiceWeaknessBtn,
    required this.noWeaknessData,
    required this.noWeaknessHint,
    required this.accuracyText,
    required this.weakTopicBadge,
    required this.topicShort,
    required this.aiPanelTitle,
    required this.aiFallbackLabel,
    required this.aiQuestionRef,
    required this.aiLoading,
    required this.aiNoQuestion,
    required this.aiGeneratedLabel,
    required this.aiAccessCodeTitle,
    required this.aiAccessCodeHint,
    required this.aiAccessCodeButton,
    required this.aiAskAgain,
    required this.ttsListen,
    required this.ttsStop,
    required this.ttsAudioPermission,
    required this.saveButton,
    required this.closeButton,
  });

  final String appTitle;
  final String tabToday;
  final String tabPractice;
  final String tabCards;
  final String cameraTooltip;
  final String languageTooltip;
  final String practiceHeading;
  final String languageLabel;
  final String topicLabel;
  final String allTopics;
  final String practiceCountLabel;
  final String unitQuestions;
  final String loadingCards;
  final String Function(int due) cardsDue;
  final String Function(int saved, int due) cardsSaved;
  final String Function(int questions, int topics) bankSummary;
  final String startPractice;
  final String examButton;
  final String quizPracticeTitle;
  final String quizExamTitle;
  final String Function(int index, int total, int answered) quizCounter;
  final String prevQuestion;
  final String submit;
  final String nextQuestion;
  final String verdictCorrect;
  final String verdictReview;
  final String saveThisCard;
  final String aiAsk;
  final String resultTitle;
  final String Function(int correct, int wrong, int skipped) scoreLine;
  final String expiredNotice;
  final String Function(int count) retryWrong;
  final String Function(int count) saveWrong;
  final String statsHeading;
  final String reviewHeading;
  final String Function(int index, int code, String status) reviewQuestionTitle;
  final String statusCorrect;
  final String statusWrong;
  final String statusSkipped;
  final String correctAnswer;
  final String correctAnswerChosen;
  final String chosenOnly;
  final String cancelButton;
  final String todaySubtitle;
  final String todayHeading;
  final String cardsTitle;
  final String cardsRetry;
  final String openCardsDue;
  final String openCards;
  final String practiceSection;
  final String quickPractice;
  final String examShort;
  final String pickTopic;
  final String all;
  final String toolsHeading;
  final String aiTutor;
  final String aiTutorSubtitle;
  final String cameraTool;
  final String cameraSubtitle;
  final String soon;
  final String reminderTitle;
  final String reminderOn;
  final String reminderOff;
  final String reminderEnabled;
  final String reminderDisabled;
  final String reminderDenied;
  final String reminderFailed;
  final String cardsPageTitle;
  final String Function(int index, int total) cardCounter;
  final String dueTab;
  final String allTab;
  final String revealAnswer;
  final String gradeForgot;
  final String gradeHard;
  final String gradeGood;
  final String gradeEasy;
  final String deleteCard;
  final String cardDeleted;
  final String backToPractice;
  final String studyAll;
  final String Function(int code) cardNotFound;
  final String deleteBrokenCard;
  final String retry;
  final String errorBankLoad;
  final String historyTitle;
  final String historyTooltip;
  final String emptyHistory;
  final String clearHistory;
  final String confirmClearHistory;
  final String confirmClearHistoryContent;
  final String historyFilterAll;
  final String historyFilterPractice;
  final String historyFilterExam;
  final String historyDeleteAttempt;
  final String historyAttemptDeleted;
  final String historyExamLabel;
  final String historyPracticeLabel;
  final String Function(int minutes, int seconds) historyDuration;
  final String errorHistoryLoad;
  final String historyReviewUnavailable;
  final String weaknessHeading;
  final String weaknessSubtitle;
  final String practiceWeaknessBtn;
  final String noWeaknessData;
  final String noWeaknessHint;
  final String Function(int percent) accuracyText;
  final String weakTopicBadge;

  /// Nhãn khối rút gọn cho panel AI: `K01 · Dart căn bản`.
  final String Function(int topic) topicShort;
  final String aiPanelTitle;
  final String aiFallbackLabel;
  final String Function(int id, String topic) aiQuestionRef;
  final String aiLoading;
  final String aiNoQuestion;
  final String aiGeneratedLabel;
  final String aiAccessCodeTitle;
  final String aiAccessCodeHint;
  final String aiAccessCodeButton;
  final String aiAskAgain;
  final String ttsListen;
  final String ttsStop;
  final String ttsAudioPermission;
  final String saveButton;
  final String closeButton;

  /// Chọn bộ chuỗi theo ngôn ngữ đang dùng. Chế độ song ngữ hiển thị tiếng Việt
  /// cho nhãn giao diện vì nội dung đã có cả hai thứ tiếng.
  static AppStrings of(QuestionLanguage language) =>
      language == QuestionLanguage.english ? english : vietnamese;

  static const AppStrings vietnamese = AppStrings(
    appTitle: 'Flutter Lab',
    tabToday: 'Hôm nay',
    tabPractice: 'Luyện tập',
    tabCards: 'Thẻ ôn',
    cameraTooltip: 'Camera học tập',
    languageTooltip: 'Ngôn ngữ câu hỏi',
    practiceHeading: 'Ôn thi Flutter và Dart',
    languageLabel: 'Ngôn ngữ câu hỏi',
    topicLabel: 'Khối luyện tập',
    allTopics: 'Tất cả các khối',
    practiceCountLabel: 'Số câu luyện tập',
    unitQuestions: 'câu',
    loadingCards: 'Đang tải thẻ…',
    cardsDue: _viCardsDue,
    cardsSaved: _viCardsSaved,
    bankSummary: _viBankSummary,
    startPractice: 'Bắt đầu luyện tập',
    examButton: 'Thi thử · 50 câu · 50 phút',
    quizPracticeTitle: 'Luyện tập',
    quizExamTitle: 'Thi thử',
    quizCounter: _viCounter,
    prevQuestion: 'Câu trước',
    submit: 'Nộp bài',
    nextQuestion: 'Câu tiếp theo',
    verdictCorrect: 'Chính xác',
    verdictReview: 'Cần xem lại',
    saveThisCard: 'Lưu câu này vào bộ thẻ',
    aiAsk: 'Hỏi AI về câu này',
    resultTitle: 'Kết quả',
    scoreLine: _viScore,
    expiredNotice: 'Hết giờ, bài thi đã được nộp.',
    retryWrong: _viRetryWrong,
    saveWrong: _viSaveWrong,
    statsHeading: 'Thống kê theo khối',
    reviewHeading: 'Xem lại bài',
    reviewQuestionTitle: _viReviewTitle,
    statusCorrect: 'Đúng',
    statusWrong: 'Sai',
    statusSkipped: 'Bỏ trống',
    correctAnswer: 'Đáp án đúng',
    correctAnswerChosen: 'Đáp án đúng · Bạn đã chọn',
    chosenOnly: 'Bạn đã chọn',
    cancelButton: 'Hủy',
    todaySubtitle: 'Ôn Flutter và Dart',
    todayHeading: 'Hôm nay học gì?',
    cardsTitle: 'Ôn tập Flashcard (SM-2)',
    cardsRetry: 'Chưa đọc được bộ thẻ. Thử lại',
    openCardsDue: 'Ôn thẻ ngay',
    openCards: 'Mở bộ thẻ',
    practiceSection: 'Luyện tập',
    quickPractice: 'Luyện 10 câu',
    examShort: 'Thi thử',
    pickTopic: 'Chọn chủ đề',
    all: 'Tất cả',
    toolsHeading: 'Công cụ học tập',
    aiTutor: 'Gia sư AI',
    aiTutorSubtitle: 'Giải thích theo câu hỏi và chủ đề',
    cameraTool: 'Camera học tập',
    cameraSubtitle: 'Quét QR và chụp câu hỏi',
    soon: 'Sắp có',
    reminderTitle: 'Nhắc ôn hằng ngày',
    reminderOn: 'Nhắc lúc 20:00 mỗi ngày',
    reminderOff: 'Nhận thông báo khi có thẻ đến hạn',
    reminderEnabled: 'Đã bật nhắc ôn lúc 20:00 mỗi ngày.',
    reminderDisabled: 'Đã tắt nhắc ôn hằng ngày.',
    reminderDenied:
        'Chưa có quyền thông báo. Hãy bật quyền trong Cài đặt để nhận nhắc ôn.',
    reminderFailed: 'Không đặt được lịch nhắc. Thử lại sau.',
    cardsPageTitle: 'Thẻ ghi nhớ SM-2',
    cardCounter: _viCardCounter,
    dueTab: 'Đến hạn',
    allTab: 'Tất cả',
    revealAnswer: 'Xem đáp án & giải thích',
    gradeForgot: '1: Quên (Mai ôn lại)',
    gradeHard: '3: Khó nhớ',
    gradeGood: '4: Nhớ tốt',
    gradeEasy: '5: Rất dễ',
    deleteCard: 'Xoá thẻ này',
    cardDeleted: 'Đã xoá thẻ khỏi bộ ôn tập.',
    backToPractice: 'Quay lại luyện tập',
    studyAll: 'Ôn tiếp tất cả thẻ',
    cardNotFound: _viCardNotFound,
    deleteBrokenCard: 'Xoá thẻ lỗi này',
    retry: 'Thử lại',
    errorBankLoad: 'Không đọc được ngân hàng câu hỏi.',
    historyTitle: 'Lịch sử làm bài',
    historyTooltip: 'Xem lịch sử làm bài',
    emptyHistory: 'Chưa có lượt làm bài nào.',
    clearHistory: 'Xoá lịch sử',
    confirmClearHistory: 'Xoá lịch sử làm bài?',
    confirmClearHistoryContent:
        'Toàn bộ kết quả các lượt luyện tập và thi thử đã lưu sẽ bị xoá.',
    historyFilterAll: 'Tất cả',
    historyFilterPractice: 'Luyện tập',
    historyFilterExam: 'Thi thử',
    historyDeleteAttempt: 'Xoá lượt này',
    historyAttemptDeleted: 'Đã xoá lượt làm bài khỏi lịch sử.',
    historyExamLabel: 'Thi thử',
    historyPracticeLabel: 'Luyện tập',
    historyDuration: _viHistoryDuration,
    errorHistoryLoad: 'Không đọc được lịch sử làm bài.',
    historyReviewUnavailable: 'Không thể ôn lại vì câu hỏi không còn khả dụng.',
    weaknessHeading: 'Khối cần cải thiện',
    weaknessSubtitle: 'Gợi ý luyện tập theo điểm yếu từ các bài làm của bạn',
    practiceWeaknessBtn: 'Luyện 10 câu điểm yếu',
    noWeaknessData: 'Chưa đủ dữ liệu điểm yếu',
    noWeaknessHint: 'Hãy hoàn thành một bài luyện tập hoặc thi thử để hệ thống gợi ý khối yếu cho bạn.',
    accuracyText: _viAccuracy,
    weakTopicBadge: 'Cần củng cố',
    topicShort: _viTopicShort,
    aiPanelTitle: 'Giải thích AI',
    aiFallbackLabel: 'Lời giải gốc',
    aiQuestionRef: _viAiQuestionRef,
    aiLoading: 'Đang hỏi AI, có thể mất 10-60 giây…',
    aiNoQuestion: 'Chưa có câu hỏi để giải thích.',
    aiGeneratedLabel: 'AI giải thích',
    aiAccessCodeTitle: 'Mã truy cập AI',
    aiAccessCodeHint: 'Mã do nhóm cung cấp',
    aiAccessCodeButton: 'Mã truy cập AI',
    aiAskAgain: 'Hỏi lại',
    ttsListen: 'Nghe lời giải',
    ttsStop: 'Dừng đọc',
    ttsAudioPermission:
        'Không có quyền audio. Hãy bật trong Cài đặt để nghe giọng đọc.',
    saveButton: 'Lưu',
    closeButton: 'Đóng',
  );

  static const AppStrings english = AppStrings(
    appTitle: 'Flutter Lab',
    tabToday: 'Today',
    tabPractice: 'Practice',
    tabCards: 'Cards',
    cameraTooltip: 'Study camera',
    languageTooltip: 'Question language',
    practiceHeading: 'Flutter and Dart exam practice',
    languageLabel: 'Question language',
    topicLabel: 'Practice topic',
    allTopics: 'All topics',
    practiceCountLabel: 'Number of questions',
    unitQuestions: 'questions',
    loadingCards: 'Loading cards…',
    cardsDue: _enCardsDue,
    cardsSaved: _enCardsSaved,
    bankSummary: _enBankSummary,
    startPractice: 'Start practice',
    examButton: 'Mock exam · 50 questions · 50 minutes',
    quizPracticeTitle: 'Practice',
    quizExamTitle: 'Mock exam',
    quizCounter: _enCounter,
    prevQuestion: 'Previous',
    submit: 'Submit',
    nextQuestion: 'Next',
    verdictCorrect: 'Correct',
    verdictReview: 'Review this one',
    saveThisCard: 'Save this question as a card',
    aiAsk: 'Ask AI about this question',
    resultTitle: 'Result',
    scoreLine: _enScore,
    expiredNotice: 'Time is up. Your exam was submitted.',
    retryWrong: _enRetryWrong,
    saveWrong: _enSaveWrong,
    statsHeading: 'Breakdown by topic',
    reviewHeading: 'Review answers',
    reviewQuestionTitle: _enReviewTitle,
    statusCorrect: 'Correct',
    statusWrong: 'Wrong',
    statusSkipped: 'Skipped',
    correctAnswer: 'Correct answer',
    correctAnswerChosen: 'Correct answer · Your choice',
    chosenOnly: 'Your choice',
    cancelButton: 'Cancel',
    todaySubtitle: 'Practise Flutter and Dart',
    todayHeading: 'What will you study today?',
    cardsTitle: 'Flashcards (SM-2)',
    cardsRetry: 'Could not read your cards. Try again',
    openCardsDue: 'Review now',
    openCards: 'Open cards',
    practiceSection: 'Practice',
    quickPractice: 'Practise 10 questions',
    examShort: 'Mock exam',
    pickTopic: 'Pick a topic',
    all: 'All',
    toolsHeading: 'Study tools',
    aiTutor: 'AI tutor',
    aiTutorSubtitle: 'Explains by question and topic',
    cameraTool: 'Study camera',
    cameraSubtitle: 'Scan QR codes and capture questions',
    soon: 'Coming soon',
    reminderTitle: 'Daily review reminder',
    reminderOn: 'Reminder at 20:00 every day',
    reminderOff: 'Get notified when cards are due',
    reminderEnabled: 'Daily reminder set for 20:00.',
    reminderDisabled: 'Daily reminder turned off.',
    reminderDenied: 'Notification permission is off. Enable it in Settings to get reminders.',
    reminderFailed: 'Could not schedule the reminder. Try again later.',
    cardsPageTitle: 'SM-2 flashcards',
    cardCounter: _enCardCounter,
    dueTab: 'Due',
    allTab: 'All',
    revealAnswer: 'Show answer and explanation',
    gradeForgot: '1: Forgot (review tomorrow)',
    gradeHard: '3: Hard',
    gradeGood: '4: Good',
    gradeEasy: '5: Easy',
    deleteCard: 'Delete this card',
    cardDeleted: 'Card removed from your deck.',
    backToPractice: 'Back to practice',
    studyAll: 'Review all cards',
    cardNotFound: _enCardNotFound,
    deleteBrokenCard: 'Delete this broken card',
    retry: 'Try again',
    errorBankLoad: 'Could not load the question bank.',
    historyTitle: 'Quiz History',
    historyTooltip: 'View quiz history',
    emptyHistory: 'No quiz history yet.',
    clearHistory: 'Clear history',
    confirmClearHistory: 'Clear quiz history?',
    confirmClearHistoryContent:
        'All past practice and exam attempt records will be deleted.',
    historyFilterAll: 'All',
    historyFilterPractice: 'Practice',
    historyFilterExam: 'Exam',
    historyDeleteAttempt: 'Delete this attempt',
    historyAttemptDeleted: 'Attempt record deleted.',
    historyExamLabel: 'Mock Exam',
    historyPracticeLabel: 'Practice',
    historyDuration: _enHistoryDuration,
    errorHistoryLoad: 'Could not load quiz history.',
    historyReviewUnavailable:
        'Cannot review because these questions are no longer available.',
    weaknessHeading: 'Areas to improve',
    weaknessSubtitle: 'Personalized practice based on your weak areas',
    practiceWeaknessBtn: 'Practice 10 weak questions',
    noWeaknessData: 'Not enough data yet',
    noWeaknessHint: 'Complete a practice quiz or mock exam to get personalized recommendations.',
    accuracyText: _enAccuracy,
    weakTopicBadge: 'Needs review',
    topicShort: _enTopicShort,
    aiPanelTitle: 'AI explanation',
    aiFallbackLabel: 'Original explanation',
    aiQuestionRef: _enAiQuestionRef,
    aiLoading: 'Asking AI, this can take 10-60 seconds…',
    aiNoQuestion: 'No question to explain yet.',
    aiGeneratedLabel: 'AI explanation',
    aiAccessCodeTitle: 'AI access code',
    aiAccessCodeHint: 'Code provided by your team',
    aiAccessCodeButton: 'AI access code',
    aiAskAgain: 'Ask again',
    ttsListen: 'Read explanation',
    ttsStop: 'Stop reading',
    ttsAudioPermission:
        'No audio permission. Enable it in Settings to hear the explanation.',
    saveButton: 'Save',
    closeButton: 'Close',
  );

  static String _viCounter(int index, int total, int answered) =>
      'Câu $index/$total · Đã chọn $answered';
  static String _enCounter(int index, int total, int answered) =>
      'Question $index/$total · Answered $answered';
  static String _viScore(int correct, int wrong, int skipped) =>
      '$correct đúng · $wrong sai · $skipped bỏ trống';
  static String _enScore(int correct, int wrong, int skipped) =>
      '$correct correct · $wrong wrong · $skipped skipped';
  static String _viRetryWrong(int count) => 'Làm lại $count câu sai';
  static String _enRetryWrong(int count) => 'Redo $count wrong answers';
  static String _viSaveWrong(int count) => 'Lưu $count câu sai vào thẻ';
  static String _enSaveWrong(int count) => 'Save $count wrong answers as cards';
  static String _viReviewTitle(int index, int code, String status) =>
      'Câu $index [Mã #$code] · $status';
  static String _enReviewTitle(int index, int code, String status) =>
      'Question $index [#$code] · $status';
  static String _viCardCounter(int index, int total) => 'Thẻ $index/$total';
  static String _enCardCounter(int index, int total) => 'Card $index/$total';
  static String _viCardsDue(int due) => '$due thẻ đến hạn';
  static String _enCardsDue(int due) => '$due cards due';
  static String _viCardsSaved(int saved, int due) =>
      '$saved thẻ đã lưu · $due thẻ cần ôn hôm nay';
  static String _enCardsSaved(int saved, int due) =>
      '$saved cards saved · $due due today';
  static String _viBankSummary(int questions, int topics) =>
      '$questions câu song ngữ · $topics khối kiến thức';
  static String _enBankSummary(int questions, int topics) =>
      '$questions bilingual questions · $topics topics';
  static String _viCardNotFound(int code) =>
      'Không tìm thấy câu hỏi mã ID #$code';
  static String _enCardNotFound(int code) => 'Question #$code not found';
  static String _viHistoryDuration(int minutes, int seconds) =>
      minutes > 0 ? '$minutes phút $seconds giây' : '$seconds giây';
  static String _enHistoryDuration(int minutes, int seconds) =>
      minutes > 0 ? '$minutes min $seconds sec' : '$seconds sec';
  static String _viAccuracy(int percent) => '$percent% chính xác';
  static String _enAccuracy(int percent) => '$percent% accuracy';

  /// Tên khối rút gọn cho nhãn nhỏ ở panel AI, cùng thứ tự với `topicNames`.
  static String _viTopicShort(int topic) => _shortTopic(topic, const [
    'Dart căn bản',
    'Công cụ',
    'Widget',
    'Bố cục',
    'Material',
    'Thích ứng',
    'Tương tác',
    'Hình ảnh',
    'Điều hướng',
    'Hoạt ảnh',
    'Trợ năng',
    'Trạng thái',
    'Dữ liệu',
    'Kiến trúc',
    'Package',
    'Kiểm thử',
    'Hiệu năng',
    'Đa nền tảng',
    'Cấu hình',
    'AI',
  ]);

  static String _enTopicShort(int topic) => _shortTopic(topic, const [
    'Dart basics',
    'Tooling',
    'Widgets',
    'Layout',
    'Material',
    'Responsive',
    'Interaction',
    'Images',
    'Navigation',
    'Animation',
    'Accessibility',
    'State',
    'Data',
    'Architecture',
    'Packages',
    'Testing',
    'Performance',
    'Cross-platform',
    'Configuration',
    'AI',
  ]);

  static String _shortTopic(int topic, List<String> names) {
    final code = 'K${topic.toString().padLeft(2, '0')}';
    if (topic < 1 || topic > names.length) return code;
    return '$code · ${names[topic - 1]}';
  }

  static String _viAiQuestionRef(int id, String topic) => 'Câu #$id · $topic';
  static String _enAiQuestionRef(int id, String topic) =>
      'Question #$id · $topic';
}
