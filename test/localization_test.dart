import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';
import 'package:my_app/models.dart';
import 'package:my_app/storage.dart';
import 'package:my_app/editor.dart';
import 'package:my_app/app_localization.dart';

class MemoryStorage implements StudyStorage {
  MemoryStorage(this.data);
  StudyData data;
  bool fail = false;
  @override
  Future<StudyData> load() async => data.copy();
  @override
  Future<void> save(StudyData next) async {
    if (fail) throw StateError('Storage full');
    data = next.copy();
  }
}

void main() {
  testWidgets('language switch persists and preserves vocabulary', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final storage = MemoryStorage(StudyData.demo());
    final original = storage.data.sets.first.toJson();
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(storage.data.settings['interfaceLanguage'], 'en');
    expect(storage.data.sets.first.toJson(), original);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Create set'));
    await tester.pumpAndSettle();
    expect(find.text('Set name'), findsOneWidget);
    await tester.ensureVisible(find.text('Save set'));
    await tester.tap(find.text('Save set'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a set name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('device locales and unsupported locale fallback', (tester) async {
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final storage = MemoryStorage(StudyData(sets: []));
    for (final entry in {
      'en': 'Home',
      'vi': 'Trang chủ',
      'ar': 'Trang chủ',
    }.entries) {
      tester.binding.platformDispatcher.localesTestValue = [Locale(entry.key)];
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MyApp(storage: storage));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('failed language save retains previous interface', (
    tester,
  ) async {
    final storage = MemoryStorage(
      StudyData(sets: [], settings: {'interfaceLanguage': 'vi'}),
    )..fail = true;
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Cá nhân'), findsOneWidget);
    expect(storage.data.settings['interfaceLanguage'], 'vi');
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      'vi',
    );
    expect(find.textContaining('Chưa lưu được dữ liệu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected study language controls speech and resets old voice', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'getVoices') return [];
      if (call.method == 'isLanguageAvailable') return true;
      return 1;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final storage = MemoryStorage(
      StudyData.demo()
        ..settings['koVoice'] = {'name': 'old', 'locale': 'ko-KR'},
    );
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    final picker = find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<String> &&
          w.decoration.labelText == 'Ngôn ngữ của từ',
    );
    await tester.scrollUntilVisible(
      picker,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Anh').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(storage.data.settings['wordLanguage'], 'en-US');
    expect(storage.data.settings.containsKey('koVoice'), isFalse);
    expect(find.text('Lưu tùy chọn'), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Nghe mẫu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nghe mẫu'));
    await tester.pumpAndSettle();
    expect(
      calls.where((c) => c.method == 'setLanguage').last.arguments,
      'en-US',
    );
    expect(calls.where((c) => c.method == 'speak'), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('female voice variants remain separate and save identifiers', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final calls = <MethodCall>[];
    final voices = [
      {
        'name': 'Korean male',
        'locale': 'ko-KR',
        'gender': 'male',
        'identifier': 'ko-male',
      },
      {
        'name': 'Korean female',
        'locale': 'ko-KR',
        'gender': 'female',
        'quality': 'default',
        'identifier': 'ko-default',
      },
      {
        'name': 'Korean female',
        'locale': 'ko-KR',
        'gender': 'female',
        'quality': 'enhanced',
        'identifier': 'ko-enhanced',
      },
      {
        'name': 'Vietnamese female',
        'locale': 'vi-VN',
        'gender': 'female',
        'quality': 'default',
        'identifier': 'vi-default',
      },
      {
        'name': 'Vietnamese female',
        'locale': 'vi-VN',
        'gender': 'female',
        'quality': 'premium',
        'identifier': 'vi-premium',
      },
    ];
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'getVoices') return voices;
      if (call.method == 'isLanguageAvailable') return true;
      return 1;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final storage = MemoryStorage(StudyData.demo());
    await tester.pumpWidget(MyApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục học   →'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    for (final language in ['ko', 'vi']) {
      final key = language == 'ko' ? 'koVoice' : 'viVoice';
      final picker = find.byKey(ValueKey('$key-$language'));
      await tester.scrollUntilVisible(
        picker,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: picker,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(dropdown.items!.length, language == 'ko' ? 4 : 3);
      expect((dropdown.items![1].child as Text).data, contains('Nữ'));
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(
              language == 'ko'
                  ? 'Korean female · Nữ · Chất lượng cao'
                  : 'Vietnamese female · Nữ · Cao cấp',
            )
            .last,
      );
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(storage.data.settings['koVoice']['identifier'], 'ko-enhanced');
    expect(storage.data.settings['viVoice']['identifier'], 'vi-premium');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    final restored = StudyData.decode(storage.data.encode());
    expect(restored.settings['koVoice']['identifier'], 'ko-enhanced');
    await tester.ensureVisible(find.byTooltip('Nghe mẫu'));
    await tester.tap(find.byTooltip('Nghe mẫu'));
    await tester.pumpAndSettle();
    expect(
      calls.where((c) => c.method == 'setVoice').last.arguments['identifier'],
      'ko-enhanced',
    );
    expect(tester.takeException(), isNull);
  });

  test('backup migrates old settings and validates language preferences', () {
    expect(StudyData.decode(StudyData(sets: []).encode()).settings, isEmpty);
    final preferences = {
      'interfaceLanguage': 'en',
      'wordLanguage': 'en-US',
      'meaningLanguage': 'ja-JP',
    };
    expect(
      StudyData.decode(StudyData(sets: [], settings: preferences).encode())
          .settings,
      preferences,
    );
    for (final settings in [
      {'interfaceLanguage': 1},
      {'wordLanguage': 'invalid'},
      {'meaningLanguage': false},
    ]) {
      expect(
        () =>
            StudyData.decode(StudyData(sets: [], settings: settings).encode()),
        throwsFormatException,
      );
    }
    expect(
      () => parseCards(
        'invalid',
        [],
        localization: lookupAppLocalizations(const Locale('en')),
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          startsWith('Line 1:'),
        ),
      ),
    );
  });
}
