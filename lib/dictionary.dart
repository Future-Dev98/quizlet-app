import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

abstract class WordDictionary {
  Future<WordDetails?> lookup(String term, String language);
}

/// Retrieves only the selected language's entry, never other-language sections.
class WiktionaryDictionary implements WordDictionary {
  WiktionaryDictionary({this.client});
  final http.Client? client;
  static const languages = {
    'ko': 'Korean',
    'vi': 'Vietnamese',
    'en': 'English',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
  };

  @override
  Future<WordDetails?> lookup(String term, String language) async {
    final code = language.split('-').first;
    if (!languages.containsKey(code)) return null;
    final uri = Uri.https('en.wiktionary.org', '/w/api.php', {
      'action': 'parse',
      'page': term.trim(),
      'prop': 'text',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'disableeditsection': '1',
    });
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(
            uri,
            headers: {
              'User-Agent': 'VocabularyStudyApp/1.0 (Flutter; word lookup)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException('Dictionary unavailable');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['error']?['code'] == 'missingtitle') return null;
      if (data['parse']?['text'] is! String) {
        throw const FormatException('Invalid dictionary response');
      }
      return parseEntry(data['parse']['text'] as String, term, code);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static WordDetails? parseEntry(String markup, String term, String code) {
    final document = html.parse(markup);
    final root = document.querySelector('.mw-parser-output') ?? document.body;
    if (root == null || !languages.containsKey(code)) return null;
    final section = Element.tag('div');
    bool active = false;
    for (final child in root.children) {
      final heading = child.localName == 'h2'
          ? child
          : child.querySelector('h2');
      if (heading != null) {
        if (active) break;
        active = heading.id == languages[code];
      } else if (active) {
        section.append(child.clone(true));
      }
    }
    if (!active) return null;
    String clean(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
    List<String> unique(Iterable<String> values, int limit) => values
        .map(clean)
        .where((v) => v.isNotEmpty)
        .toSet()
        .take(limit)
        .toList();
    final definitions = <String>[];
    final usage = <String>[];
    final synonyms = <String>[];
    final examples = <String>[];
    const wordTypes = {
      'Noun',
      'Verb',
      'Adjective',
      'Adverb',
      'Pronoun',
      'Particle',
      'Interjection',
      'Proper noun',
      'Determiner',
      'Preposition',
      'Conjunction',
      'Phrase',
      'Idiom',
      'Proverb',
      'Numeral',
    };
    String subsection = '';
    for (final child in section.children) {
      final heading = RegExp(r'^h[3-6]$').hasMatch(child.localName ?? '')
          ? child
          : child.querySelector('h3, h4, h5, h6');
      if (heading != null) {
        subsection = clean(heading.text.replaceAll('[edit]', ''));
        continue;
      }
      if (subsection == 'Usage notes' &&
          ['p', 'ul', 'ol', 'dl'].contains(child.localName)) {
        usage.add(child.text);
      }
      if (subsection == 'Synonyms') {
        synonyms.addAll(
          child
              .querySelectorAll(
                '[lang="$code"] a, a[href*="#${languages[code]}"]',
              )
              .where((e) => !(e.attributes['title'] ?? '').contains(':'))
              .map((e) => e.text),
        );
      }
      if (wordTypes.contains(subsection) && child.localName == 'ol') {
        for (final sense in child.children.where((e) => e.localName == 'li')) {
          final copy = sense.clone(true);
          for (final extra in copy.querySelectorAll(
            'dl, ul, ol, .synonym, .HQToggle, .citation-whole',
          )) {
            extra.remove();
          }
          definitions.add('$subsection: ${clean(copy.text)}');
        }
      }
    }
    synonyms.addAll(
      section
          .querySelectorAll(
            '.synonym [lang="$code"] a, .synonyms [lang="$code"] a',
          )
          .map((e) => e.text),
    );
    for (final example in section.querySelectorAll(
      '.h-usage-example, .usage-example, .usex, .ux',
    )) {
      final sentence = example.querySelector('[lang="$code"]');
      if (sentence == null) continue;
      final translation = example.querySelector('.e-translation');
      examples.add(
        '${sentence.text}${translation == null ? '' : '\n${translation.text}'}',
      );
    }
    final result = WordDetails(
      language: code,
      sourceUrl: Uri.https(
        'en.wiktionary.org',
        '/wiki/$term',
        null,
      ).replace(fragment: languages[code]).toString(),
      fetchedAt: DateTime.now().toUtc().toIso8601String(),
      definitions: unique(definitions, 8),
      usage: unique(usage, 6),
      examples: unique(examples, 8),
      synonyms: unique(
        synonyms.where((s) => normalizeAnswer(s) != normalizeAnswer(term)),
        20,
      ),
    );
    return result.isEmpty ? null : result;
  }
}

/// Bounded workers avoid flooding the dictionary when importing a large set.
Future<int> enrichCards(
  List<StudyCard> cards,
  WordDictionary dictionary,
  String language, {
  void Function(int done, int total)? onProgress,
  bool Function()? shouldContinue,
}) async {
  var cursor = 0, done = 0, missing = 0;
  Future<void> worker() async {
    while (cursor < cards.length && (shouldContinue?.call() ?? true)) {
      final card = cards[cursor++];
      try {
        final result = await dictionary.lookup(card.term, language);
        if (!(shouldContinue?.call() ?? true)) return;
        if (result == null) {
          missing++;
        } else {
          card.details = result;
        }
      } catch (_) {
        missing++;
      }
      done++;
      onProgress?.call(done, cards.length);
    }
  }

  await Future.wait(List.generate(cards.length.clamp(0, 3), (_) => worker()));
  return missing;
}
