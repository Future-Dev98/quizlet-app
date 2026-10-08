import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';
import 'package:my_app/models.dart';
import 'package:my_app/storage.dart';
import 'package:my_app/editor.dart';
import 'package:my_app/practice.dart';
import 'package:my_app/app_localization.dart';
import 'package:my_app/dictionary.dart';
import 'package:my_app/word_tile.dart';

class EmptyDictionary implements WordDictionary {
  @override
  Future<WordDetails?> lookup(String term, String language) async => null;
}

class DelayedDictionary implements WordDictionary {
  final result = Completer<WordDetails?>();
  @override
  Future<WordDetails?> lookup(String term, String language) => result.future;
}

class MemoryStorage implements StudyStorage {
  MemoryStorage(this.data);
  StudyData data;
  bool fail = false;
  Completer<void>? saveGate;
  int saveCalls = 0;
  @override
  Future<StudyData> load() async => data.copy();
  @override
  Future<void> save(StudyData next) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (fail) throw const FileSystemException('Full');
    data = next.copy();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = {
      'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
      'Noto Sans KR': 'C:/Windows/Fonts/malgun.ttf',
      'MaterialIcons': 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    };
    for (final entry in fonts.entries) {
      final font = File(entry.value);
      if (await font.exists()) {
        final bytes = await font.readAsBytes();
        await (FontLoader(
          entry.key,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    }
  });
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
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'getVoices') return [];
          if (call.method == 'isLanguageAvailable') return true;
          return 1;
        });
  });
  Future<void> phone(
    WidgetTester tester,
    StudyStorage storage, {
    WordDictionary? dictionary,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: MyApp(
          storage: storage,
          dictionary: dictionary ?? EmptyDictionary(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/previews').create(recursive: true);
      await File('build/previews/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    debugDisableShadows = shadows;
    repaint(boundary);
    await tester.pump();
  }

  testWidgets('iPhone 13 home and study layout with actual seed', (
    tester,
  ) async {
    final seed = (await tester.runAsync(
      () async =>
          StudyData.decode(await File('assets/seed.json').readAsString()),
    ))!;
    expect(seed.sets.length, 8);
    expect(seed.sets.fold(0, (n, s) => n + s.cards.length), 405);
    await phone(tester, MemoryStorage(seed));
    expect(find.text('Mỗi từ mới là một\nbước tiến nhỏ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'iphone13-home');
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    expect(find.text('Chạm để lật · Vuốt để chuyển'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'iphone13-study');
  });
  testWidgets('redesigned word list supports details and quick status', (
    tester,
  ) async {
    final storage = MemoryStorage(
      StudyData(
        sets: [
          StudySet(
            id: 'korean',
            title: 'Động từ',
            cards: [
              StudyCard(id: 'k1', term: '가다', definition: 'đi'),
              StudyCard(
                id: 'k2',
                term: '오다',
                definition: 'đến',
                mastered: true,
              ),
              StudyCard(id: 'k3', term: '먹다', definition: 'ăn', starred: true),
              StudyCard(id: 'k4', term: '마시다', definition: 'uống'),
              StudyCard(id: 'k5', term: '보다', definition: 'xem, nhìn'),
            ],
          ),
        ],
        darkMode: true,
      ),
    );
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('add-word')).hitTestable(),
      findsOneWidget,
    );
    await capture(tester, 'word-list-add-toolbar');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('vocabulary-header')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find
          .ancestor(
            of: find.byKey(const ValueKey('vocabulary-header')),
            matching: find.byType(Row),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'word-list-redesign-dark');
    final tile = find.byType(WordTile).first;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: tile,
        matching: find.widgetWithText(FilterChip, 'Đã thuộc'),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.cards.first.mastered, isTrue);
    await tester.tap(
      find.descendant(
        of: tile,
        matching: find.widgetWithText(FilterChip, 'Cần học lại'),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.cards.first.mastered, isTrue);
    expect(storage.data.sets.single.cards.first.starred, isTrue);
    await tester.tap(
      find.descendant(
        of: tile,
        matching: find.widgetWithText(FilterChip, 'Đã thuộc'),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.cards.first.mastered, isFalse);
    expect(storage.data.sets.single.cards.first.starred, isTrue);
    await tester.tap(
      find.descendant(
        of: tile,
        matching: find.widgetWithText(FilterChip, 'Đã thuộc'),
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.cards.first.mastered, isTrue);
    expect(storage.data.sets.single.cards.first.starred, isTrue);
    await tester.tap(
      find.descendant(of: tile, matching: find.byTooltip('Thao tác với từ')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa từ'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa từ vựng'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: tile, matching: find.text('가다')));
    await tester.pumpAndSettle();
    expect(find.text('Cách sử dụng'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('card mastery persists through restart', (tester) async {
    final storage = MemoryStorage(StudyData.demo());
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã thuộc từ này'));
    await tester.pumpAndSettle();
    expect(storage.data.sets.first.cards.first.mastered, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await phone(tester, storage);
    expect(find.text('1 thẻ đã thuộc'), findsOneWidget);
  });
  testWidgets('failed saves do not change mastery', (tester) async {
    final storage = MemoryStorage(StudyData.demo())..fail = true;
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã thuộc từ này'));
    await tester.pumpAndSettle();
    expect(storage.data.sets.first.cards.first.mastered, isFalse);
    expect(find.text('Đã thuộc từ này'), findsOneWidget);
  });
  testWidgets('create category and add imported terms', (tester) async {
    final storage = MemoryStorage(StudyData(sets: []));
    await phone(tester, storage);
    await tester.tap(find.text('Tạo danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Bộ mới');
    await tester.ensureVisible(find.text('Lưu danh mục'));
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.title, 'Bộ mới');
    expect(find.widgetWithText(AppBar, 'Bộ mới'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-word')), findsOneWidget);
    await tester.ensureVisible(find.text('Nhập từ'));
    await tester.tap(find.text('Nhập từ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      '학교, trường học\n학생, học sinh\n학교, nghĩa khác',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Nhập từ'));
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.cards.length, 2);
    expect(storage.data.sets.single.cards.first.definition, 'trường học');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'iOS bulk import with keyboard saves without waiting for network',
    (tester) async {
      final storage = MemoryStorage(StudyData.demo());
      await phone(tester, storage, dictionary: DelayedDictionary());
      await tester.tap(find.text('Tiếp tục học   →'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Nhập từ'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(
        find.byType(TextField).last,
        '학교, trường học\n학생, học sinh\n학교, trùng',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final submit = find.widgetWithText(FilledButton, 'Nhập từ');
      expect(submit.hitTestable(), findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        storage.data.sets.first.cards.where((c) => c.term == '학교'),
        hasLength(1),
      );
      expect(storage.data.sets.first.cards.any((c) => c.term == '학생'), isTrue);
      expect(find.text('Đang tra cách dùng và từ đồng nghĩa'), findsOneWidget);
      await tester.tap(find.text('Bỏ qua tra cứu'));
      await tester.pumpAndSettle();
      expect(
        storage.data.sets.first.cards.where((c) => c.term == '학교'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('bulk import saves first then looks up and persists details', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo());
    final dictionary = DelayedDictionary();
    await phone(tester, storage, dictionary: dictionary);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Nhập từ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      '학교, trường  học\n학생\t học sinh',
    );
    storage.saveGate = Completer<void>();
    await tester.tap(find.widgetWithText(FilledButton, 'Nhập từ'));
    for (var i = 0; i < 10 && storage.saveCalls == 0; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('add-word')))
          .onPressed,
      isNull,
    );
    expect(find.text('Đang lưu từ…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(storage.saveCalls, 1);
    expect(storage.data.sets.first.cards.any((c) => c.term == '학교'), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Đang lưu từ…'), findsOneWidget);
    storage.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Đang lưu từ…'), findsNothing);
    expect(find.text('Đang tra cách dùng và từ đồng nghĩa'), findsOneWidget);
    expect(
      storage.data.sets.first.cards
          .where((c) => c.term == '학교')
          .single
          .definition,
      'trường  học',
    );
    expect(storage.data.sets.first.cards.any((c) => c.term == '학생'), isTrue);
    expect(
      storage.data.sets.first.cards.where((c) => c.term == '학교').single.details,
      isNull,
    );
    dictionary.result.complete(
      WordDetails(
        language: 'ko',
        sourceUrl: 'https://en.wiktionary.org/wiki/학교',
        fetchedAt: '2026-10-06',
        examples: ['학교에 가요.'],
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.saveCalls, 2);
    expect(
      storage.data.sets.first.cards
          .where((c) => c.term == '학교')
          .single
          .details!
          .examples,
      ['학교에 가요.'],
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('add-word')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('single word save failure dismisses loading and allows retry', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo())..fail = true;
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    Future<void> submit() async {
      await tester.tap(find.byKey(const ValueKey('add-word')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('new-word-term')), '학교');
      await tester.enterText(
        find.byKey(const ValueKey('new-word-meaning')),
        'trường học',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu từ'));
    }

    storage.saveGate = Completer<void>();
    await submit();
    for (var i = 0; i < 10 && storage.saveCalls == 0; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump();
    expect(find.text('Đang lưu từ…'), findsOneWidget);
    storage.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Đang lưu từ…'), findsNothing);
    expect(storage.data.sets.first.cards.any((c) => c.term == '학교'), isFalse);
    storage.fail = false;
    storage.saveGate = null;
    await submit();
    await tester.pumpAndSettle();
    expect(
      storage.data.sets.first.cards.where((c) => c.term == '학교'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('writing checks Korean term and saves one result', (
    tester,
  ) async {
    final card = StudyCard(id: '1', term: '학교', definition: 'trường học');
    int calls = 0;
    PracticeResult? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PracticePage(
          cards: [card],
          mode: PracticeMode.writing,
          onComplete: (r) async {
            calls++;
            result = r;
            return true;
          },
        ),
      ),
    );
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.text('trường học'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' 학교 ');
    await tester.pump();
    await tester.tap(find.text('Kiểm tra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem kết quả'));
    await tester.pumpAndSettle();
    expect(result!.correct, 1);
    expect(result!.total, 1);
    expect(calls, 1);
    expect(find.text('Đã lưu kết quả trên thiết bị.'), findsOneWidget);
  });
  testWidgets('reflex timeout and lifecycle pause', (tester) async {
    final cards = StudyData.demo().sets.first.cards;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PracticePage(
          cards: cards,
          mode: PracticeMode.reflex,
          onComplete: (_) async => true,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 8));
    expect(
      find.text('Bài luyện đã tạm dừng khi rời ứng dụng.'),
      findsOneWidget,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('Chưa đúng. Đáp án:'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('0 / 1'), findsOneWidget);
  });
  testWidgets('home handles larger text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await phone(tester, MemoryStorage(StudyData.demo()));
    expect(tester.takeException(), isNull);
  });
  testWidgets('study fits small phones, large phones, tablets and landscape', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo());
    await phone(tester, storage);
    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(430, 932),
      const Size(600, 960),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Home at $size');
      await tester.scrollUntilVisible(
        find.text('Tiếp tục học   →'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục học   →'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Study at $size');
      final termFont = tester
          .widget<Text>(find.byKey(const ValueKey('falsee1')))
          .style!
          .fontSize;
      final button = find.byKey(const ValueKey('mastery-button'));
      await tester.scrollUntilVisible(
        button,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(button).width, lessThan(250));
      expect(tester.getSize(button).height, lessThanOrEqualTo(48));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('falsee1')),
        -120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('falsee1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('truee1')))
            .style!
            .fontSize,
        termFont,
      );
      expect(tester.takeException(), isNull, reason: 'Definition at $size');
      if (size.width == 390) await capture(tester, 'iphone13-study-compact');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
  });
  testWidgets('word status responds before disk save without shifting chips', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo());
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('vocabulary-header')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final tile = find.byType(WordTile).first;
    final chip = find.descendant(
      of: tile,
      matching: find.widgetWithText(FilterChip, 'Đã thuộc'),
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    final position = tester.getTopLeft(chip);
    storage.saveGate = Completer<void>();
    storage.fail = true;
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(tester.getTopLeft(chip), position);
    expect(
      find.descendant(
        of: tile,
        matching: find.byType(ReorderableDragStartListener),
      ),
      findsOneWidget,
    );
    storage.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(storage.data.sets.first.cards.first.mastered, isFalse);
    expect(tester.getTopLeft(chip), position);
  });

  testWidgets('settings serialize changes and flush when sheet closes', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo());
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Lưu tùy chọn'), findsNothing);
    storage.saveGate = Completer<void>();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Chỉ thẻ cần học lại'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Hiển thị nghĩa ở mặt trước'),
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    storage.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(storage.data.settings['starredOnly'], isTrue);
    expect(storage.data.settings['reverse'], isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid delay is not saved and failed autosave restores controls',
    (tester) async {
      final storage = MemoryStorage(StudyData.demo());
      await phone(tester, storage);
      await tester.tap(find.text('Tiếp tục học   →'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tùy chọn'));
      await tester.pumpAndSettle();
      final delay = find.byKey(const ValueKey('flipDelayMs'));
      await tester.ensureVisible(delay);
      await tester.enterText(delay, '0');
      await tester.pump(const Duration(milliseconds: 300));
      expect(storage.data.settings.containsKey('flipDelayMs'), isFalse);
      await tester.enterText(delay, '0,5');
      await tester.pump(const Duration(milliseconds: 300));
      expect(storage.data.settings['flipDelayMs'], 500);
      storage.fail = true;
      await tester.enterText(delay, '1');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(storage.data.settings['flipDelayMs'], 500);
      expect(tester.widget<TextFormField>(delay).initialValue, '0.5');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('autoplay background lifecycle on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          calls.add(call);
          if (call.method == 'isLanguageAvailable') return true;
          return 1;
        },
      );
      final data = StudyData.demo()
        ..settings = {'flipDelayMs': 500, 'nextDelayMs': 500};
      await phone(tester, MemoryStorage(data));
      await tester.tap(find.text('Tiếp tục học   →'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Tự động phát'));
      await tester.tap(find.byTooltip('Tự động phát'));
      await tester.pump();
      final spoken = calls.where((c) => c.method == 'speak').length;
      expect(spoken, greaterThan(0));
      calls.clear();
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      if (platform == TargetPlatform.iOS) {
        expect(calls.where((c) => c.method == 'stop'), isEmpty);
        await tester.pump(const Duration(milliseconds: 500));
        expect(calls.where((c) => c.method == 'speak'), isNotEmpty);
        expect(
          calls
              .singleWhere((c) => c.method == 'autoStopSharedSession')
              .arguments,
          false,
        );
        expect(
          calls.singleWhere((c) => c.method == 'setSharedInstance').arguments,
          true,
        );
      } else {
        expect(calls.where((c) => c.method == 'stop'), isNotEmpty);
        await tester.pump(const Duration(milliseconds: 500));
        expect(calls.where((c) => c.method == 'speak'), isEmpty);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      if (platform == TargetPlatform.iOS) {
        await tester.tap(find.byTooltip('Dừng tự phát'));
        await tester.pump();
        expect(
          calls.where((c) => c.method == 'setSharedInstance').last.arguments,
          false,
        );
      }
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tự động phát'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('fractional delay saves milliseconds and autoplay uses 500 ms', (
    tester,
  ) async {
    final data = StudyData.demo()..settings = {'speechEnabled': false};
    final storage = MemoryStorage(data);
    await phone(tester, storage);
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    final flip = find.byKey(const ValueKey('flipDelayMs'));
    final next = find.byKey(const ValueKey('nextDelayMs'));
    await tester.ensureVisible(flip);
    await tester.enterText(flip, '0.5');
    await tester.ensureVisible(next);
    await tester.enterText(next, '0,5');
    await tester.pump(const Duration(milliseconds: 300));
    expect(storage.data.settings['flipDelayMs'], 500);
    expect(storage.data.settings['nextDelayMs'], 500);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Tự động phát'));
    await tester.tap(find.byTooltip('Tự động phát'));
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.byKey(const ValueKey('falsee1')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('truee1')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('falsee2')), findsOneWidget);
    await tester.tap(find.byTooltip('Dừng tự phát'));
    await tester.pumpAndSettle();
  });
  test(
    'legacy seconds migrate while fractional and invalid times validate',
    () {
      final migrated = StudyData.decode(
        StudyData(
          sets: [],
          settings: {'flipDelay': 3, 'nextDelay': .5},
        ).encode(),
      );
      expect(migrated.settings['flipDelayMs'], 3000);
      expect(migrated.settings['nextDelayMs'], 500);
      expect(migrated.settings.containsKey('flipDelay'), isFalse);
      expect(
        () => StudyData.decode(
          StudyData(sets: [], settings: {'flipDelayMs': 0}).encode(),
        ),
        throwsFormatException,
      );
    },
  );
  testWidgets('Default and Dark change surfaces and text and persist', (
    tester,
  ) async {
    final storage = MemoryStorage(StudyData.demo());
    await phone(tester, storage);
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tối'));
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(storage.data.darkMode, isTrue);
    expect(find.text('Nền tối · Chữ sáng'), findsOneWidget);
    await capture(tester, 'iphone13-theme-dark');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await phone(tester, storage);
    final homeContext = tester.element(find.byType(HomePage));
    expect(Theme.of(homeContext).brightness, Brightness.dark);
    expect(
      Theme.of(homeContext).scaffoldBackgroundColor.computeLuminance(),
      lessThan(.1),
    );
    expect(
      Theme.of(homeContext).colorScheme.onSurface.computeLuminance(),
      greaterThan(.7),
    );
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    Color cardColor() =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(const ValueKey('flashcard-surface')),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;
    expect(cardColor().computeLuminance(), lessThan(.1));
    await tester.tap(find.text('Serendipity'));
    await tester.pumpAndSettle();
    expect(cardColor().computeLuminance(), lessThan(.1));
    final text = tester.widget<Text>(find.text('Sự tình cờ may mắn'));
    expect(text.style!.color!.computeLuminance(), greaterThan(.7));
    await capture(tester, 'iphone13-study-dark');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sáng'));
    await tester.tap(find.text('Sáng'));
    await tester.pumpAndSettle();
    expect(storage.data.darkMode, isFalse);
    expect(
      Theme.of(tester.element(find.byType(HomePage))).brightness,
      Brightness.light,
    );
    expect(find.text('Nền sáng · Chữ tối'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('quiz revisits answers without counting twice', (tester) async {
    final cards = StudyData.demo().sets.first.cards.take(2).toList();
    PracticeResult? result;
    int saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PracticePage(
          cards: cards,
          mode: PracticeMode.quiz,
          onComplete: (r) async {
            saves++;
            result = r;
            return true;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    final first = cards.firstWhere(
      (c) => find.text(c.term).evaluate().isNotEmpty,
    );
    Finder option(String meaning) => find.byWidgetPredicate(
      (w) => w is Text && w.data != null && w.data!.endsWith('.  $meaning'),
    );
    await tester.tap(option(first.definition));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Câu trước'));
    await tester.pumpAndSettle();
    await tester.tap(
      option(cards.firstWhere((c) => c.id != first.id).definition),
    );
    await tester.pumpAndSettle();
    final second = cards.firstWhere(
      (c) => find.text(c.term).evaluate().isNotEmpty,
    );
    await tester.tap(option(second.definition));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(result!.correct, 1);
    expect(result!.total, 2);
  });
  testWidgets('nested folders can organize a category', (tester) async {
    final storage = MemoryStorage(
      StudyData(sets: [], folders: [Folder('root', 'Tiếng Hàn', null)]),
    );
    await phone(tester, storage);
    await tester.ensureVisible(find.text('Tiếng Hàn'));
    await tester.tap(find.text('Tiếng Hàn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tạo thư mục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Bài 1');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    final child = storage.data.folders.last;
    expect(child.parentId, 'root');
    await tester.ensureVisible(find.text('Bài 1'));
    await tester.tap(find.text('Bài 1'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tạo danh mục'),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Động từ');
    await tester.ensureVisible(find.text('Lưu danh mục'));
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(storage.data.sets.single.folderId, child.id);
    expect(storage.data.folderPath(child.id), 'Tiếng Hàn / Bài 1');
  });
  test('import parses commas and rejects malformed lines atomically', () {
    final result = parseCards(
      '학교, trường học, nơi học tập\n학생\t học sinh\n학교, trùng',
      [],
    );
    expect(result.cards.length, 2);
    expect(result.duplicates, 1);
    expect(result.cards.first.definition, 'trường học, nơi học tập');
    expect(() => parseCards('학교, trường học\nbad', []), throwsFormatException);
    expect(normalizeAnswer('학교'), normalizeAnswer('학교'));
  });
  test('import uses the first separator and preserves meaning spacing', () {
    final result = parseCards(
      '학교, trường  học, nơi học tập\r\n학생\t học  sinh\r가다  đi, đi tới',
      [],
    );
    expect(result.cards.map((c) => c.term), ['학교', '학생', '가다']);
    expect(result.cards.map((c) => c.definition), [
      'trường  học, nơi học tập',
      'học  sinh',
      'đi, đi tới',
    ]);
    expect(parseCards('학교, nghĩa khác', result.cards).duplicates, 1);
  });
  test('quiz options are unique despite duplicate meanings', () {
    final cards = [
      StudyCard(id: '1', term: 'a', definition: 'A'),
      StudyCard(id: '2', term: 'b', definition: ' a '),
      StudyCard(id: '3', term: 'c', definition: 'B'),
    ];
    for (final q in makeQuestions(cards, 3)) {
      expect(q.options.map(normalizeAnswer).toSet().length, q.options.length);
      expect(q.options, contains(q.card.definition));
    }
  });
  test('backup rejects cycles and invalid scores', () {
    final data = StudyData(sets: [], folders: [Folder('1', 'Loop', '1')]);
    expect(() => StudyData.decode(data.encode()), throwsFormatException);
    expect(
      () => StudyData.decode(
        StudyData(sets: [], correct: 2, answers: 1).encode(),
      ),
      throwsFormatException,
    );
  });
  test('disk roundtrip and recovery from corrupted primary', () async {
    final dir = await Directory.systemTemp.createTemp('vocab_test_');
    try {
      final storage = LocalStudyStorage(directory: dir);
      final data = StudyData.demo();
      await storage.save(data);
      data.sets.first.cards.first.mastered = true;
      await storage.save(data);
      expect((await storage.load()).sets.first.cards.first.mastered, isTrue);
      await File('${dir.path}/study_data.json').writeAsString('broken');
      final recovered = await storage.load();
      expect(recovered.sets.length, 2);
      await storage.save(recovered);
      expect((await storage.load()).sets.length, 2);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
