import 'package:flutter/material.dart';

import 'question.dart';

enum LearningTool { assistant, camera }

/// Điểm mở giao diện dành cho dịch vụ AI và camera khi tích hợp sau.
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

class LearningToolPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ai = tool == LearningTool.assistant;
    final colors = Theme.of(context).colorScheme;
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
                ai ? Icons.auto_awesome_outlined : Icons.camera_alt_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ai ? 'Gia sư AI' : 'Camera học tập',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Chip(label: Text('Sắp có')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ai
                ? 'Dự kiến giải thích câu sai, giải đáp theo chủ đề Flutter/Dart và đọc lời giải.'
                : 'Dự kiến quét mã QR và nhận câu hỏi từ ảnh chụp.',
          ),
          if (question case final current?) ...[
            const SizedBox(height: 20),
            Text(
              'Câu #${current.id} · ${topicLabel(current.topic)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(language.display(current.vi, current.en)),
          ],
          const SizedBox(height: 20),
          if (ai) ...[
            const TextField(
              enabled: false,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi hoặc hỏi bằng giọng nói',
                suffixIcon: Icon(Icons.mic_none_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Nghe lời giải'),
                ),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Gửi câu hỏi'),
                ),
              ],
            ),
          ] else ...[
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
          ],
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
}
