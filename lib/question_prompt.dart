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
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontSize: 20, height: 1.5),
      ),
      if (question.code.isNotEmpty)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              question.code,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onInverseSurface,
                height: 1.6,
              ),
            ),
          ),
        ),
    ],
  );
}
