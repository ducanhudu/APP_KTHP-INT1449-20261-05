import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'card_storage.dart';
import 'question.dart';
import 'question_prompt.dart';
import 'question_search.dart';
import 'study_image_service.dart';

class CameraStudyPage extends StatefulWidget {
  const CameraStudyPage({
    super.key,
    this.language = QuestionLanguage.vietnamese,
    this.imageService,
    this.questions,
    this.storage = const SharedPrefsCardStorage(),
    this.onExplain,
  });

  final QuestionLanguage language;
  final StudyImageService? imageService;
  final List<Question>? questions;
  final CardStorage storage;
  final void Function(BuildContext, Question, QuestionLanguage)? onExplain;

  @override
  State<CameraStudyPage> createState() => _CameraStudyPageState();
}

class _CameraStudyPageState extends State<CameraStudyPage> {
  late final StudyImageService _service =
      widget.imageService ?? NativeStudyImageService();
  final _text = TextEditingController();
  List<Question> _bank = [];
  List<QuestionMatch> _matches = [];
  StudyScanMode _mode = StudyScanMode.text;
  String? _path;
  String? _error;
  bool _loadingBank = true;
  bool _busy = false;
  bool _searched = false;

  String _t(String vi, String en) =>
      widget.language == QuestionLanguage.english ? en : vi;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loadingBank = true;
      _error = null;
    });
    try {
      final bank =
          widget.questions ??
          decodeQuestions(
            await rootBundle.loadString('assets/flutter_quiz_300.json'),
          );
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _loadingBank = false;
        _busy = true;
      });
      final recovered = await _service.recoverLostImage();
      if (!mounted) return;
      if (recovered == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() => _busy = true);
      try {
        await _read(recovered);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingBank = false;
        _busy = false;
        _error = _message(error);
      });
    }
  }

  String _message(Object error) {
    if (error is PlatformException &&
        error.code.toLowerCase().contains('access')) {
      return _t(
        'Chưa được phép mở camera/ảnh. Hãy cấp quyền trong Cài đặt hoặc nhập nội dung bên dưới.',
        'Camera/photos access was denied. Enable access in Settings or enter the text below.',
      );
    }
    if (error is FormatException && error.message == 'image_too_large') {
      return _t(
        'Ảnh quá lớn (tối đa 12 MB). Hãy chọn ảnh nhỏ hơn.',
        'Image exceeds 12 MB. Choose a smaller image.',
      );
    }
    return _t(
      'Không đọc được ảnh hoặc dữ liệu. Hãy thử lại, chọn ảnh khác hoặc nhập chữ bên dưới.',
      'Could not read the image or data. Retry, choose another image or enter text below.',
    );
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy || _loadingBank) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = await _service.pick(source);
      if (!mounted || path == null) {
        return; // Cancel preserves the current result.
      }
      await _read(path);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _read(String path) async {
    setState(() {
      _path = path;
      _matches = [];
      _searched = false;
      _text.clear();
    });
    final result = await _service.read(path, _mode);
    if (!mounted) return;
    if (_mode == StudyScanMode.qr) {
      final found = <int, Question>{};
      for (final code in result.codes) {
        final question = questionFromStudyQr(_bank, code);
        if (question != null) found[question.id] = question;
      }
      setState(() {
        _searched = true;
        _matches = [
          for (final question in found.values) QuestionMatch(question, 1),
        ];
        if (found.isEmpty) {
          _error = _t(
            'Không có QR hợp lệ. Dùng mã flutterlab://question/81 hoặc mã câu K##-### có trong ngân hàng.',
            'No supported QR code. Use flutterlab://question/81 or a bank reference K##-###.',
          );
        }
      });
    } else {
      setState(() {
        _text.text = result.text;
        if (result.text.trim().isEmpty) {
          _error = _t(
            'Không tìm thấy chữ. Chụp rõ, đủ sáng hoặc nhập nội dung thủ công.',
            'No text found. Use a clear, well-lit image or enter text manually.',
          );
        }
      });
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _searched = true;
      _matches = searchStudyQuestions(_bank, _text.text);
    });
  }

  Future<void> _openQuestion(Question question) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ScannedQuestionDetails(
        question: question,
        language: widget.language,
        storage: widget.storage,
        onExplain: widget.onExplain,
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || _loadingBank || _bank.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(_t('Camera học tập', 'Study camera'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            _t(
              'Đưa câu hỏi trên giấy vào buổi ôn',
              'Bring a printed question into your study session',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'Chụp hoặc chọn ảnh. Chữ và QR được xử lý trên thiết bị; ảnh không gửi lên backend AI.',
              'Take or choose a photo. Text and QR processing happens on your device; images are not sent to the AI backend.',
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<StudyScanMode>(
            segments: [
              ButtonSegment(
                value: StudyScanMode.text,
                icon: const Icon(Icons.text_fields),
                label: Text(_t('Đọc chữ', 'Read text')),
              ),
              ButtonSegment(
                value: StudyScanMode.qr,
                icon: const Icon(Icons.qr_code),
                label: Text(_t('Mã QR', 'QR code')),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: disabled
                ? null
                : (values) => setState(() {
                    _mode = values.single;
                    _text.clear();
                    _matches = [];
                    _searched = false;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: disabled ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_t('Chụp ảnh', 'Take photo')),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_t('Chọn ảnh', 'Choose photo')),
              ),
            ],
          ),
          if (_loadingBank || _busy) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              _t('Đang chuẩn bị hoặc đọc ảnh…', 'Preparing or reading image…'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (_bank.isEmpty)
              TextButton(
                onPressed: _loadingBank ? null : _initialize,
                child: Text(
                  _t('Tải lại ngân hàng câu hỏi', 'Reload question bank'),
                ),
              ),
          ],
          if (_path != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_path!),
                height: 180,
                fit: BoxFit.contain,
                semanticLabel: _t('Ảnh đã chọn', 'Selected image'),
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 40,
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ],
          if (_mode == StudyScanMode.text) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              enabled: !disabled,
              minLines: 3,
              maxLines: 7,
              maxLength: 6000,
              onChanged: (_) => setState(() {
                _searched = false;
                _matches = [];
              }),
              decoration: InputDecoration(
                labelText: _t('Nội dung câu hỏi', 'Question text'),
                hintText: _t(
                  'Sửa chữ nhận diện hoặc nhập câu hỏi tại đây',
                  'Correct the recognized text or type a question',
                ),
                helperText: _t(
                  'Kiểm tra nội dung trước khi tìm. Không tự gửi lên AI.',
                  'Review before searching. Nothing is automatically sent to AI.',
                ),
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: disabled || _text.text.trim().isEmpty ? null : _search,
              icon: const Icon(Icons.search),
              label: Text(_t('Tìm trong 300 câu', 'Search 300 questions')),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              _t(
                'Chụp rõ mã QR hoặc chọn ảnh chứa QR. Chỉ mở câu có trong ngân hàng, không mở website bên ngoài.',
                'Photograph a QR or choose a QR image. Only questions in the bank are opened, never external websites.',
              ),
            ),
          ],
          if (_searched) ...[
            const SizedBox(height: 24),
            Text(
              _t('Câu hỏi gợi ý', 'Suggested questions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _t(
                    'Chưa tìm thấy câu phù hợp. Thử sửa nội dung hoặc dùng ít từ khóa hơn.',
                    'No matching questions. Edit the text or use fewer keywords.',
                  ),
                ),
              ),
            for (final match in _matches)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    widget.language.display(
                      match.question.vi,
                      match.question.en,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${match.question.referenceCode} · #${match.question.id}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openQuestion(match.question),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ScannedQuestionDetails extends StatefulWidget {
  const _ScannedQuestionDetails({
    required this.question,
    required this.language,
    required this.storage,
    this.onExplain,
  });
  final Question question;
  final QuestionLanguage language;
  final CardStorage storage;
  final void Function(BuildContext, Question, QuestionLanguage)? onExplain;
  @override
  State<_ScannedQuestionDetails> createState() =>
      _ScannedQuestionDetailsState();
}

class _ScannedQuestionDetailsState extends State<_ScannedQuestionDetails> {
  bool _saving = false;
  String? _message;
  String _t(String vi, String en) =>
      widget.language == QuestionLanguage.english ? en : vi;
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final count = await widget.storage.addCards([widget.question.id]);
      if (!mounted) return;
      setState(
        () => _message = count == 0
            ? _t('Thẻ đã có trong bộ ôn.', 'Already in your deck.')
            : _t('Đã lưu vào bộ thẻ.', 'Saved to your deck.'),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = _t(
            'Chưa lưu được. Hãy thử lại.',
            'Could not save. Please retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${q.referenceCode} · #${q.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          QuestionPrompt(question: q, language: widget.language),
          const SizedBox(height: 12),
          for (final choice in q.choices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                choice.id == q.correctId
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
              title: Text(
                '${choice.id}. ${widget.language.display(choice.vi, choice.en)}',
              ),
            ),
          Text(
            _t('Đáp án đúng: ${q.correctId}', 'Correct answer: ${q.correctId}'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(widget.language.display(q.explanationVi, q.explanationEn)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(_t('Lưu thẻ ôn', 'Save study card')),
              ),
              if (widget.onExplain != null)
                OutlinedButton.icon(
                  onPressed: () =>
                      widget.onExplain!(context, q, widget.language),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    _t('Hỏi AI về câu này', 'Ask AI about this question'),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t('Đóng', 'Close')),
              ),
            ],
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }
}
