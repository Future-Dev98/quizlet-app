import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_localization.dart';
import 'models.dart';
import 'dictionary.dart';

Future<int?> lookupNewCards(
  BuildContext context,
  List<StudyCard> cards,
  WordDictionary dictionary,
  String language, {
  bool wordsSaved = false,
}) async {
  final route = DialogRoute<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _LookupProgress(
      cards: cards,
      dictionary: dictionary,
      language: language,
      wordsSaved: wordsSaved,
    ),
  );
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}

class _LookupProgress extends StatefulWidget {
  const _LookupProgress({
    required this.cards,
    required this.dictionary,
    required this.language,
    required this.wordsSaved,
  });
  final List<StudyCard> cards;
  final WordDictionary dictionary;
  final String language;
  final bool wordsSaved;
  @override
  State<_LookupProgress> createState() => _LookupProgressState();
}

class _LookupProgressState extends State<_LookupProgress> {
  int done = 0;
  bool active = true;
  @override
  void initState() {
    super.initState();
    run();
  }

  Future<void> run() async {
    final missing = await enrichCards(
      widget.cards,
      widget.dictionary,
      widget.language,
      shouldContinue: () => active,
      onProgress: (count, _) {
        if (mounted) setState(() => done = count);
      },
    );
    if (mounted && active) Navigator.pop(context, missing);
  }

  @override
  void dispose() {
    active = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      title: Text(context.l10n.lookingUpWords),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.wordsSaved
                ? context.l10n.wordsSavedLookupNotice
                : context.l10n.dictionaryNetworkNotice,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: widget.cards.isEmpty ? 1 : done / widget.cards.length,
          ),
          const SizedBox(height: 12),
          Text('$done / ${widget.cards.length}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            active = false;
            Navigator.pop(
              context,
              widget.cards.where((c) => c.details == null).length,
            );
          },
          child: Text(
            widget.wordsSaved
                ? context.l10n.skipLookupOnly
                : context.l10n.skipLookup,
          ),
        ),
      ],
    ),
  );
}

class CardDetailsDialog extends StatefulWidget {
  const CardDetailsDialog({
    super.key,
    required this.card,
    required this.dictionary,
    required this.language,
    required this.onSave,
  });
  final StudyCard card;
  final WordDictionary dictionary;
  final String language;
  final Future<bool> Function(WordDetails) onSave;
  @override
  State<CardDetailsDialog> createState() => _CardDetailsDialogState();
}

class _CardDetailsDialogState extends State<CardDetailsDialog> {
  late WordDetails? details = widget.card.details;
  bool loading = false;
  String? error;
  Future<void> lookup() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.dictionary.lookup(
        widget.card.term,
        widget.language,
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => error = context.l10n.noDictionaryEntry);
      } else if (await widget.onSave(result)) {
        if (mounted) setState(() => details = result);
      } else if (mounted) {
        setState(() => error = context.l10n.saveError);
      }
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.dictionaryLookupError);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget section(String title, List<String> values, String empty) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Text(
              empty,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final text in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText(text),
              ),
        ],
      ),
    );
    return AlertDialog(
      title: Text(widget.card.term),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(widget.card.definition),
              if (details == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(l.noSavedDetails),
                ),
              section(
                l.dictionaryMeanings,
                details?.definitions ?? [],
                l.noDictionaryMeanings,
              ),
              section(l.wordUsage, details?.usage ?? [], l.noUsageNotes),
              section(
                l.usageExamples,
                details?.examples ?? [],
                l.noUsageExamples,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  l.wordSynonyms,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              if (details?.synonyms.isNotEmpty == true)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: details!.synonyms
                      .map((s) => Chip(label: Text(s)))
                      .toList(),
                )
              else
                Text(l.noSynonyms),
              if (details != null) ...[
                const SizedBox(height: 20),
                Text(
                  l.dictionarySourceNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SelectableText(
                  details!.sourceUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: details!.sourceUrl),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.sourceCopied)));
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l.copySource),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : lookup,
          child: Text(details == null ? l.lookupDetails : l.refreshDetails),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.closeDetails),
        ),
      ],
    );
  }
}
