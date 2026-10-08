import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'models.dart';
import 'main.dart';
import 'editor.dart';
import 'practice.dart';
import 'reading.dart';
import 'app_layout.dart';
import 'app_localization.dart';
import 'dictionary.dart';
import 'card_details.dart';
import 'word_suggestions.dart';
import 'word_tile.dart';

typedef SaveSet = Future<bool> Function(StudySet);
typedef SaveResult = Future<bool> Function(StudySet, int, int);

class SetPage extends StatefulWidget {
  const SetPage({
    super.key,
    required this.initial,
    required this.folders,
    required this.settings,
    required this.onSave,
    required this.onResult,
    required this.onDelete,
    required this.onSettings,
    required this.dictionary,
  });
  final StudySet initial;
  final List<Folder> folders;
  final Map<String, dynamic> settings;
  final SaveSet onSave;
  final WordDictionary dictionary;
  final SaveResult onResult;
  final Future<bool> Function() onDelete;
  final Future<bool> Function(Map<String, dynamic>) onSettings;
  @override
  State<SetPage> createState() => _SetPageState();
}

class _SetPageState extends State<SetPage> with WidgetsBindingObserver {
  AppLocalizations get l10n => context.l10n;
  late StudySet set = StudySet.fromJson(widget.initial.toJson());
  late Map<String, dynamic> settings = Map.of(widget.settings);
  final tts = FlutterTts();
  late List<String> order = set.cards.map((c) => c.id).toList();
  late int index = cards
      .indexWhere((c) => c.id == set.lastCardId)
      .clamp(0, cards.isEmpty ? 0 : cards.length - 1);
  bool flipped = false, playing = false, busy = false;
  int generation = 0;
  String search = '';
  final searchController = TextEditingController();
  bool get onlyStars => settings['starredOnly'] == true;
  bool get reverse => settings['reverse'] == true;
  List<StudyCard> get cards => order
      .map((id) => set.cards.firstWhere((c) => c.id == id))
      .where((c) => !onlyStars || c.starred)
      .toList();
  StudyCard? get current =>
      cards.isEmpty ? null : cards[index.clamp(0, cards.length - 1)];
  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tts.awaitSpeakCompletion(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            state != AppLifecycleState.resumed)) {
      stop();
    }
  }

  void stop() {
    generation++;
    unawaited(stopSpeech(generation));
    if (mounted) setState(() => playing = false);
  }

  Future<void> stopSpeech(int token) async {
    await tts.stop();
    await releaseAudioSession(token);
  }

  Future<void> releaseAudioSession(int token) async {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        token == generation) {
      await tts.setSharedInstance(false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    generation++;
    unawaited(stopSpeech(generation));
    super.dispose();
  }

  Future<bool> save(StudySet next) async {
    if (busy) return false;
    setState(() => busy = true);
    final ok = await widget.onSave(next);
    if (mounted) {
      setState(() {
        if (ok) set = next;
        busy = false;
      });
    }
    return ok;
  }

  Future<void> status({bool? mastered, bool? starred}) async {
    stop();
    final c = current;
    if (c == null || busy) return;
    final next = StudySet.fromJson(set.toJson());
    final item = next.cards.firstWhere((v) => v.id == c.id);
    if (mastered != null) {
      item.mastered = mastered;
    }
    if (starred != null) {
      item.starred = starred;
    }
    next.lastCardId = c.id;
    if (await save(next) && mounted) {
      setState(
        () => index = index.clamp(0, cards.isEmpty ? 0 : cards.length - 1),
      );
    }
  }

  Future<void> move(int step, {bool auto = false}) async {
    if (!auto) stop();
    if (busy || current == null) return;
    var target = index + step;
    while (target >= 0 && target < cards.length && cards[target].mastered) {
      target += step;
    }
    if (target < 0 || target >= cards.length) return;
    final next = StudySet.fromJson(set.toJson())..lastCardId = cards[target].id;
    if (settings['trackProgress'] != false) {
      next.cards.firstWhere((c) => c.id == next.lastCardId).seen = true;
    }
    if (await save(next) && mounted) {
      setState(() {
        index = target;
        flipped = false;
      });
    }
    if (!auto && mounted && settings['autoSpeak'] == true && current != null) {
      await speak(reverse ? current!.definition : current!.term, reverse);
    }
  }

  Future<void> speak(String text, bool meaning) async {
    if (settings['speechEnabled'] == false) return;
    final token = generation;
    try {
      await tts.stop();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Keep the session active between words in a background study session.
        await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ], IosTextToSpeechAudioMode.spokenAudio);
        await tts.autoStopSharedSession(!playing);
        await tts.setSharedInstance(true);
      }
      final language =
          settings[meaning ? 'meaningLanguage' : 'wordLanguage'] as String? ??
          (meaning ? 'vi-VN' : 'ko-KR');
      if (await tts.isLanguageAvailable(language) != true) {
        message(l10n.voiceUnavailable(language));
        return;
      }
      await tts.setLanguage(language);
      final voice = settings[meaning ? 'viVoice' : 'koVoice'];
      if (voice is Map &&
          voice['locale'].toString().split('-').first ==
              language.split('-').first) {
        await tts.setVoice(Map<String, String>.from(voice));
      } else {
        await tts.clearVoice();
      }
      await tts.setSpeechRate((settings['rate'] as num? ?? .45).toDouble());
      if (!mounted || token != generation) return;
      await tts.speak(text);
    } catch (_) {
      message(l10n.speechError);
    }
  }

  Future<void> autoplay() async {
    if (playing) {
      stop();
      return;
    }
    if (current == null || busy) return;
    final token = ++generation;
    setState(() => playing = true);
    bool active() => mounted && playing && token == generation;
    try {
      while (active() && current != null) {
        final c = current!;
        setState(() => flipped = false);
        for (
          var i = 0;
          i < (settings['wordRepeats'] as int? ?? 1) && active();
          i++
        ) {
          if (settings['speakWord'] != false) {
            await speak(reverse ? c.definition : c.term, reverse);
          }
        }
        if (!active()) break;
        await Future<void>.delayed(
          Duration(milliseconds: settings['flipDelayMs'] as int? ?? 3000),
        );
        if (!active()) break;
        setState(() => flipped = true);
        for (
          var i = 0;
          i < (settings['meaningRepeats'] as int? ?? 1) && active();
          i++
        ) {
          if (settings['speakMeaning'] != false) {
            await speak(reverse ? c.term : c.definition, !reverse);
          }
        }
        if (!active()) break;
        await Future<void>.delayed(
          Duration(milliseconds: settings['nextDelayMs'] as int? ?? 2000),
        );
        if (!active()) break;
        final before = index;
        await move(1, auto: true);
        if (!active()) break;
        if (before == index) {
          if (settings['loop'] == true && cards.any((c) => !c.mastered)) {
            final target = cards.indexWhere((c) => !c.mastered);
            final next = StudySet.fromJson(set.toJson())
              ..lastCardId = cards[target].id;
            if (!await save(next)) break;
            if (active()) {
              setState(() {
                index = target;
                flipped = false;
              });
            }
          } else {
            break;
          }
        }
      }
    } finally {
      if (mounted && token == generation) {
        setState(() => playing = false);
        await releaseAudioSession(token);
      }
    }
  }

  Future<void> options() async {
    stop();
    var next = Map<String, dynamic>.of(settings);
    Timer? saveTimer;
    Future<void> writes = Future.value();
    var revision = 0;
    var savedRevision = 0;
    var sheetOpen = true;
    var timingForm = GlobalKey<FormState>();
    StateSetter? refreshSheet;
    Future<void> persist() {
      saveTimer?.cancel();
      if (savedRevision == revision) return writes;
      final token = revision;
      savedRevision = token;
      final snapshot = Map<String, dynamic>.of(next);
      writes = writes.then((_) async {
        final ok = await widget.onSettings(snapshot);
        if (!mounted) return;
        if (ok) {
          setState(() {
            settings = snapshot;
            index = index.clamp(0, cards.isEmpty ? 0 : cards.length - 1);
            flipped = false;
          });
        } else if (token == revision) {
          next = Map<String, dynamic>.of(settings);
          timingForm = GlobalKey<FormState>();
          if (sheetOpen) refreshSheet?.call(() {});
        }
      });
      return writes;
    }

    void scheduleSave() {
      revision++;
      saveTimer?.cancel();
      saveTimer = Timer(const Duration(milliseconds: 250), persist);
    }

    List<Map<String, String>> voices = [];
    try {
      voices = (await tts.getVoices as List)
          .whereType<Map>()
          .where((v) => v['name'] is String && v['locale'] is String)
          .map(
            (v) => {
              for (final key in [
                'name',
                'locale',
                'identifier',
                'gender',
                'quality',
              ])
                if (v[key] != null) key: '${v[key]}',
            },
          )
          .toList();
      voices.sort((a, b) {
        final femaleA = a['gender']?.toLowerCase() == 'female';
        final femaleB = b['gender']?.toLowerCase() == 'female';
        if (femaleA != femaleB) return femaleA ? -1 : 1;
        return a['name']!.compareTo(b['name']!);
      });
    } catch (_) {
      /* Voice selection is optional. */
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, state) {
          refreshSheet = state;
          void change(VoidCallback update) {
            state(update);
            scheduleSave();
          }

          Widget toggle(String key, String label, bool fallback) =>
              SwitchListTile(
                title: Text(label),
                value: next[key] as bool? ?? fallback,
                onChanged: (v) => change(() => next[key] = v),
              );
          Widget number(
            String key,
            String label,
            int fallback,
            List<int> values,
          ) => ListTile(
            title: Text(label),
            trailing: DropdownButton<int>(
              value: next[key] as int? ?? fallback,
              items: values
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) => change(() => next[key] = v),
            ),
          );
          Widget voice(String key, String locale, String label) {
            String identity(Map v) =>
                v['identifier']?.toString().isNotEmpty == true
                ? v['identifier'].toString()
                : '${v['name']}|${v['locale']}';
            final choices = {
              for (final v in voices.where(
                (v) =>
                    v['locale']!.replaceAll('_', '-').split('-').first ==
                    locale,
              ))
                identity(v): v,
            };
            var value = next[key] is Map ? identity(next[key]) : '';
            // Preserve selections saved before voice identifiers were stored.
            if (!choices.containsKey(value) && next[key] is Map) {
              for (final entry in choices.entries) {
                if (entry.value['name'] == next[key]['name'] &&
                    entry.value['locale'] == next[key]['locale']) {
                  value = entry.key;
                  break;
                }
              }
            }
            String voiceLabel(Map<String, String> v) => [
              v['name']!,
              if (v['gender']?.toLowerCase() == 'female') l10n.femaleVoice,
              if (v['gender']?.toLowerCase() == 'male') l10n.maleVoice,
              if (v['quality']?.toLowerCase() == 'enhanced') l10n.enhancedVoice,
              if (v['quality']?.toLowerCase() == 'premium') l10n.premiumVoice,
            ].join(' · ');
            return DropdownButtonFormField<String>(
              key: ValueKey('$key-$locale'),
              isExpanded: true,
              initialValue: choices.containsKey(value) ? value : '',
              decoration: InputDecoration(labelText: label),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.defaultVoice)),
                ...choices.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      voiceLabel(e.value),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => change(() => next[key] = choices[v]),
            );
          }

          Widget languagePicker(
            String key,
            String fallback,
            String voiceKey,
            String label,
          ) => DropdownButtonFormField<String>(
            initialValue: next[key] as String? ?? fallback,
            isExpanded: true,
            decoration: InputDecoration(labelText: label),
            items: studyLanguages
                .map(
                  (code) => DropdownMenuItem(
                    value: code,
                    child: Text(studyLanguageName(context, code)),
                  ),
                )
                .toList(),
            onChanged: (value) => change(() {
              next[key] = value;
              next.remove(voiceKey);
            }),
          );

          Widget delay(String key, String label, int fallback) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              key: ValueKey(key),
              initialValue: '${(next[key] as int? ?? fallback) / 1000}',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: label,
                suffixText: l10n.secondsUnit,
                helperText: l10n.delayHint,
              ),
              validator: (value) {
                final seconds = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (seconds == null ||
                    !seconds.isFinite ||
                    seconds < .001 ||
                    seconds > 60) {
                  return l10n.delayValidation;
                }
                return null;
              },
              onChanged: (value) {
                final seconds = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                if (seconds == null ||
                    !seconds.isFinite ||
                    seconds < .001 ||
                    seconds > 60) {
                  return;
                }
                next[key] = (seconds * 1000).round();
                scheduleSave();
              },
            ),
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(context).height * .88 -
                          MediaQuery.viewInsetsOf(context).bottom)
                      .clamp(120.0, MediaQuery.sizeOf(context).height),
              child: Form(
                key: timingForm,
                child: ListView(
                  padding: EdgeInsets.all(mobileInset(context)),
                  children: [
                    Text(
                      l10n.cardOptions,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    toggle('starredOnly', l10n.starredOnly, false),
                    toggle('trackProgress', l10n.trackProgress, true),
                    toggle('reverse', l10n.reverseCards, false),
                    toggle('speechEnabled', l10n.speechEnabled, true),
                    toggle('autoSpeak', l10n.autoSpeak, false),
                    toggle('loop', l10n.loopCards, false),
                    toggle('speakWord', l10n.speakFront, true),
                    toggle('speakMeaning', l10n.speakBack, true),
                    Text(l10n.speechRate),
                    Slider(
                      value: (next['rate'] as num? ?? .45).toDouble(),
                      min: .1,
                      max: 1,
                      divisions: 18,
                      label: '${next['rate'] ?? .45}',
                      onChanged: (v) => change(() => next['rate'] = v),
                    ),
                    delay('flipDelayMs', l10n.flipDelay, 3000),
                    delay('nextDelayMs', l10n.nextDelay, 2000),
                    number('wordRepeats', l10n.frontRepeats, 1, [
                      1,
                      2,
                      3,
                      4,
                      5,
                    ]),
                    number('meaningRepeats', l10n.backRepeats, 1, [
                      1,
                      2,
                      3,
                      4,
                      5,
                    ]),
                    languagePicker(
                      'wordLanguage',
                      'ko-KR',
                      'koVoice',
                      l10n.wordLanguage,
                    ),
                    const SizedBox(height: 16),
                    voice(
                      'koVoice',
                      (next['wordLanguage'] as String? ?? 'ko-KR')
                          .split('-')
                          .first,
                      l10n.wordVoice,
                    ),
                    const SizedBox(height: 16),
                    languagePicker(
                      'meaningLanguage',
                      'vi-VN',
                      'viVoice',
                      l10n.meaningLanguage,
                    ),
                    const SizedBox(height: 16),
                    voice(
                      'viVoice',
                      (next['meaningLanguage'] as String? ?? 'vi-VN')
                          .split('-')
                          .first,
                      l10n.meaningVoice,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.languageHint),
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 8),
                      Text(l10n.downloadVoicesHint),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: next['font'] as String? ?? 'system',
                      decoration: InputDecoration(labelText: l10n.font),
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(l10n.defaultFont),
                        ),
                        DropdownMenuItem(value: 'serif', child: Text('Serif')),
                        DropdownMenuItem(
                          value: 'monospace',
                          child: Text('Monospace'),
                        ),
                      ],
                      onChanged: (v) => change(() => next['font'] = v),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    sheetOpen = false;
    await persist();
  }

  Future<void> editSet() async {
    stop();
    final result = await Navigator.push<StudySet>(
      context,
      MaterialPageRoute(
        builder: (_) => SetEditor(initial: set, folders: widget.folders),
      ),
    );
    if (result != null) await save(result);
  }

  Future<void> addCard() async {
    stop();
    final form = GlobalKey<FormState>();
    final term = TextEditingController();
    final meaning = TextEditingController();
    final card = await showSettledDialog<StudyCard>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addWord),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('new-word-term'),
                    controller: term,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.word),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.enterWordMeaning;
                      }
                      if (set.cards.any(
                        (c) =>
                            normalizeAnswer(c.term) == normalizeAnswer(value),
                      )) {
                        return l10n.duplicateWord;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('new-word-meaning'),
                    controller: meaning,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.meaning),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterWordMeaning
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.autoDetailsHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(
                  context,
                  StudyCard(
                    id: newId(),
                    term: term.text.trim(),
                    definition: meaning.text.trim(),
                  ),
                );
              }
            },
            child: Text(l10n.saveWord),
          ),
        ],
      ),
    );
    term.dispose();
    meaning.dispose();
    if (card != null && mounted) await addCards([card]);
  }

  Future<void> import() async {
    stop();
    final input = TextEditingController();
    String? error;
    final result = await showSettledDialog<ImportResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, state) => AlertDialog(
          title: Text(l10n.addDefinitions),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.importHint),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('import-words-input'),
                  controller: input,
                  maxLines: 8,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: l10n.importExample,
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final parsed = parseCards(
                    input.text,
                    set.cards,
                    localization: l10n,
                  );
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context, parsed);
                } on FormatException catch (e) {
                  state(() => error = e.message);
                }
              },
              child: Text(l10n.importWords),
            ),
          ],
        ),
      ),
    );
    input.dispose();
    if (result == null || !mounted) return;
    await addCards(result.cards, duplicates: result.duplicates);
  }

  Future<void> addCards(List<StudyCard> newCards, {int duplicates = 0}) async {
    if (busy) return;
    if (newCards.isEmpty) {
      message(l10n.importSummary(0, duplicates));
      return;
    }
    setState(() => busy = true);
    try {
      final next = StudySet.fromJson(set.toJson())..cards.addAll(newCards);
      if (await saveWords(next) && mounted) {
        setState(() {
          set = next;
          order = set.cards.map((c) => c.id).toList();
        });
        message(l10n.importSummary(newCards.length, duplicates));
        // The entered words are already persisted before any network request.
        // Enrich a copy so a failed details save cannot change saved cards.
        final enriched = StudySet.fromJson(set.toJson());
        final ids = newCards.map((c) => c.id).toSet();
        final added = enriched.cards.where((c) => ids.contains(c.id)).toList();
        final missing = await lookupNewCards(
          context,
          added,
          widget.dictionary,
          settings['wordLanguage'] as String? ?? 'ko-KR',
          wordsSaved: true,
        );
        if (!mounted) return;
        if (added.any((c) => c.details != null) &&
            await saveWords(enriched) &&
            mounted) {
          setState(() => set = enriched);
        }
        if ((missing ?? 0) > 0) message(l10n.detailsMissing(missing!));
      }
    } catch (_) {
      message(l10n.saveError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> saveWords(StudySet next) async {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context, rootNavigator: true);
    final loading = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(context.l10n.savingWords),
          scrollable: true,
          content: const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
    unawaited(navigator.push(loading));
    try {
      return await widget.onSave(next);
    } finally {
      if (loading.isActive) navigator.removeRoute(loading);
    }
  }

  Future<void> toggleWordStatus(StudyCard card, {required bool learned}) async {
    if (busy) return;
    stop();
    final previous = set;
    final next = StudySet.fromJson(set.toJson());
    final item = next.cards.firstWhere((c) => c.id == card.id);
    if (learned) {
      item.mastered = !item.mastered;
    } else {
      item.starred = !item.starred;
    }
    setState(() => set = next);
    if (!await save(next) && mounted) {
      setState(() => set = previous);
    }
  }

  Future<void> deleteCard(StudyCard card) async {
    stop();
    if (!await confirm(
          context,
          l10n.deleteWordConfirm,
          l10n.deleteWordNotice(card.term),
        ) ||
        !mounted) {
      return;
    }
    final next = StudySet.fromJson(set.toJson())
      ..cards.removeWhere((c) => c.id == card.id);
    if (await save(next) && mounted) {
      setState(() {
        order.remove(card.id);
        index = 0;
      });
    }
  }

  Future<void> editCard(StudyCard card) async {
    stop();
    final term = TextEditingController(text: card.term);
    final definition = TextEditingController(text: card.definition);
    String? error;
    final ok = await showSettledDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, state) => AlertDialog(
          title: Text(l10n.editWord),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: term,
                  decoration: InputDecoration(
                    labelText: l10n.word,
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: definition,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.meaning),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (term.text.trim().isEmpty ||
                    definition.text.trim().isEmpty) {
                  state(() => error = l10n.enterWordMeaning);
                  return;
                }
                if (set.cards.any(
                  (c) =>
                      c.id != card.id &&
                      normalizeAnswer(c.term) == normalizeAnswer(term.text),
                )) {
                  state(() => error = l10n.duplicateWord);
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      if (!mounted) {
        term.dispose();
        definition.dispose();
        return;
      }
      final next = StudySet.fromJson(set.toJson());
      final c = next.cards.firstWhere((c) => c.id == card.id);
      final changedTerm = normalizeAnswer(c.term) != normalizeAnswer(term.text);
      c.term = term.text.trim();
      c.definition = definition.text.trim();
      c.mastered = false;
      if (changedTerm) {
        c.details = null;
        await lookupNewCards(
          context,
          [c],
          widget.dictionary,
          settings['wordLanguage'] as String? ?? 'ko-KR',
        );
      }
      if (!mounted) {
        term.dispose();
        definition.dispose();
        return;
      }
      await save(next);
    }
    term.dispose();
    definition.dispose();
  }

  Future<void> showDetails(StudyCard card) async {
    stop();
    await showDialog<void>(
      context: context,
      builder: (_) => CardDetailsDialog(
        card: card,
        dictionary: widget.dictionary,
        language: settings['wordLanguage'] as String? ?? 'ko-KR',
        onSave: (details) async {
          final next = StudySet.fromJson(set.toJson());
          final index = next.cards.indexWhere((c) => c.id == card.id);
          if (index < 0 || !mounted) return false;
          next.cards[index].details = details;
          return save(next);
        },
      ),
    );
  }

  Future<void> practice(PracticeMode mode) async {
    stop();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PracticePage(
          cards: set.cards,
          mode: mode,
          onComplete: (result) async {
            final next = StudySet.fromJson(set.toJson());
            next.attempts.insert(0, {
              'mode': mode.name,
              'score': result.correct,
              'total': result.total,
              'date': DateTime.now().toIso8601String(),
            });
            next.attempts = next.attempts.take(50).toList();
            final ok = await widget.onResult(
              next,
              result.correct,
              result.total,
            );
            if (ok && mounted) setState(() => set = next);
            return ok;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(set.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await editSet();
            } else if (v == 'delete') {
              stop();
              if (await confirm(
                    context,
                    l10n.deleteSetConfirm,
                    l10n.deleteSetNotice(set.title),
                  ) &&
                  await widget.onDelete() &&
                  context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.editSet)),
            PopupMenuItem(value: 'delete', child: Text(l10n.deleteSet)),
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              mobileInset(context),
              12,
              mobileInset(context),
              32,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.wordProgress(set.cards.length, set.learned),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.options,
                    onPressed: options,
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('add-word'),
                    onPressed: busy ? null : addCard,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.addWord),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : import,
                    icon: const Icon(Icons.playlist_add_rounded, size: 20),
                    label: Text(l10n.importWords),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (current == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(onlyStars ? l10n.noReviewCards : l10n.emptySet),
                  ),
                )
              else
                flashcard(current!),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton.filledTonal(
                    tooltip: l10n.previousCard,
                    onPressed: busy ? null : () => move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton.filledTonal(
                    tooltip: l10n.nextCard,
                    onPressed: busy ? null : () => move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton.filledTonal(
                    tooltip: playing ? l10n.stopAutoplay : l10n.autoplay,
                    onPressed: busy && !playing ? null : autoplay,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                  IconButton.filledTonal(
                    tooltip: l10n.shuffleCards,
                    onPressed: () {
                      stop();
                      setState(() {
                        order.shuffle();
                        index = 0;
                        flipped = false;
                      });
                    },
                    icon: const Icon(Icons.shuffle),
                  ),
                ],
              ),
              if (current != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: FilledButton.icon(
                    key: const ValueKey('mastery-button'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontSize: 12),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    onPressed: busy
                        ? null
                        : () => status(mastered: !current!.mastered),
                    icon: Icon(
                      current!.mastered ? Icons.undo : Icons.check,
                      size: 16,
                    ),
                    label: Text(
                      current!.mastered ? l10n.markUnlearned : l10n.markLearned,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                l10n.practice,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in PracticeMode.values)
                    ActionChip(
                      avatar: Icon(mode.icon, size: 18),
                      label: Text(mode.localizedLabel(context)),
                      onPressed: () => practice(mode),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.mic_none, size: 18),
                    label: Text(l10n.reading),
                    onPressed: () {
                      stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReadingPage(
                            setId: set.id,
                            initialText: '',
                            pronunciation: false,
                          ),
                        ),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.record_voice_over, size: 18),
                    label: Text(l10n.pronunciation),
                    onPressed: current == null
                        ? null
                        : () {
                            stop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReadingPage(
                                  setId: set.id,
                                  initialText: current!.term,
                                  pronunciation: true,
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.vocabulary,
                      key: const ValueKey('vocabulary-header'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${set.cards.where((c) => matchesCard(c, search)).length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.addWord,
                    onPressed: busy ? null : addCard,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.wordListHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.searchInSet,
                  suffixIcon: search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          onPressed: () {
                            searchController.clear();
                            setState(() => search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              if (search.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.wordSuggestions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final card in suggestCards(set.cards, search))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(card.term),
                    subtitle: Text(card.definition),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () => showDetails(card),
                  ),
              ],
              const SizedBox(height: 12),
              if (search.isNotEmpty &&
                  !set.cards.any((c) => matchesCard(c, search)))
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noCards),
                ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: set.cards
                    .where((c) => matchesCard(c, search))
                    .length,
                onReorderItem: (a, b) async {
                  if (search.isNotEmpty || busy) return;
                  stop();
                  final next = StudySet.fromJson(set.toJson());
                  final card = next.cards.removeAt(a);
                  next.cards.insert(b, card);
                  if (await save(next) && mounted) {
                    setState(() {
                      order = set.cards.map((c) => c.id).toList();
                      index = 0;
                    });
                  }
                },
                itemBuilder: (context, i) {
                  final c = set.cards
                      .where((c) => matchesCard(c, search))
                      .elementAt(i);
                  return WordTile(
                    key: ValueKey(c.id),
                    card: c,
                    index: i,
                    canReorder: search.isEmpty,
                    busy: busy,
                    onDetails: () => showDetails(c),
                    onListen: () {
                      stop();
                      speak(c.term, false);
                    },
                    onLearned: () => toggleWordStatus(c, learned: true),
                    onReview: () => toggleWordStatus(c, learned: false),
                    onEdit: () => editCard(c),
                    onDelete: () => deleteCard(c),
                  );
                },
              ),
              if (set.attempts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.recentResults,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...set.attempts
                    .take(5)
                    .map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history),
                        title: Text(
                          '${PracticeMode.values.where((m) => m.name == a['mode']).firstOrNull?.localizedLabel(context) ?? a['mode']} · ${a['score']}/${a['total']}',
                        ),
                        subtitle: Text(
                          '${a['date']}'
                              .replaceFirst('T', ' ')
                              .split('.')
                              .first,
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  Widget flashcard(StudyCard c) {
    final meaning = flipped ? !reverse : reverse;
    final colors = Theme.of(context).colorScheme;
    final availableWidth =
        MediaQuery.sizeOf(context).width.clamp(0.0, 600.0) -
        mobileInset(context) * 2;
    final cardFontSize = (availableWidth * .105).clamp(30.0, 40.0);
    return Column(
      children: [
        Text(
          l10n.cardPosition(index + 1, cards.length),
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onHorizontalDragEnd: (d) => move(d.primaryVelocity! < 0 ? 1 : -1),
          onTap: () {
            stop();
            setState(() => flipped = !flipped);
            if (settings['trackProgress'] != false && !busy) {
              final next = StudySet.fromJson(set.toJson())..lastCardId = c.id;
              next.cards.firstWhere((v) => v.id == c.id).seen = true;
              save(next);
            }
          },
          child: AnimatedContainer(
            key: const ValueKey('flashcard-surface'),
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: (MediaQuery.sizeOf(context).height * .3).clamp(
                220.0,
                300.0,
              ),
            ),
            padding: EdgeInsets.all(mobileInset(context)),
            decoration: BoxDecoration(
              color: meaning ? colors.primaryContainer : colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: purple.withValues(alpha: .07),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meaning ? l10n.meaningFace : l10n.wordFace,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.cardDetails,
                      onPressed: () => showDetails(c),
                      icon: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      tooltip: l10n.needsReview,
                      onPressed: busy
                          ? null
                          : () => status(starred: !c.starred),
                      icon: Icon(
                        c.starred ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    meaning ? c.definition : c.term,
                    key: ValueKey('$meaning${c.id}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: meaning
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontSize: cardFontSize,
                      fontWeight: FontWeight.w700,
                      fontFamily: settings['font'] == 'system'
                          ? null
                          : settings['font'] as String?,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                IconButton(
                  tooltip: l10n.listenSample,
                  onPressed: busy
                      ? null
                      : () {
                          stop();
                          speak(meaning ? c.definition : c.term, meaning);
                        },
                  icon: Icon(Icons.volume_up_outlined, color: colors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.cardGestureHint,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
