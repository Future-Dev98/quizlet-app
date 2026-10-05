import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'models.dart';
import 'main.dart';
import 'editor.dart';
import 'practice.dart';
import 'reading.dart';
import 'app_layout.dart';

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
  });
  final StudySet initial;
  final List<Folder> folders;
  final Map<String, dynamic> settings;
  final SaveSet onSave;
  final SaveResult onResult;
  final Future<bool> Function() onDelete;
  final Future<bool> Function(Map<String, dynamic>) onSettings;
  @override
  State<SetPage> createState() => _SetPageState();
}

class _SetPageState extends State<SetPage> with WidgetsBindingObserver {
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
    if (state != AppLifecycleState.resumed) stop();
  }

  void stop() {
    generation++;
    tts.stop();
    if (mounted) setState(() => playing = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    generation++;
    tts.stop();
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
      if (mastered) item.starred = false;
    }
    if (starred != null) {
      item.starred = starred;
      if (starred) item.mastered = false;
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
    try {
      await tts.stop();
      final language = meaning ? 'vi-VN' : 'ko-KR';
      if (await tts.isLanguageAvailable(language) != true) {
        message(
          'Thiết bị chưa có giọng ${meaning ? 'tiếng Việt' : 'tiếng Hàn'}. Hãy tải giọng trong cài đặt hệ thống.',
        );
        return;
      }
      await tts.setLanguage(language);
      final voice = settings[meaning ? 'viVoice' : 'koVoice'];
      if (voice is Map) await tts.setVoice(Map<String, String>.from(voice));
      await tts.setSpeechRate((settings['rate'] as num? ?? .45).toDouble());
      await tts.speak(text);
    } catch (_) {
      message('Không phát được giọng đọc trên thiết bị này.');
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
      if (mounted && token == generation) setState(() => playing = false);
    }
  }

  Future<void> options() async {
    stop();
    var next = Map<String, dynamic>.of(settings);
    final timingForm = GlobalKey<FormState>();
    List<Map<String, String>> voices = [];
    try {
      voices = (await tts.getVoices as List)
          .map((v) => {'name': '${v['name']}', 'locale': '${v['locale']}'})
          .where(
            (v) =>
                v['locale']!.startsWith('ko') || v['locale']!.startsWith('vi'),
          )
          .toSet()
          .toList();
    } catch (_) {
      /* Voice selection is optional. */
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, state) {
          Widget toggle(String key, String label, bool fallback) =>
              SwitchListTile(
                title: Text(label),
                value: next[key] as bool? ?? fallback,
                onChanged: (v) => state(() => next[key] = v),
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
              onChanged: (v) => state(() => next[key] = v),
            ),
          );
          Widget voice(String key, String locale, String label) {
            final choices = {
              for (final v in voices.where(
                (v) => v['locale']!.startsWith(locale),
              ))
                '${v['name']}|${v['locale']}': v,
            };
            final value = next[key] is Map
                ? '${next[key]['name']}|${next[key]['locale']}'
                : '';
            return DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: choices.containsKey(value) ? value : '',
              decoration: InputDecoration(labelText: label),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Giọng mặc định'),
                ),
                ...choices.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value['name']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => state(() => next[key] = choices[v]),
            );
          }

          Widget delay(String key, String label, int fallback) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              key: ValueKey(key),
              initialValue: '${(next[key] as int? ?? fallback) / 1000}',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: label,
                suffixText: 'giây',
                helperText: '0.5 giây = 500 ms · Từ 0.001 đến 60 giây',
              ),
              validator: (value) {
                final seconds = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (seconds == null ||
                    !seconds.isFinite ||
                    seconds < .001 ||
                    seconds > 60) {
                  return 'Nhập thời gian từ 0.001 đến 60 giây';
                }
                return null;
              },
              onSaved: (value) => next[key] =
                  (double.parse(value!.trim().replaceAll(',', '.')) * 1000)
                      .round(),
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
                      'Tùy chọn thẻ',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    toggle('starredOnly', 'Chỉ thẻ cần học lại', false),
                    toggle('trackProgress', 'Theo dõi tiến độ xem thẻ', true),
                    toggle('reverse', 'Hiển thị nghĩa ở mặt trước', false),
                    toggle('speechEnabled', 'Bật giọng đọc', true),
                    toggle('autoSpeak', 'Tự đọc khi chuyển thẻ', false),
                    toggle('loop', 'Lặp lại khi hết thẻ', false),
                    toggle('speakWord', 'Đọc mặt trước khi tự phát', true),
                    toggle('speakMeaning', 'Đọc mặt sau khi tự phát', true),
                    const Text('Tốc độ đọc'),
                    Slider(
                      value: (next['rate'] as num? ?? .45).toDouble(),
                      min: .1,
                      max: 1,
                      divisions: 18,
                      label: '${next['rate'] ?? .45}',
                      onChanged: (v) => state(() => next['rate'] = v),
                    ),
                    delay('flipDelayMs', 'Chờ lật thẻ', 3000),
                    delay('nextDelayMs', 'Chờ chuyển thẻ', 2000),
                    number('wordRepeats', 'Số lần đọc mặt trước', 1, [
                      1,
                      2,
                      3,
                      4,
                      5,
                    ]),
                    number('meaningRepeats', 'Số lần đọc mặt sau', 1, [
                      1,
                      2,
                      3,
                      4,
                      5,
                    ]),
                    voice('koVoice', 'ko', 'Giọng tiếng Hàn'),
                    const SizedBox(height: 16),
                    voice('viVoice', 'vi', 'Giọng tiếng Việt'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: next['font'] as String? ?? 'system',
                      decoration: const InputDecoration(labelText: 'Kiểu chữ'),
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('Mặc định'),
                        ),
                        DropdownMenuItem(value: 'serif', child: Text('Serif')),
                        DropdownMenuItem(
                          value: 'monospace',
                          child: Text('Monospace'),
                        ),
                      ],
                      onChanged: (v) => state(() => next['font'] = v),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (!timingForm.currentState!.validate()) return;
                        timingForm.currentState!.save();
                        Navigator.pop(context, next);
                      },
                      child: const Text('Lưu tùy chọn'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (result != null && await widget.onSettings(result) && mounted) {
      setState(() {
        settings = result;
        index = 0;
        flipped = false;
      });
    }
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

  Future<void> import() async {
    stop();
    final input = TextEditingController();
    String? error;
    final result = await showSettledDialog<ImportResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, state) => AlertDialog(
          title: const Text('Thêm định nghĩa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mỗi dòng: từ + TAB / nhiều dấu cách / dấu phẩy + nghĩa. Từ trùng sẽ được bỏ qua.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: input,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '사랑하다, yêu\n공부하다, học',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  Navigator.pop(context, parseCards(input.text, set.cards));
                } on FormatException catch (e) {
                  state(() => error = e.message);
                }
              },
              child: const Text('Nhập từ'),
            ),
          ],
        ),
      ),
    );
    input.dispose();
    if (result == null || !mounted) return;
    final next = StudySet.fromJson(set.toJson())..cards.addAll(result.cards);
    if (await save(next) && mounted) {
      setState(() => order = set.cards.map((c) => c.id).toList());
      message(
        'Đã thêm ${result.cards.length} từ · bỏ qua ${result.duplicates} từ trùng.',
      );
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
          title: const Text('Sửa từ vựng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: term,
                decoration: InputDecoration(
                  labelText: 'Từ tiếng Hàn',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: definition,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Nghĩa'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (term.text.trim().isEmpty ||
                    definition.text.trim().isEmpty) {
                  state(() => error = 'Nhập đầy đủ từ và nghĩa');
                  return;
                }
                if (set.cards.any(
                  (c) =>
                      c.id != card.id &&
                      normalizeAnswer(c.term) == normalizeAnswer(term.text),
                )) {
                  state(() => error = 'Từ này đã có trong danh mục');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final next = StudySet.fromJson(set.toJson());
      final c = next.cards.firstWhere((c) => c.id == card.id);
      c.term = term.text.trim();
      c.definition = definition.text.trim();
      c.mastered = false;
      await save(next);
    }
    term.dispose();
    definition.dispose();
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
                    'Xóa danh mục?',
                    'Xóa ${set.title} và toàn bộ thẻ trong danh mục này?',
                  ) &&
                  await widget.onDelete() &&
                  context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa danh mục')),
            PopupMenuItem(value: 'delete', child: Text('Xóa danh mục')),
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
                      '${set.cards.length} từ · ${set.learned} đã thuộc',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tùy chọn',
                    onPressed: options,
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (current == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      onlyStars
                          ? 'Không có thẻ cần học lại. Tắt bộ lọc để xem tất cả.'
                          : 'Danh mục chưa có từ. Nhập từ để bắt đầu.',
                    ),
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
                    tooltip: 'Thẻ trước',
                    onPressed: busy ? null : () => move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton.filledTonal(
                    tooltip: playing ? 'Dừng tự phát' : 'Tự động phát',
                    onPressed: autoplay,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Trộn thẻ',
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
                  IconButton.filledTonal(
                    tooltip: 'Thẻ tiếp',
                    onPressed: busy ? null : () => move(1),
                    icon: const Icon(Icons.chevron_right),
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
                      current!.mastered
                          ? 'Đánh dấu chưa thuộc'
                          : 'Đã thuộc từ này',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text('Luyện tập', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in PracticeMode.values)
                    ActionChip(
                      avatar: Icon(mode.icon, size: 18),
                      label: Text(mode.label),
                      onPressed: () => practice(mode),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.mic_none, size: 18),
                    label: const Text('Luyện đọc'),
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
                    label: const Text('Chấm phát âm'),
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
                      'Từ vựng',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : import,
                    icon: const Icon(Icons.add),
                    label: const Text('Nhập từ'),
                  ),
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm trong danh mục',
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: set.cards
                    .where(
                      (c) => '${c.term} ${c.definition}'.toLowerCase().contains(
                        search.toLowerCase(),
                      ),
                    )
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
                      .where(
                        (c) => '${c.term} ${c.definition}'
                            .toLowerCase()
                            .contains(search.toLowerCase()),
                      )
                      .elementAt(i);
                  return Card(
                    key: ValueKey(c.id),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (search.isEmpty)
                            ReorderableDragStartListener(
                              index: i,
                              child: const Icon(
                                Icons.drag_indicator,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.term,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(c.definition),
                                Wrap(
                                  children: [
                                    IconButton(
                                      tooltip: 'Đã thuộc',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final next = StudySet.fromJson(
                                                set.toJson(),
                                              );
                                              final item = next.cards
                                                  .firstWhere(
                                                    (v) => v.id == c.id,
                                                  );
                                              item.mastered = !item.mastered;
                                              if (item.mastered) {
                                                item.starred = false;
                                              }
                                              await save(next);
                                            },
                                      icon: Icon(
                                        c.mastered
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        size: 20,
                                        color: c.mastered
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Cần học lại',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final next = StudySet.fromJson(
                                                set.toJson(),
                                              );
                                              final item = next.cards
                                                  .firstWhere(
                                                    (v) => v.id == c.id,
                                                  );
                                              item.starred = !item.starred;
                                              if (item.starred) {
                                                item.mastered = false;
                                              }
                                              await save(next);
                                            },
                                      icon: Icon(
                                        c.starred
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 20,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Nghe từ',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        stop();
                                        speak(c.term, false);
                                      },
                                      icon: const Icon(
                                        Icons.volume_up_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Sửa từ',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => editCard(c),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Xóa từ',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              stop();
                                              if (!await confirm(
                                                context,
                                                'Xóa từ?',
                                                'Xóa “${c.term}” khỏi danh mục?',
                                              )) {
                                                return;
                                              }
                                              final next =
                                                  StudySet.fromJson(
                                                      set.toJson(),
                                                    )
                                                    ..cards.removeWhere(
                                                      (v) => v.id == c.id,
                                                    );
                                              if (await save(next) && mounted) {
                                                setState(() {
                                                  order.remove(c.id);
                                                  index = 0;
                                                });
                                              }
                                            },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (set.attempts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Kết quả gần đây',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ...set.attempts
                    .take(5)
                    .map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history),
                        title: Text(
                          '${PracticeMode.values.where((m) => m.name == a['mode']).firstOrNull?.label ?? a['mode']} · ${a['score']}/${a['total']}',
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
          'THẺ ${index + 1} / ${cards.length}',
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
                        meaning ? 'NGHĨA TIẾNG VIỆT' : 'TỪ TIẾNG HÀN',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cần học lại',
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
                  tooltip: 'Nghe mẫu',
                  onPressed: () {
                    stop();
                    speak(meaning ? c.definition : c.term, meaning);
                  },
                  icon: Icon(Icons.volume_up_outlined, color: colors.primary),
                ),
                Text(
                  'Chạm để lật · Vuốt để chuyển',
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
