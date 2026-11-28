import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'app_strings.dart';
import 'question.dart';

typedef AiQuestionSender = Future<AiResult?> Function(
  String question,
  QuestionLanguage language,
);

/// Single-turn, open-ended AI tutor for study questions.
class AskAiPage extends StatefulWidget {
  const AskAiPage({super.key, required this.language, this.sender});

  final QuestionLanguage language;
  final AiQuestionSender? sender;

  @override
  State<AskAiPage> createState() => _AskAiPageState();
}

class _AskAiPageState extends State<AskAiPage> {
  final TextEditingController _question = TextEditingController();
  AppStrings get s => AppStrings.of(widget.language);

  AiResult? _answer;
  String? _error;
  String? _answeredQuestion;
  bool _loading = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _question.text.trim();
    if (text.isEmpty || _loading) return;
    if (text.length > AiService.maxAskLength) {
      setState(() => _error = s.aiAskTooLong);
      return;
    }
    if (widget.sender == null && !AiService.isAskConfigured) {
      setState(() => _error = s.aiAskNotConfigured);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
      _answeredQuestion = text;
    });
    AiResult? result;
    try {
      result =
          await (widget.sender?.call(text, widget.language) ??
              AiService.ask(question: text, language: widget.language));
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _answer = result;
      _error = result == null ? s.aiAskFailed : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.aiAskPageTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.aiAskDescription, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _question,
                minLines: 2,
                maxLines: 5,
                maxLength: AiService.maxAskLength,
                textInputAction: TextInputAction.send,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: s.aiAskInputLabel,
                  hintText: s.aiAskInputHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loading || _question.text.trim().isEmpty
                    ? null
                    : _submit,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_loading ? s.aiAskLoading : s.aiAskButton),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              if (_answer != null) ...[
                const SizedBox(height: 20),
                Text(s.aiAskAnswerTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_answeredQuestion != null) ...[
                          Text(
                            _answeredQuestion!,
                            style: theme.textTheme.labelLarge,
                          ),
                          const Divider(height: 24),
                        ],
                        Text(_answer!.text),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
