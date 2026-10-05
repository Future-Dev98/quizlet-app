import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'app_layout.dart';
import 'app_theme.dart';
import 'storage.dart';
import 'editor.dart';
import 'study.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const purple = Color(0xFF6961E8);
const ink = Color(0xFF222642);
const mint = Color(0xFFCDEEDF);
typedef UpdateData = Future<bool> Function(StudyData);

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.storage});
  final StudyStorage? storage;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final storage = widget.storage ?? LocalStudyStorage();
  StudyData? data;
  Object? error;
  bool saving = false;
  final messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final loaded = await storage.load();
      if (mounted) setState(() => data = loaded);
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<bool> update(StudyData next) async {
    if (saving) return false;
    setState(() => saving = true);
    try {
      await storage.save(next);
      if (mounted) setState(() => data = next);
      return true;
    } catch (_) {
      messenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa lưu được dữ liệu. Kiểm tra dung lượng máy và thử lại.',
          ),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  ThemeData theme(Brightness brightness) => buildAppTheme(brightness);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Từ Vựng',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    themeMode: data?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
    home: data == null
        ? Scaffold(
            body: SafeArea(
              child: Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_off_outlined, size: 48),
                            const SizedBox(height: 20),
                            const Text(
                              'Không đọc được dữ liệu. Dữ liệu hiện có được giữ lại.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: load,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          )
        : HomePage(data: data!, update: update, saving: saving),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.data,
    required this.update,
    required this.saving,
  });
  final StudyData data;
  final UpdateData update;
  final bool saving;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String query = '';
  String? folderId;
  Future<void> edit([StudySet? set]) async {
    final result = await Navigator.of(context).push<StudySet>(
      MaterialPageRoute(
        builder: (_) => SetEditor(
          initial: set,
          folders: widget.data.folders,
          folderId: folderId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final next = widget.data.copy();
    final i = next.sets.indexWhere((s) => s.id == result.id);
    if (i < 0) {
      next.sets.add(result);
    } else {
      next.sets[i] = result;
    }
    await widget.update(next);
  }

  void open(StudySet set) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SetPage(
        initial: set,
        folders: widget.data.folders,
        settings: widget.data.settings,
        onSettings: (settings) =>
            widget.update(widget.data.copy()..settings = settings),
        onSave: (changed) async {
          final next = widget.data.copy();
          final i = next.sets.indexWhere((s) => s.id == changed.id);
          if (i < 0) return false;
          next.sets[i] = changed;
          return widget.update(next);
        },
        onResult: (changed, score, total) async {
          final next = widget.data.copy();
          final i = next.sets.indexWhere((s) => s.id == changed.id);
          if (i < 0) return false;
          next.sets[i] = changed;
          next.sessions++;
          next.correct += score;
          next.answers += total;
          return widget.update(next);
        },
        onDelete: () => widget.update(
          widget.data.copy()..sets.removeWhere((s) => s.id == set.id),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: tab == 2 ? settings() : library(),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style),
          label: 'Thư viện',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    ),
  );
  Widget library() {
    if (!widget.data.folders.any((f) => f.id == folderId)) folderId = null;
    final sets =
        widget.data.sets
            .where(
              (s) =>
                  (query.isNotEmpty || s.folderId == folderId) &&
                  '${s.title} ${s.cards.map((c) => '${c.term} ${c.definition}').join(' ')}'
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final folders = widget.data.folders
        .where((f) => f.parentId == folderId)
        .toList();
    final learned = widget.data.sets.fold(0, (n, s) => n + s.learned);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        mobileInset(context),
        20,
        mobileInset(context),
        110,
      ),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.layers_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'từ vựng',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            const Icon(Icons.offline_pin_outlined, color: Color(0xFF479677)),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.saving ? null : () => edit(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo danh mục'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tab == 0 ? 'Mỗi từ mới là một\nbước tiến nhỏ.' : 'Thư viện của bạn',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Học theo nhịp của bạn. Ghi nhớ mỗi ngày.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (tab == 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: mint, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HÀNH TRÌNH CỦA BẠN',
                        style: TextStyle(
                          color: mint,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$learned thẻ đã thuộc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.data.sessions} lượt học · ${widget.data.sets.length} danh mục',
                  style: const TextStyle(color: Color(0xFFBDBDD5)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.data.sets.isEmpty
                        ? () => edit()
                        : () => open(
                            widget.data.sets.firstWhere(
                              (s) => s.cards.isNotEmpty && s.progress < 1,
                              orElse: () => widget.data.sets.first,
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: ink,
                    ),
                    child: const Text('Tiếp tục học   →'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Tìm danh mục, từ vựng…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (folderId != null)
              IconButton(
                tooltip: 'Thư mục cha',
                onPressed: () => setState(
                  () => folderId = widget.data.folders
                      .firstWhere((f) => f.id == folderId)
                      .parentId,
                ),
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Text(
                folderId == null
                    ? 'Thư viện của bạn'
                    : widget.data.folderPath(folderId),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Tạo thư mục',
              onPressed: widget.saving ? null : () => editFolder(),
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (query.isEmpty)
          ...folders.map(
            (f) => Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFFD9AB5B),
                ),
                title: Text(f.name),
                subtitle: const Text('Mở thư mục'),
                onTap: () => setState(() => folderId = f.id),
                trailing: IconButton(
                  tooltip: 'Sửa thư mục',
                  onPressed: () => editFolder(f),
                  icon: const Icon(Icons.more_horiz),
                ),
              ),
            ),
          ),
        if (sets.isEmpty && folders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Chưa có danh mục phù hợp. Tạo danh mục để bắt đầu.'),
          ),
        ...sets.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(s),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.style_rounded,
                            color: purple,
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.subject,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (s.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${s.cards.length} thẻ · ${s.learned} đã thuộc',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: s.progress,
                          minHeight: 5,
                          color: purple,
                          backgroundColor: purple.withValues(alpha: .12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> editFolder([Folder? folder]) async {
    final name = TextEditingController(text: folder?.name);
    String? parent = folder?.parentId ?? folderId;
    bool descendant(Folder f) {
      String? id = f.id;
      while (id != null) {
        if (id == folder?.id) return true;
        id = widget.data.folders.firstWhere((v) => v.id == id).parentId;
      }
      return false;
    }

    final choices = widget.data.folders.where((f) => !descendant(f)).toList();
    final action = await showSettledDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, state) => AlertDialog(
          title: Text(folder == null ? 'Tạo thư mục' : 'Sửa thư mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên thư mục'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: parent,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Thư mục cha'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Thư viện gốc'),
                  ),
                  ...choices.map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(
                        widget.data.folderPath(f.id),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => state(() => parent = v),
              ),
            ],
          ),
          actions: [
            if (folder != null)
              TextButton(
                onPressed: () => Navigator.pop(context, 'delete'),
                child: const Text('Xóa thư mục trống'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) Navigator.pop(context, 'save');
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    final value = name.text.trim();
    name.dispose();
    if (action == null || !mounted) return;
    final next = widget.data.copy();
    if (action == 'delete') {
      if (next.folders.any((f) => f.parentId == folder!.id) ||
          next.sets.any((s) => s.folderId == folder!.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chỉ xóa được thư mục trống. Hãy chuyển nội dung ra trước.',
            ),
          ),
        );
        return;
      }
      next.folders.removeWhere((f) => f.id == folder!.id);
    } else if (folder == null) {
      next.folders.add(Folder(newId(), value, parent));
    } else {
      final f = next.folders.firstWhere((f) => f.id == folder.id);
      f.name = value;
      f.parentId = parent;
    }
    await widget.update(next);
  }

  Widget settings() => ListView(
    padding: EdgeInsets.all(mobileInset(context)),
    children: [
      const SizedBox(height: 12),
      Text('Góc học tập', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      const Text('Kiến thức của bạn, hành trình của bạn.'),
      const SizedBox(height: 28),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.insights, size: 42, color: purple),
              const SizedBox(height: 16),
              Text(
                '${widget.data.sessions} lượt học hoàn thành',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Độ chính xác: ${widget.data.answers == 0 ? 0 : (widget.data.correct / widget.data.answers * 100).round()}%',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('Settings · Theme', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        'Chọn màu nền và chữ cho ứng dụng.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('Default'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('Dark'),
          ),
        ],
        selected: {widget.data.darkMode},
        onSelectionChanged: widget.saving
            ? null
            : (values) =>
                  widget.update(widget.data.copy()..darkMode = values.first),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mỗi từ mới là một bước tiến nhỏ.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.darkMode
                  ? 'Nền tối · Chữ sáng'
                  : 'Nền sáng · Chữ tối',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.copy_all),
        title: const Text('Sao chép bản sao lưu'),
        subtitle: const Text('Bộ từ, thư mục, cài đặt và tiến độ (JSON)'),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.data.encode()));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đã sao chép bản sao lưu. Bản ghi âm được lưu riêng trên máy.',
                ),
              ),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.download_outlined),
        title: const Text('Khôi phục từ JSON'),
        onTap: widget.saving ? null : restore,
      ),
      const SizedBox(height: 24),
      Text(
        'Dữ liệu lưu riêng trên thiết bị, không cần tài khoản. Gỡ app có thể xóa dữ liệu; hãy sao lưu trước khi đổi máy. Chấm phát âm cần máy chủ Azure và kết nối mạng.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    ],
  );
  Future<void> restore() async {
    final input = TextEditingController();
    final source = await showSettledDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: TextField(
          controller: input,
          maxLines: 7,
          decoration: const InputDecoration(hintText: 'Dán JSON đã sao lưu…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Kiểm tra'),
          ),
        ],
      ),
    );
    input.dispose();
    if (source == null || !mounted) return;
    try {
      final next = StudyData.decode(source);
      final yes = await confirm(
        context,
        'Thay thế dữ liệu hiện tại?',
        'Bản sao lưu có ${next.sets.length} danh mục. Toàn bộ từ vựng và tiến độ hiện tại sẽ được thay thế.',
      );
      if (yes) await widget.update(next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'JSON không hợp lệ. Dữ liệu hiện tại được giữ nguyên.',
            ),
          ),
        );
      }
    }
  }
}

Future<bool> confirm(BuildContext context, String title, String text) async =>
    await showSettledDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    ) ??
    false;

/// Wait until the dialog has left the tree before releasing its controllers.
Future<T?> showSettledDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}
