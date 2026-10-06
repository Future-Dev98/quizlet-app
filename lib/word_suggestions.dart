import 'models.dart';

bool matchesCard(StudyCard card, String query) {
  final normalized = normalizeAnswer(query);
  return normalized.isEmpty ||
      [
        card.term,
        card.definition,
        ...?card.details?.synonyms,
      ].any((text) => normalizeAnswer(text).contains(normalized));
}

List<StudyCard> suggestCards(
  List<StudyCard> cards,
  String query, {
  int limit = 5,
}) {
  final normalized = normalizeAnswer(query);
  if (normalized.isEmpty) return [];
  int rank(StudyCard card) {
    final term = normalizeAnswer(card.term);
    return term == normalized
        ? 0
        : term.startsWith(normalized)
        ? 1
        : term.contains(normalized)
        ? 2
        : 3;
  }

  final matches = cards.where((card) => matchesCard(card, normalized)).toList()
    ..sort((a, b) {
      final comparison = rank(a).compareTo(rank(b));
      return comparison == 0 ? a.term.compareTo(b.term) : comparison;
    });
  return matches.take(limit).toList();
}
