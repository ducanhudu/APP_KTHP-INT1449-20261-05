import 'package:flutter/material.dart';

import 'question.dart';

/// Hiển thị nội dung câu hỏi song ngữ kèm đoạn mã code snippet (nếu có).
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
