import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'app_layout.dart';
import 'main.dart';

enum PracticeMode {
  quiz('Kiểm tra', Icons.fact_check_outlined),
  reflex('Phản xạ', Icons.bolt),
  writing('Luyện viết', Icons.edit_note);

  const PracticeMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

class PracticeResult {
  PracticeResult(this.correct, this.total);
  final int correct, total;
}

class Question {
  Question(this.card, this.options);
  final StudyCard card;
  final List<String> options;
}

List<Question> makeQuestions(List<StudyCard> cards, int count) {
  final shuffled = List<StudyCard>.of(cards)..shuffle();
  return shuffled.take(count).map((c) {
    final options = <String, String>{};
    final key = normalizeAnswer(c.definition);
    for (final other in shuffled) {
      final k = normalizeAnswer(other.definition);
      if (k != key) options[k] = other.definition;
    }
    final wrong = options.values.toList()..shuffle();
    final choices = [c.definition, ...wrong.take(3)]..shuffle();
    return Question(c, choices);
  }).toList();
}

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.cards,
    required this.mode,
    required this.onComplete,
  });
  final List<StudyCard> cards;
  final PracticeMode mode;
  final Future<bool> Function(PracticeResult) onComplete;
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage>
    with WidgetsBindingObserver {
  final count = TextEditingController(text: '20');
  final answer = TextEditingController();
  List<Question> questions = [];
  final Map<int, String?> answers = {};
  int index = 0, correct = 0, seconds = 5, remaining = 5;
  bool checked = false, right = false, finished = false, paused = false;
  bool saving = false, saved = false;
  Timer? timer;
  Timer? advance;
  bool get writing => widget.mode == PracticeMode.writing;
  bool get reflex => widget.mode == PracticeMode.reflex;
  bool get enough =>
      writing ||
      widget.cards.map((c) => normalizeAnswer(c.definition)).toSet().length >=
          2;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (reflex &&
        !finished &&
        questions.isNotEmpty &&
        state != AppLifecycleState.resumed) {
      timer?.cancel();
      advance?.cancel();
      if (mounted) setState(() => paused = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    advance?.cancel();
    count.dispose();
    answer.dispose();
    super.dispose();
  }

  void start() {
    final n = int.tryParse(count.text);
    if (n == null || n < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập số câu lớn hơn 0.')));
      return;
    }
    setState(() {
      questions = makeQuestions(widget.cards, n.clamp(1, widget.cards.length));
      index = 0;
      correct = 0;
      checked = false;
      finished = false;
      answers.clear();
      answer.clear();
    });
    tick();
  }

  void tick() {
    timer?.cancel();
    remaining = seconds;
    if (reflex) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => remaining--);
        if (remaining <= 0) check(null);
      });
    }
  }

  void check(String? selected) {
    if ((checked && (writing || reflex)) || finished || paused) return;
    timer?.cancel();
    final expected = writing
        ? questions[index].card.term
        : questions[index].card.definition;
    setState(() {
      checked = true;
      right =
          selected != null &&
          normalizeAnswer(selected) == normalizeAnswer(expected);
      answers[index] = selected;
      correct = questions
          .asMap()
          .entries
          .where(
            (e) =>
                answers[e.key] != null &&
                normalizeAnswer(answers[e.key]!) ==
                    normalizeAnswer(
                      writing ? e.value.card.term : e.value.card.definition,
                    ),
          )
          .length;
    });
    if (reflex) advance = Timer(const Duration(milliseconds: 1400), next);
    if (!writing && !reflex) {
      if (answers.length == questions.length) {
        setState(() => finished = true);
        saveResult();
      } else {
        goTo(questions.asMap().keys.firstWhere((i) => !answers.containsKey(i)));
      }
    }
  }

  void goTo(int target) {
    setState(() {
      index = target;
      checked = answers.containsKey(index);
      right =
          checked &&
          answers[index] != null &&
          normalizeAnswer(answers[index]!) ==
              normalizeAnswer(questions[index].card.definition);
    });
  }

  void next() {
    if (!mounted || paused) return;
    if (index == questions.length - 1) {
      setState(() => finished = true);
      saveResult();
      return;
    }
    setState(() {
      index++;
      checked = false;
      right = false;
      answer.clear();
    });
    tick();
  }

  Future<void> saveResult() async {
    if (saving || saved) return;
    setState(() => saving = true);
    final ok = await widget.onComplete(
      PracticeResult(correct, questions.length),
    );
    if (mounted) {
      setState(() {
        saving = false;
        saved = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.mode.label)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: EdgeInsets.all(mobileInset(context)),
            children: [
              if (widget.cards.isEmpty || !enough) ...[
                const SizedBox(height: 80),
                const Icon(Icons.style_outlined, size: 60, color: purple),
                const SizedBox(height: 24),
                Text(
                  widget.cards.isEmpty
                      ? 'Thêm từ vựng trước khi luyện tập.'
                      : 'Cần ít nhất 2 nghĩa khác nhau để tạo đáp án.',
                ),
              ] else if (questions.isEmpty) ...[
                const SizedBox(height: 28),
                Icon(widget.mode.icon, size: 60, color: purple),
                const SizedBox(height: 24),
                Text(
                  writing
                      ? 'Nhìn nghĩa, viết lại từ.'
                      : reflex
                      ? 'Nhanh tay chọn đáp án.'
                      : 'Sẵn sàng thử sức?',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  writing
                      ? 'Viết từ tiếng Hàn tương ứng. Bạn có thể hiện đáp án để tự ôn tập.'
                      : 'Câu hỏi được trộn ngẫu nhiên. Đáp án sai lấy từ các từ trong danh mục.',
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: count,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số câu hỏi',
                    helperText:
                        'Tối đa ${widget.cards.length} câu; nhập nhiều hơn sẽ dùng tất cả.',
                  ),
                ),
                if (reflex) ...[
                  const SizedBox(height: 20),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 3, label: Text('3 giây')),
                      ButtonSegment(value: 5, label: Text('5 giây')),
                    ],
                    selected: {seconds},
                    onSelectionChanged: (v) =>
                        setState(() => seconds = v.first),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(onPressed: start, child: const Text('Bắt đầu')),
              ] else if (finished) ...[
                const SizedBox(height: 30),
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 70,
                  color: purple,
                ),
                const SizedBox(height: 20),
                Text(
                  '$correct / ${questions.length}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mỗi lượt học là một bước tiến.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  saving
                      ? 'Đang lưu kết quả…'
                      : saved
                      ? 'Đã lưu kết quả trên thiết bị.'
                      : 'Chưa lưu được kết quả. Hãy thử lại.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: saving
                      ? null
                      : saved
                      ? () => Navigator.pop(context)
                      : saveResult,
                  child: Text(saved ? 'Quay lại danh mục' : 'Thử lưu lại'),
                ),
                const SizedBox(height: 24),
                ...questions.asMap().entries.map(
                  (e) => Card(
                    child: ListTile(
                      leading: Icon(
                        answers[e.key] != null &&
                                normalizeAnswer(answers[e.key]!) ==
                                    normalizeAnswer(
                                      writing
                                          ? e.value.card.term
                                          : e.value.card.definition,
                                    )
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                      ),
                      title: Text(e.value.card.term),
                      subtitle: Text(
                        '${e.value.card.definition}\nBạn trả lời: ${answers[e.key] ?? 'Bỏ qua / hết giờ'}',
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Text(
                      'CÂU ${index + 1} / ${questions.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (reflex)
                      Text(
                        '$remaining giây',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: (index + 1) / questions.length),
                const SizedBox(height: 32),
                Text(
                  writing ? 'Viết từ tương ứng với nghĩa' : 'Chọn nghĩa đúng',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  writing
                      ? questions[index].card.definition
                      : questions[index].card.term,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 30),
                if (paused) ...[
                  const Text('Bài luyện đã tạm dừng khi rời ứng dụng.'),
                  FilledButton(
                    onPressed: () {
                      setState(() => paused = false);
                      if (checked) {
                        next();
                      } else {
                        tick();
                      }
                    },
                    child: const Text('Tiếp tục'),
                  ),
                ] else if (writing) ...[
                  TextField(
                    controller: answer,
                    enabled: !checked,
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) {
                      if (checked) {
                        next();
                      } else if (v.trim().isNotEmpty) {
                        check(v);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Gõ từ tiếng Hàn…',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!checked)
                    TextButton(
                      onPressed: () => check(null),
                      child: const Text('Hiện đáp án'),
                    ),
                  if (!checked)
                    FilledButton(
                      onPressed: answer.text.trim().isEmpty
                          ? null
                          : () => check(answer.text),
                      child: const Text('Kiểm tra'),
                    ),
                ] else
                  ...questions[index].options.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: checked && reflex
                            ? null
                            : () => check(e.value),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(18),
                          backgroundColor: reflex
                              ? (checked &&
                                        e.value ==
                                            questions[index].card.definition
                                    ? Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                    : null)
                              : answers[index] == e.value
                              ? purple.withValues(alpha: .12)
                              : null,
                        ),
                        child: Text(
                          '${String.fromCharCode(65 + e.key)}.  ${e.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                if (!writing && !reflex) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: index > 0 ? () => goTo(index - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Câu trước'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: index < questions.length - 1
                            ? () => goTo(index + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Câu tiếp'),
                      ),
                    ],
                  ),
                ],
                if (checked && !paused && (writing || reflex)) ...[
                  const SizedBox(height: 18),
                  Text(
                    right
                        ? 'Chính xác!'
                        : 'Chưa đúng. Đáp án: ${writing ? questions[index].card.term : questions[index].card.definition}',
                    style: TextStyle(
                      color: right ? Colors.green : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!reflex) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: next,
                      child: Text(
                        index == questions.length - 1
                            ? 'Xem kết quả'
                            : 'Tiếp theo',
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
