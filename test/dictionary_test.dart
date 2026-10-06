import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/main.dart';
import 'package:my_app/models.dart';
import 'package:my_app/storage.dart';
import 'package:my_app/dictionary.dart';
import 'package:my_app/card_details.dart';
import 'package:my_app/app_localization.dart';
import 'package:my_app/word_suggestions.dart';

const markup = '''<div class="mw-parser-output">
<div class="mw-heading"><h2 id="English">English</h2></div>
<div class="mw-heading"><h3>Adjective</h3></div>
<ol><li>Feeling joy.<dl><dd><span class="h-usage-example"><i lang="en">I am happy.</i></span></dd></dl>
<span class="synonym"><span lang="en"><a>glad</a></span></span></li></ol>
<div class="mw-heading"><h4>Usage notes</h4></div><p>Used to describe a positive feeling.</p>
<div class="mw-heading"><h4>Synonyms</h4></div>
<ul><li><span lang="en"><a>glad</a>, <a>joyful</a></span></li></ul>
<div class="mw-heading"><h2 id="French">French</h2></div>
<h3>Adjective</h3><ol><li>Wrong language.</li></ol>
<h4>Synonyms</h4><span lang="fr"><a>unrelated</a></span></div>''';

WordDetails details() => WordDetails(
  language: 'en',
  sourceUrl: 'https://en.wiktionary.org/wiki/happy#English',
  fetchedAt: '2026-10-05T12:00:00Z',
  usage: ['Describes a positive feeling.'],
  examples: ['I am happy.'],
  synonyms: ['glad', 'joyful'],
);

class FakeDictionary implements WordDictionary {
  int calls = 0;
  bool fail = false;
  @override
  Future<WordDetails?> lookup(String term, String language) async {
    calls++;
    if (fail) throw StateError('Offline');
    return details();
  }
}

class PendingDictionary implements WordDictionary {
  final response = Completer<WordDetails?>();
  @override
  Future<WordDetails?> lookup(String term, String language) => response.future;
}

class MemoryStorage implements StudyStorage {
  MemoryStorage(this.data);
  StudyData data;
  bool fail = false;
  @override
  Future<StudyData> load() async => data.copy();
  @override
  Future<void> save(StudyData next) async {
    if (fail) throw StateError('Full');
    data = next.copy();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [Locale('vi')];
    addTearDown(
      TestWidgetsFlutterBinding
          .instance
          .platformDispatcher
          .clearLocalesTestValue,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });

  test('parser isolates language, excludes examples from definitions and deduplicates synonyms', () {
    final result = WiktionaryDictionary.parseEntry(markup, 'happy', 'en')!;
    expect(result.definitions, ['Adjective: Feeling joy.']);
    expect(result.synonyms, ['glad', 'joyful']);
    expect(result.examples, ['I am happy.']);
    expect(result.usage, ['Used to describe a positive feeling.']);
    expect(WiktionaryDictionary.parseEntry(markup, 'happy', 'ko'), isNull);
  });

  test(
    'API encodes Unicode, uses selected language and handles missing entries',
    () async {
      final dictionary = WiktionaryDictionary(
        client: MockClient((request) async {
          expect(request.url.queryParameters['page'], '학교');
          expect(request.url.queryParameters['formatversion'], '2');
          return http.Response(
            jsonEncode({
              'parse': {
                'text': '<div class="mw-parser-output"><h2 id="Korean">Korean</h2><h3>Noun</h3><ol><li>school</li></ol></div>',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      expect((await dictionary.lookup('학교', 'ko-KR'))!.definitions, [
        'Noun: school',
      ]);
      final missing = WiktionaryDictionary(
        client: MockClient(
          (_) async => http.Response('{"error":{"code":"missingtitle"}}', 200),
        ),
      );
      expect(await missing.lookup('unknown', 'en-US'), isNull);
    },
  );

  test('details survive copy/backup and old backups remain readable', () {
    final card = StudyCard(
      id: '1',
      term: 'happy',
      definition: 'vui',
      details: details(),
    );
    final data = StudyData(
      sets: [
        StudySet(id: 'set', title: 'Set', cards: [card]),
      ],
    );
    expect(
      data.copy().sets.single.cards.single.details!.toJson(),
      details().toJson(),
    );
    expect(
      StudyCard.fromJson({'id': 'old', 'term': 'old', 'definition': 'cũ'})
          .details,
      isNull,
    );
    expect(
      () => WordDetails.fromJson({
        ...details().toJson(),
        'synonyms': [1],
      }),
      throwsFormatException,
    );
  });

  test('suggestions match synonyms and prioritize exact words', () {
    final card = StudyCard(
      id: '1',
      term: 'happy',
      definition: 'vui',
      details: details(),
    );
    final glad = StudyCard(id: '2', term: 'glad', definition: 'vui');
    expect(suggestCards([card, glad], 'GLAD').map((c) => c.id), ['2', '1']);
    expect(suggestCards([card], ''), isEmpty);
  });

  test('lookup failure never prevents retaining imported cards', () async {
    final dictionary = FakeDictionary()..fail = true;
    final cards = [StudyCard(id: '1', term: 'happy', definition: 'vui')];
    expect(await enrichCards(cards, dictionary, 'en-US'), 1);
    expect(cards.single.term, 'happy');
    expect(cards.single.details, isNull);
  });

  testWidgets('skip lookup ignores late results and closes progress', (
    tester,
  ) async {
    final dictionary = PendingDictionary();
    final cards = [StudyCard(id: '1', term: 'happy', definition: 'vui')];
    int? missing;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                missing = await lookupNewCards(
                  context,
                  cards,
                  dictionary,
                  'en-US',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Bỏ qua tra cứu và lưu từ'));
    await tester.pumpAndSettle();
    expect(missing, 1);
    dictionary.response.complete(details());
    await tester.pumpAndSettle();
    expect(cards.single.details, isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'import looks up, persists and opens offline popup after restart',
    (tester) async {
      final dictionary = FakeDictionary();
      final storage = MemoryStorage(
        StudyData(
          sets: [StudySet(id: 'set', title: 'Set', cards: [])],
          settings: {'wordLanguage': 'en-US'},
        ),
      );
      Future<void> open() async {
        await tester.pumpWidget(
          MyApp(storage: storage, dictionary: dictionary),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục học   →'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.ensureVisible(find.text('Nhập từ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập từ'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'happy, vui\nhappy, khác',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Nhập từ'));
      await tester.pumpAndSettle();
      expect(dictionary.calls, 1);
      expect(storage.data.sets.single.cards.single.details!.synonyms, [
        'glad',
        'joyful',
      ]);
      await tester.pumpWidget(const SizedBox());
      dictionary.fail = true;
      await open();
      await tester.tap(find.byTooltip('Chi tiết thẻ').first);
      await tester.pumpAndSettle();
      expect(find.text('I am happy.'), findsOneWidget);
      expect(find.text('glad'), findsOneWidget);
      expect(dictionary.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single word form validates duplicates and adds only to the opened set',
    (tester) async {
      final dictionary = FakeDictionary();
      final storage = MemoryStorage(
        StudyData(
          sets: [
            StudySet(
              id: 'target',
              title: 'Target',
              cards: [StudyCard(id: '1', term: 'happy', definition: 'vui')],
            ),
            StudySet(id: 'other', title: 'Other', cards: []),
          ],
          settings: {'wordLanguage': 'en-US'},
        ),
      );
      await tester.pumpWidget(MyApp(storage: storage, dictionary: dictionary));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục học   →'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-word')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu từ'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập đầy đủ từ và nghĩa'), findsNWidgets(2));
      await tester.enterText(
        find.byKey(const ValueKey('new-word-term')),
        'HAPPY',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-word-meaning')),
        'vui vẻ',
      );
      await tester.tap(find.text('Lưu từ'));
      await tester.pumpAndSettle();
      expect(find.text('Từ này đã có trong danh mục'), findsOneWidget);
      expect(dictionary.calls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('new-word-term')),
        'glad',
      );
      await tester.tap(find.text('Lưu từ'));
      await tester.pumpAndSettle();
      expect(storage.data.sets.first.cards.map((c) => c.term), [
        'happy',
        'glad',
      ]);
      expect(storage.data.sets.last.cards, isEmpty);
      expect(storage.data.sets.first.cards.last.details, isNotNull);
      expect(dictionary.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refresh only updates popup after storage succeeds', (
    tester,
  ) async {
    final card = StudyCard(id: '1', term: 'happy', definition: 'vui');
    bool saved = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CardDetailsDialog(
                  card: card,
                  dictionary: FakeDictionary(),
                  language: 'en-US',
                  onSave: (_) async => saved,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tra chi tiết'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa lưu được dữ liệu.'), findsOneWidget);
    expect(find.text('glad'), findsNothing);
    saved = true;
    await tester.tap(find.text('Tra chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('glad'), findsOneWidget);
  });
}
