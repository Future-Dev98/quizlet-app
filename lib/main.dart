import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'app_layout.dart';
import 'app_localization.dart';
import 'app_theme.dart';
import 'storage.dart';
import 'editor.dart';
import 'study.dart';
import 'dictionary.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const purple = Color(0xFF6961E8);
const ink = Color(0xFF222642);
const mint = Color(0xFFCDEEDF);
typedef UpdateData = Future<bool> Function(StudyData);

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.storage, this.dictionary});
  final StudyStorage? storage;
  final WordDictionary? dictionary;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLocalizations get l10n => messenger.currentContext!.l10n;
  late final storage = widget.storage ?? LocalStudyStorage();
  late final dictionary = widget.dictionary ?? WiktionaryDictionary();
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
        SnackBar(content: Text(l10n.saveError)),
      );
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  ThemeData theme(Brightness brightness) => buildAppTheme(brightness);
  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => context.l10n.appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: data?.settings['interfaceLanguage'] is String
        ? Locale(data!.settings['interfaceLanguage'] as String)
        : null,
    localeListResolutionCallback: (locales, supported) {
      for (final locale in locales ?? <Locale>[]) {
        for (final candidate in supported) {
          if (candidate.languageCode == locale.languageCode) return candidate;
        }
      }
      return const Locale('vi');
    },
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    themeMode: data?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
    home: data == null
        ? Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Scaffold(
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
                                Text(l10n.loadError),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: load,
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              );
            },
          )
        : HomePage(
            data: data!,
            update: update,
            saving: saving,
            dictionary: dictionary,
          ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.data,
    required this.update,
    required this.saving,
    required this.dictionary,
  });
  final StudyData data;
  final UpdateData update;
  final bool saving;
  final WordDictionary dictionary;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppLocalizations get l10n => context.l10n;
  int tab = 0;
  int languageRevision = 0;
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
    final saved = await widget.update(next);
    if (saved && mounted && set == null) open(result);
  }

  void open(StudySet set) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SetPage(
        dictionary: widget.dictionary,
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
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style),
          label: l10n.library,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: l10n.profile,
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
            Text(
              l10n.brand,
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
            label: Text(l10n.createSet),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          tab == 0 ? l10n.homeHeading : l10n.yourLibrary,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.tagline,
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
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: mint, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.journey,
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
                  l10n.learnedCards(learned),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sessionSets(
                    widget.data.sessions,
                    widget.data.sets.length,
                  ),
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
                    child: Text(l10n.continueLearning),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            hintText: l10n.searchSets,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (folderId != null)
              IconButton(
                tooltip: l10n.parentFolder,
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
                    ? l10n.yourLibrary
                    : widget.data.folderPath(folderId),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: l10n.createFolder,
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
                subtitle: Text(l10n.openFolder),
                onTap: () => setState(() => folderId = f.id),
                trailing: IconButton(
                  tooltip: l10n.editFolder,
                  onPressed: () => editFolder(f),
                  icon: const Icon(Icons.more_horiz),
                ),
              ),
            ),
          ),
        if (sets.isEmpty && folders.isEmpty)
          Padding(padding: EdgeInsets.all(24), child: Text(l10n.emptyLibrary)),
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
                        l10n.setProgress(s.cards.length, s.learned),
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
          title: Text(folder == null ? l10n.createFolder : l10n.editFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.folderName),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: parent,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.parentFolder),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.rootLibrary),
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
                child: Text(l10n.deleteEmptyFolder),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) Navigator.pop(context, 'save');
              },
              child: Text(l10n.save),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.folderNotEmpty)));
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
      Text(l10n.studyCorner, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(l10n.yourJourney),
      const SizedBox(height: 28),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.insights, size: 42, color: purple),
              const SizedBox(height: 16),
              Text(
                l10n.completedSessions(widget.data.sessions),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accuracyPercent(
                  widget.data.answers == 0
                      ? 0
                      : (widget.data.correct / widget.data.answers * 100)
                            .round(),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(
        key: ValueKey(
          '${widget.data.settings['interfaceLanguage'] ?? 'system'}-$languageRevision',
        ),
        initialValue:
            widget.data.settings['interfaceLanguage'] as String? ?? 'system',
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.interfaceLanguage),
        items: [
          DropdownMenuItem(value: 'system', child: Text(l10n.systemLanguage)),
          const DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
          const DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: widget.saving
            ? null
            : (value) async {
                final next = widget.data.copy();
                if (value == 'system') {
                  next.settings.remove('interfaceLanguage');
                } else {
                  next.settings['interfaceLanguage'] = value;
                }
                final saved = await widget.update(next);
                if (!saved && mounted) setState(() => languageRevision++);
              },
      ),
      const SizedBox(height: 24),
      Text(l10n.themeSettings, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        l10n.themeHint,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.light_mode_outlined),
            label: Text(l10n.lightTheme),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text(l10n.darkTheme),
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
              l10n.smallStep,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.darkMode ? l10n.darkPreview : l10n.lightPreview,
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
        title: Text(l10n.copyBackup),
        subtitle: Text(l10n.backupHint),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.data.encode()));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.backupCopied)));
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.download_outlined),
        title: Text(l10n.restoreJson),
        onTap: widget.saving ? null : restore,
      ),
      const SizedBox(height: 24),
      Text(
        l10n.privacyNotice,
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
        title: Text(l10n.restoreData),
        content: TextField(
          controller: input,
          maxLines: 7,
          decoration: InputDecoration(hintText: l10n.pasteBackup),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: Text(l10n.quiz),
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
        l10n.replaceData,
        l10n.backupReplaceNotice(next.sets.length),
      );
      if (yes) await widget.update(next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.invalidJson)));
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
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.agree),
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
