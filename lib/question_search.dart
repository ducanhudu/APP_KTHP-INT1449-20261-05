import 'question.dart';

/// Normalize OCR text without requiring accents or punctuation to match.
String normalizeStudyText(String value) {
  var text = value.toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final rune in entry.value.runes) {
      text = text.replaceAll(String.fromCharCode(rune), entry.key);
    }
  }
  return text
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'[^a-z0-9_]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

const _stopWords = {
  'the',
  'a',
  'an',
  'is',
  'of',
  'to',
  'in',
  'and',
  'which',
  'what',
  'la',
  'va',
  'cua',
  'trong',
  'nao',
  'mot',
  'cac',
  'cho',
  'voi',
  'khi',
};

Set<String> _tokens(String value) =>
    normalizeStudyText(value)
        .split(' ')
        .where((word) => word.isNotEmpty && !_stopWords.contains(word))
        .toSet();

class QuestionMatch {
  const QuestionMatch(this.question, this.score);
  final Question question;

  /// Search relevance, not OCR confidence or answer correctness.
  final double score;
}

List<QuestionMatch> searchStudyQuestions(
  Iterable<Question> bank,
  String query, {
  int limit = 5,
}) {
  if (limit <= 0) return [];
  final normalized = normalizeStudyText(query);
  final tokens = _tokens(query);
  if (tokens.isEmpty) return [];
  final matches = <QuestionMatch>[];
  for (final q in bank) {
    var best = 0.0;
    for (final prompt in [q.vi, q.en]) {
      final text = normalizeStudyText(prompt);
      if (text.length >= 15 && normalized.contains(text)) {
        best = 1;
        break;
      }
      final words = _tokens('$prompt ${q.code}');
      final overlap = tokens.intersection(words).length;
      if (overlap == 0 || (tokens.length > 2 && overlap < 2)) continue;
      final score =
          0.7 * overlap / tokens.length +
          0.3 * overlap / (words.isEmpty ? 1 : words.length);
      if (score > best) best = score;
    }
    if (best >= 0.2) matches.add(QuestionMatch(q, best));
  }
  matches.sort((a, b) {
    final order = b.score.compareTo(a.score);
    return order == 0 ? a.question.id.compareTo(b.question.id) : order;
  });
  return matches.take(limit).toList();
}

/// Accept only the app's documented QR format or an exact bank reference code.
Question? questionFromStudyQr(Iterable<Question> bank, String value) {
  final raw = value.trim();
  final uri = Uri.tryParse(raw);
  int? id;
  if (uri != null &&
      uri.scheme == 'flutterlab' &&
      uri.host == 'question' &&
      uri.userInfo.isEmpty &&
      !uri.hasPort &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      uri.pathSegments.length == 1 &&
      RegExp(r'^\d+$').hasMatch(uri.pathSegments.single)) {
    id = int.tryParse(uri.pathSegments.single);
  }
  for (final question in bank) {
    if (id != null && question.id == id) return question;
    if (RegExp(r'^K\d{2}-\d{3}$').hasMatch(raw) &&
        question.referenceCode == raw) {
      return question;
    }
  }
  return null;
}
