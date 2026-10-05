import 'package:flutter/material.dart';

import 'models.dart';
import 'app_layout.dart';

class SetEditor extends StatefulWidget {
  const SetEditor({
    super.key,
    this.initial,
    required this.folders,
    this.folderId,
  });
  final StudySet? initial;
  final List<Folder> folders;
  final String? folderId;
  @override
  State<SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<SetEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.initial?.title);
  late final description = TextEditingController(
    text: widget.initial?.description,
  );
  late final order = TextEditingController(
    text: '${widget.initial?.sortOrder ?? 0}',
  );
  late String? folder = widget.initial?.folderId ?? widget.folderId;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Tạo danh mục' : 'Sửa danh mục'),
    ),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: EdgeInsets.all(mobileInset(context)),
          children: [
            TextFormField(
              controller: title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
              validator: (v) => v!.trim().isEmpty ? 'Nhập tên danh mục' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: folder,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Thư mục'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Thư viện gốc'),
                ),
                ...widget.folders.map(
                  (f) => DropdownMenuItem(
                    value: f.id,
                    child: Text(f.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => folder = v,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
              validator: (v) =>
                  int.tryParse(v!) == null ||
                      int.parse(v) < 0 ||
                      int.parse(v) > 1000000
                  ? 'Nhập số từ 0 đến 1000000'
                  : null,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                final set = widget.initial == null
                    ? StudySet(id: newId(), title: title.text.trim(), cards: [])
                    : StudySet.fromJson(widget.initial!.toJson());
                set.title = title.text.trim();
                set.description = description.text.trim();
                set.folderId = folder;
                set.sortOrder = int.parse(order.text);
                Navigator.pop(context, set);
              },
              child: const Text('Lưu danh mục'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ImportResult {
  ImportResult(this.cards, this.duplicates);
  final List<StudyCard> cards;
  final int duplicates;
}

ImportResult parseCards(String text, List<StudyCard> existing) {
  final cards = <StudyCard>[];
  final keys = existing.map((c) => normalizeAnswer(c.term)).toSet();
  int duplicates = 0;
  final lines = text.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^(.+?)(?:\t+| {2,})(.+)$').firstMatch(line);
    final comma = line.indexOf(',');
    final term =
        (match?.group(1) ?? (comma < 0 ? '' : line.substring(0, comma))).trim();
    final meaning =
        (match?.group(2) ?? (comma < 0 ? '' : line.substring(comma + 1)))
            .trim();
    if (term.isEmpty || meaning.isEmpty) {
      throw FormatException(
        'Dòng ${i + 1}: dùng TAB, nhiều dấu cách hoặc dấu phẩy để ngăn từ và nghĩa.',
      );
    }
    if (!keys.add(normalizeAnswer(term))) {
      duplicates++;
      continue;
    }
    cards.add(StudyCard(id: '${newId()}_$i', term: term, definition: meaning));
  }
  if (cards.isEmpty && duplicates == 0) {
    throw const FormatException('Chưa có từ để nhập.');
  }
  return ImportResult(cards, duplicates);
}
