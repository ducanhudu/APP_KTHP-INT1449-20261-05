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
    required this.aiOpenQuestionTitle,
    required this.aiOpenQuestionSubtitle,
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
    required this.statisticsTitle,
    required this.statisticsSummary,
    required this.statisticsAttempts,
    required this.statisticsQuestions,
    required this.statisticsAverage,
    required this.statisticsAnswerBreakdown,
    required this.statisticsTrend,
    required this.statisticsTrendSubtitle,
    required this.statisticsByTopic,
    required this.statisticsEmpty,
    required this.statisticsTopicsUnavailable,
    required this.statisticsTopicBreakdown,
    required this.homeStatisticsTitle,
    required this.homeStatisticsSubtitle,
    required this.weaknessHeading,
    required this.weaknessSubtitle,
    required this.practiceWeaknessBtn,
    required this.noWeaknessData,
    required this.noWeaknessHint,
    required this.noWeaknessFound,
    required this.loadingWeakness,
    required this.errorWeaknessCardsLoad,
    required this.accuracyText,
    required this.dueCardsCount,
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
    required this.aiTutorPickTitle,
    required this.aiTutorNoHistory,
    required this.aiAskPageTitle,
    required this.aiAskDescription,
    required this.aiAskInputLabel,
    required this.aiAskInputHint,
    required this.aiAskButton,
    required this.aiAskLoading,
    required this.aiAskAnswerTitle,
    required this.aiAskFailed,
    required this.aiAskNotConfigured,
    required this.aiAskNeedAccessCode,
    required this.aiAskTooLong,
    required this.accountTooltip,
    required this.signInTitle,
    required this.signInSubtitle,
    required this.registerTitle,
    required this.registerSubtitle,
    required this.nameLabel,
    required this.emailLabel,
    required this.passwordLabel,
    required this.confirmPasswordLabel,
    required this.rememberMe,
    required this.signInButton,
    required this.signUpButton,
    required this.continueWithGoogle,
    required this.showPassword,
    required this.hidePassword,
    required this.noAccount,
    required this.haveAccount,
    required this.signUpLink,
    required this.signInLink,
    required this.emailRequired,
    required this.emailInvalid,
    required this.nameRequired,
    required this.passwordRequired,
    required this.passwordTooShort,
    required this.passwordMismatch,
    required this.demoHintTitle,
    required this.demoHintBody,
    required this.authInvalidCredentials,
    required this.authEmailInUse,
    required this.authGoogleNotConfigured,
    required this.authDisabled,
    required this.authUnknown,
    required this.registerSuccess,
    required this.registerFailed,
    required this.signInFailed,
    required this.profileTitle,
    required this.memberSince,
    required this.editName,
    required this.editAvatar,
    required this.removeAvatar,
    required this.logout,
    required this.demoBadge,
    required this.demoBadgeNote,
    required this.profileNameSaved,
    required this.avatarPickFailed,
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
  final String aiOpenQuestionTitle;
  final String aiOpenQuestionSubtitle;
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
  final String statisticsTitle;
  final String statisticsSummary;
  final String statisticsAttempts;
  final String statisticsQuestions;
  final String statisticsAverage;
  final String Function(int correct, int wrong, int skipped)
  statisticsAnswerBreakdown;
  final String statisticsTrend;
  final String statisticsTrendSubtitle;
  final String statisticsByTopic;
  final String statisticsEmpty;
  final String statisticsTopicsUnavailable;
  final String Function(int correct, int total, int wrong, int skipped)
  statisticsTopicBreakdown;
  final String homeStatisticsTitle;
  final String homeStatisticsSubtitle;
  final String weaknessHeading;
  final String weaknessSubtitle;
  final String practiceWeaknessBtn;
  final String noWeaknessData;
  final String noWeaknessHint;
  final String noWeaknessFound;
  final String loadingWeakness;
  final String errorWeaknessCardsLoad;
  final String Function(int percent) accuracyText;
  final String Function(int count) dueCardsCount;
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
  final String aiTutorPickTitle;
  final String aiTutorNoHistory;
  final String aiAskPageTitle;
  final String aiAskDescription;
  final String aiAskInputLabel;
  final String aiAskInputHint;
  final String aiAskButton;
  final String aiAskLoading;
  final String aiAskAnswerTitle;
  final String aiAskFailed;
  final String aiAskNotConfigured;
  final String aiAskNeedAccessCode;
  final String aiAskTooLong;

  final String accountTooltip;
  final String signInTitle;
  final String signInSubtitle;
  final String registerTitle;
  final String registerSubtitle;
  final String nameLabel;
  final String emailLabel;
  final String passwordLabel;
  final String confirmPasswordLabel;
  final String rememberMe;
  final String signInButton;
  final String signUpButton;
  final String continueWithGoogle;
  final String showPassword;
  final String hidePassword;
  final String noAccount;
  final String haveAccount;
  final String signUpLink;
  final String signInLink;
  final String emailRequired;
  final String emailInvalid;
  final String nameRequired;
  final String passwordRequired;
  final String passwordTooShort;
  final String passwordMismatch;
  final String demoHintTitle;
  final String Function(String email, String password) demoHintBody;
  final String authInvalidCredentials;
  final String authEmailInUse;
  final String authGoogleNotConfigured;
  final String authDisabled;
  final String authUnknown;
  final String registerSuccess;
  final String registerFailed;
  final String signInFailed;
  final String profileTitle;
  final String memberSince;
  final String editName;
  final String editAvatar;
  final String removeAvatar;
  final String logout;
  final String demoBadge;
  final String demoBadgeNote;
  final String profileNameSaved;
  final String avatarPickFailed;

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
    aiOpenQuestionTitle: 'Hỏi AI tự do',
    aiOpenQuestionSubtitle:
        'Đặt câu hỏi bất kỳ về Flutter, Dart hoặc lập trình',
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
    statisticsTitle: 'Thống kê tiến độ',
    statisticsSummary: 'Tổng quan học tập',
    statisticsAttempts: 'lượt làm',
    statisticsQuestions: 'câu đã làm',
    statisticsAverage: 'điểm trung bình',
    statisticsAnswerBreakdown: _viStatisticsAnswerBreakdown,
    statisticsTrend: 'Điểm 7 lượt gần nhất',
    statisticsTrendSubtitle: 'Theo dõi kết quả qua từng bài làm.',
    statisticsByTopic: 'Kết quả theo chủ đề',
    statisticsEmpty:
        'Chưa có dữ liệu. Hãy hoàn thành một bài luyện tập để xem tiến độ.',
    statisticsTopicsUnavailable:
        'Chưa có dữ liệu câu hỏi để thống kê theo chủ đề.',
    statisticsTopicBreakdown: _viStatisticsTopicBreakdown,
    homeStatisticsTitle: 'Thống kê tiến độ',
    homeStatisticsSubtitle: 'Xem điểm số theo thời gian và chủ đề',
    weaknessHeading: 'Khối cần cải thiện',
    weaknessSubtitle: 'Gợi ý luyện tập theo điểm yếu từ các bài làm của bạn',
    practiceWeaknessBtn: 'Luyện 10 câu điểm yếu',
    noWeaknessData: 'Chưa đủ dữ liệu điểm yếu',
    noWeaknessHint: 'Hãy hoàn thành một bài luyện tập hoặc thi thử để hệ thống gợi ý khối yếu cho bạn.',
    noWeaknessFound:
        'Phong độ rất tốt! Hiện chưa ghi nhận khối kiến thức nào cần củng cố.',
    loadingWeakness: 'Đang tải dữ liệu để phân tích điểm yếu…',
    errorWeaknessCardsLoad:
        'Chưa đọc được bộ thẻ để phân tích điểm yếu. Hãy thử lại.',
    accuracyText: _viAccuracy,
    dueCardsCount: _viDueCardsCount,
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
    aiTutorPickTitle: 'Chọn câu để hỏi AI',
    aiTutorNoHistory:
        'Chưa có câu nào làm sai để hỏi AI. Hãy làm một lượt luyện tập trước.',
    aiAskPageTitle: 'Hỏi AI',
    aiAskDescription: 'Đặt câu hỏi tự do để được giải thích ngắn gọn về Flutter, Dart hoặc lập trình.',
    aiAskInputLabel: 'Câu hỏi của bạn',
    aiAskInputHint: 'Ví dụ: Flutter là gì?',
    aiAskButton: 'Gửi câu hỏi',
    aiAskLoading: 'Đang tìm câu trả lời…',
    aiAskAnswerTitle: 'Câu trả lời',
    aiAskFailed: 'AI chưa trả lời được. Kiểm tra kết nối hoặc thử lại sau.',
    aiAskNotConfigured: 'Tính năng AI chưa được cấu hình cho ứng dụng này.',
    aiAskNeedAccessCode: 'Cần nhập mã truy cập để gửi câu hỏi cho AI.',
    aiAskTooLong: 'Câu hỏi quá dài. Hãy giữ trong giới hạn 500 ký tự.',
    accountTooltip: 'Tài khoản',
    signInTitle: 'Đăng nhập',
    signInSubtitle: 'Đăng nhập để xem và chỉnh sửa hồ sơ thành viên.',
    registerTitle: 'Đăng ký',
    registerSubtitle: 'Tạo tài khoản để lưu hồ sơ thành viên.',
    nameLabel: 'Họ tên',
    emailLabel: 'Email',
    passwordLabel: 'Mật khẩu',
    confirmPasswordLabel: 'Xác nhận mật khẩu',
    rememberMe: 'Ghi nhớ đăng nhập',
    signInButton: 'Đăng nhập',
    signUpButton: 'Đăng ký',
    continueWithGoogle: 'Tiếp tục với Google',
    showPassword: 'Hiện mật khẩu',
    hidePassword: 'Ẩn mật khẩu',
    noAccount: 'Chưa có tài khoản?',
    haveAccount: 'Đã có tài khoản?',
    signUpLink: 'Đăng ký',
    signInLink: 'Đăng nhập',
    emailRequired: 'Vui lòng nhập email.',
    emailInvalid: 'Email không hợp lệ.',
    nameRequired: 'Vui lòng nhập họ tên.',
    passwordRequired: 'Vui lòng nhập mật khẩu.',
    passwordTooShort: 'Mật khẩu phải có ít nhất 8 ký tự.',
    passwordMismatch: 'Mật khẩu xác nhận không khớp.',
    demoHintTitle: 'Tài khoản mẫu (chỉ dùng khi chạy demo)',
    demoHintBody: _viDemoHintBody,
    authInvalidCredentials: 'Email hoặc mật khẩu không đúng.',
    authEmailInUse: 'Email này đã được đăng ký.',
    authGoogleNotConfigured: 'Đăng nhập Google chưa được cấu hình. Hãy cấu hình Google OAuth (Client ID) để dùng tính năng này.',
    authDisabled: 'Chức năng đăng nhập chưa khả dụng trong chế độ này.',
    authUnknown: 'Có lỗi xảy ra. Vui lòng thử lại.',
    registerSuccess: 'Đăng ký thành công!',
    registerFailed: 'Đăng ký thất bại. Vui lòng thử lại.',
    signInFailed: 'Đăng nhập thất bại. Vui lòng thử lại.',
    profileTitle: 'Thông tin thành viên',
    memberSince: 'Ngày tham gia',
    editName: 'Sửa họ tên',
    editAvatar: 'Đổi ảnh đại diện',
    removeAvatar: 'Xoá ảnh đại diện',
    logout: 'Đăng xuất',
    demoBadge: 'Tài khoản mẫu',
    demoBadgeNote: 'Đây là tài khoản mẫu, chỉ dùng khi chạy chế độ demo. Xác thực được mô phỏng trên thiết bị và không dùng cho môi trường thật.',
    profileNameSaved: 'Đã cập nhật hồ sơ.',
    avatarPickFailed: 'Không đọc được ảnh. Thử lại sau.',
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
    aiOpenQuestionTitle: 'Ask AI anything',
    aiOpenQuestionSubtitle: 'Ask about Flutter, Dart, or programming',
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
    statisticsTitle: 'Study progress',
    statisticsSummary: 'Learning summary',
    statisticsAttempts: 'attempts',
    statisticsQuestions: 'questions',
    statisticsAverage: 'average score',
    statisticsAnswerBreakdown: _enStatisticsAnswerBreakdown,
    statisticsTrend: 'Scores from your last 7 attempts',
    statisticsTrendSubtitle: 'Track your results across completed quizzes.',
    statisticsByTopic: 'Results by topic',
    statisticsEmpty:
        'No data yet. Complete a practice quiz to see your progress.',
    statisticsTopicsUnavailable:
        'No question details are available for topic statistics.',
    statisticsTopicBreakdown: _enStatisticsTopicBreakdown,
    homeStatisticsTitle: 'Study progress',
    homeStatisticsSubtitle: 'View scores over time and by topic',
    weaknessHeading: 'Areas to improve',
    weaknessSubtitle: 'Personalized practice based on your weak areas',
    practiceWeaknessBtn: 'Practice 10 weak questions',
    noWeaknessData: 'Not enough data yet',
    noWeaknessHint: 'Complete a practice quiz or mock exam to get personalized recommendations.',
    noWeaknessFound: 'Great job! No weak topics detected so far.',
    loadingWeakness: 'Loading data to assess your weak areas…',
    errorWeaknessCardsLoad:
        'Could not load your cards to assess weak areas. Please try again.',
    accuracyText: _enAccuracy,
    dueCardsCount: _enDueCardsCount,
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
    aiTutorPickTitle: 'Pick a question to ask AI',
    aiTutorNoHistory: 'No wrong answers yet. Finish a practice round first.',
    aiAskPageTitle: 'Ask AI',
    aiAskDescription: 'Ask an open question for a concise explanation about Flutter, Dart, or programming.',
    aiAskInputLabel: 'Your question',
    aiAskInputHint: 'For example: What is Flutter?',
    aiAskButton: 'Ask question',
    aiAskLoading: 'Getting an answer…',
    aiAskAnswerTitle: 'Answer',
    aiAskFailed:
        'AI could not answer. Check your connection or try again later.',
    aiAskNotConfigured: 'AI is not configured for this app.',
    aiAskNeedAccessCode: 'Enter the access code to ask AI.',
    aiAskTooLong: 'Question is too long. Keep it within 500 characters.',
    accountTooltip: 'Account',
    signInTitle: 'Sign in',
    signInSubtitle: 'Sign in to view and edit your member profile.',
    registerTitle: 'Sign up',
    registerSubtitle: 'Create an account to keep your member profile.',
    nameLabel: 'Full name',
    emailLabel: 'Email',
    passwordLabel: 'Password',
    confirmPasswordLabel: 'Confirm password',
    rememberMe: 'Remember me',
    signInButton: 'Sign in',
    signUpButton: 'Sign up',
    continueWithGoogle: 'Continue with Google',
    showPassword: 'Show password',
    hidePassword: 'Hide password',
    noAccount: "Don't have an account?",
    haveAccount: 'Already have an account?',
    signUpLink: 'Sign up',
    signInLink: 'Sign in',
    emailRequired: 'Please enter your email.',
    emailInvalid: 'Please enter a valid email address.',
    nameRequired: 'Please enter your full name.',
    passwordRequired: 'Please enter your password.',
    passwordTooShort: 'Password must be at least 8 characters.',
    passwordMismatch: 'Passwords do not match.',
    demoHintTitle: 'Demo account (demo mode only)',
    demoHintBody: _enDemoHintBody,
    authInvalidCredentials: 'Incorrect email or password.',
    authEmailInUse: 'This email is already registered.',
    authGoogleNotConfigured: 'Google sign-in is not configured yet. Configure Google OAuth (Client ID) to enable it.',
    authDisabled: 'Sign-in is not available in this mode.',
    authUnknown: 'Something went wrong. Please try again.',
    registerSuccess: 'Registration successful!',
    registerFailed: 'Registration failed. Please try again.',
    signInFailed: 'Sign-in failed. Please try again.',
    profileTitle: 'Member profile',
    memberSince: 'Member since',
    editName: 'Edit name',
    editAvatar: 'Change avatar',
    removeAvatar: 'Remove avatar',
    logout: 'Sign out',
    demoBadge: 'Demo account',
    demoBadgeNote: 'This is a demo account for demo mode only. Authentication is simulated on-device and is not for production use.',
    profileNameSaved: 'Profile updated.',
    avatarPickFailed: 'Could not read the image. Try again later.',
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
  static String _viStatisticsAnswerBreakdown(
    int correct,
    int wrong,
    int skipped,
  ) => '$correct đúng · $wrong sai · $skipped bỏ trống';
  static String _viStatisticsTopicBreakdown(
    int correct,
    int total,
    int wrong,
    int skipped,
  ) => '$correct/$total đúng · $wrong sai · $skipped bỏ trống';
  static String _enStatisticsTopicBreakdown(
    int correct,
    int total,
    int wrong,
    int skipped,
  ) => '$correct/$total correct · $wrong wrong · $skipped skipped';
  static String _enStatisticsAnswerBreakdown(
    int correct,
    int wrong,
    int skipped,
  ) => '$correct correct · $wrong wrong · $skipped skipped';
  static String _viAccuracy(int percent) => '$percent% chính xác';
  static String _enAccuracy(int percent) => '$percent% accuracy';
  static String _viDueCardsCount(int count) => '$count thẻ đến hạn cần ôn';
  static String _enDueCardsCount(int count) => '$count cards due for review';

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

  static String _viDemoHintBody(String email, String password) =>
      'Email: $email\nMật khẩu: $password\nĐây là xác thực mô phỏng, chỉ để '
      'chạy thử, không dùng cho môi trường thật.';
  static String _enDemoHintBody(String email, String password) =>
      'Email: $email\nPassword: $password\nThis is simulated authentication '
      'for demo use only — not for production.';
}
