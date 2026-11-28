import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'ask_ai_page.dart';
import 'app_strings.dart';
import 'camera_study_page.dart';
import 'card_storage.dart';
import 'question.dart';
import 'tts_service.dart';

enum LearningTool { assistant, askAi, camera }

/// Điểm mở giao diện AI và camera.
/// AI giải thích theo câu hỏi; camera mở luồng nhận diện ảnh và QR.
Future<void> showLearningTool(
  BuildContext context,
  LearningTool tool, {
  Question? question,
  QuestionLanguage language = QuestionLanguage.vietnamese,
  CardStorage storage = const SharedPrefsCardStorage(),
}) async {
  if (tool == LearningTool.askAi) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AskAiPage(language: language)),
    );
    return;
  }
  if (tool == LearningTool.camera) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CameraStudyPage(
          language: language,
          storage: storage,
          onExplain: (context, question, language) => showLearningTool(
            context,
            LearningTool.assistant,
            question: question,
            language: language,
          ),
        ),
      ),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        LearningToolPreview(tool: tool, question: question, language: language),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Panel
// ─────────────────────────────────────────────────────────────────────────────

class LearningToolPreview extends StatefulWidget {
  const LearningToolPreview({
    super.key,
    required this.tool,
    this.question,
    this.language = QuestionLanguage.vietnamese,
  });

  final LearningTool tool;
  final Question? question;
  final QuestionLanguage language;

  @override
  State<LearningToolPreview> createState() => _LearningToolPreviewState();
}

class _LearningToolPreviewState extends State<LearningToolPreview> {
  final TtsService _tts = TtsService();
  TtsState _ttsState = TtsState.stopped;

  AiResult? _result;
  bool _loading = false;

  /// Nhãn giao diện theo ngôn ngữ đang chọn; nội dung câu hỏi đã song ngữ sẵn.
  AppStrings get s => AppStrings.of(widget.language);

  @override
  void initState() {
    super.initState();
    _tts.onStateChanged.listen((s) {
      if (mounted) setState(() => _ttsState = s);
    });
    // Auto-fetch khi mở panel với câu hỏi cụ thể
    if (widget.tool == LearningTool.assistant && widget.question != null) {
      _fetchAi();
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _fetchAi() async {
    if (widget.question == null) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final r = await AiService.explain(
      question: widget.question!,
      language: widget.language,
    );
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  Future<void> _toggleTts() async {
    final text = _result?.text;
    if (text == null) return;
    if (_ttsState == TtsState.playing) {
      await _tts.stop();
    } else {
      await _tts.speak(text, language: widget.language);
    }
  }

  Future<void> _enterAccessCode() async {
    var value = '';
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.aiAccessCodeTitle),
        content: TextField(
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (text) => value = text,
          decoration: InputDecoration(labelText: s.aiAccessCodeHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: Text(s.saveButton),
          ),
        ],
      ),
    );
    if (!mounted || code == null) return;
    AiService.accessCode = code;
    await _fetchAi();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAiPanel(context);
  }

  // ── AI Panel ───────────────────────────────────────────────────────────────

  Widget _buildAiPanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final q = widget.question;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ──
          // Dùng Wrap thay Row: nhãn "Original explanation" dài hơn bản tiếng
          // Việt và làm tràn hàng trên máy hẹp 320 px.
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: colors.primary),
              Text(
                s.aiPanelTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_result?.fromFallback == true)
                Chip(label: Text(s.aiFallbackLabel)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Câu hỏi ──
          if (q != null) ...[
            Text(
              s.aiQuestionRef(q.id, s.topicShort(q.topic)),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              widget.language.display(q.vi, q.en),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
          ],

          // ── Nội dung giải thích ──
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(s.aiLoading),
                ],
              ),
            )
          else if (_result != null)
            _buildExplanationCard(context)
          else ...[
            Text(s.aiNoQuestion),
            const SizedBox(height: 8),
          ],

          // ── Nút thao tác ──
          const SizedBox(height: 12),
          if (_result != null) _buildActionRow(context),
          if (_tts.permissionDenied) _buildPermissionWarning(context),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.closeButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    final result = _result!;
    return Card(
      color: result.fromFallback
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!result.fromFallback)
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.aiGeneratedLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            if (!result.fromFallback) const SizedBox(height: 8),
            Text(result.text),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final playing = _ttsState == TtsState.playing;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (AiService.isConfigured)
          OutlinedButton.icon(
            onPressed: _loading ? null : _enterAccessCode,
            icon: const Icon(Icons.key),
            label: Text(s.aiAccessCodeButton),
          ),
        // Nút TTS – ẩn nếu quyền bị từ chối
        if (!_tts.permissionDenied)
          OutlinedButton.icon(
            onPressed: _toggleTts,
            icon: Icon(playing ? Icons.stop : Icons.volume_up_outlined),
            label: Text(playing ? s.ttsStop : s.ttsListen),
          ),
        // Nút hỏi lại AI
        if (widget.question != null)
          OutlinedButton.icon(
            onPressed: _loading ? null : _fetchAi,
            icon: const Icon(Icons.refresh),
            label: Text(s.aiAskAgain),
          ),
      ],
    );
  }

  Widget _buildPermissionWarning(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.mic_off, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.ttsAudioPermission,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
