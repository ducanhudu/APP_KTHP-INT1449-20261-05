import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'question.dart';
import 'tts_service.dart';

enum LearningTool { assistant, camera }

/// Điểm mở giao diện AI và camera.
/// AI đã được nối thật ở Ngày 3; camera vẫn là placeholder.
Future<void> showLearningTool(
  BuildContext context,
  LearningTool tool, {
  Question? question,
  QuestionLanguage language = QuestionLanguage.vietnamese,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) =>
      LearningToolPreview(tool: tool, question: question, language: language),
);

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
        title: const Text('Mã truy cập AI / AI access code'),
        content: TextField(
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (text) => value = text,
          decoration: const InputDecoration(labelText: 'Mã do nhóm cung cấp'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: const Text('Lưu'),
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
    if (widget.tool == LearningTool.camera) return _buildCameraPreview(context);
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
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Giải thích AI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_result?.fromFallback == true)
                const Chip(label: Text('Lời giải gốc')),
            ],
          ),
          const SizedBox(height: 12),

          // ── Câu hỏi ──
          if (q != null) ...[
            Text(
              'Câu #${q.id} · ${_topicShort(q.topic)}',
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Đang hỏi AI, có thể mất 10-60 giây…'),
                ],
              ),
            )
          else if (_result != null)
            _buildExplanationCard(context)
          else ...[
            const Text('Chưa có câu hỏi để giải thích.'),
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
              child: const Text('Đóng'),
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
                    'AI giải thích',
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
            label: const Text('Mã truy cập AI'),
          ),
        // Nút TTS – ẩn nếu quyền bị từ chối
        if (!_tts.permissionDenied)
          OutlinedButton.icon(
            onPressed: _toggleTts,
            icon: Icon(playing ? Icons.stop : Icons.volume_up_outlined),
            label: Text(playing ? 'Dừng đọc' : 'Nghe lời giải'),
          ),
        // Nút hỏi lại AI
        if (widget.question != null)
          OutlinedButton.icon(
            onPressed: _loading ? null : _fetchAi,
            icon: const Icon(Icons.refresh),
            label: const Text('Hỏi lại'),
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
              'Không có quyền audio. Hãy bật trong Cài đặt để nghe giọng đọc.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera placeholder ─────────────────────────────────────────────────────

  Widget _buildCameraPreview(BuildContext context) {
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
          Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Camera học tập',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Chip(label: Text('Sắp có')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Dự kiến quét mã QR và nhận câu hỏi từ ảnh chụp.'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Quét mã QR'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Chụp câu hỏi'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tính năng đang được chuẩn bị.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  String _topicShort(int topic) {
    const names = [
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
    ];
    if (topic < 1 || topic > names.length) {
      return 'K${topic.toString().padLeft(2, '0')}';
    }
    return 'K${topic.toString().padLeft(2, '0')} · ${names[topic - 1]}';
  }
}
