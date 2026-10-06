import 'package:flutter/material.dart';

import 'app_localization.dart';
import 'models.dart';

class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.card,
    required this.index,
    required this.canReorder,
    required this.busy,
    required this.onDetails,
    required this.onListen,
    required this.onLearned,
    required this.onReview,
    required this.onEdit,
    required this.onDelete,
  });
  final StudyCard card;
  final int index;
  final bool canReorder, busy;
  final VoidCallback onDetails, onListen, onLearned, onReview, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: card.mastered
                ? colors.primary.withValues(alpha: .4)
                : colors.outlineVariant.withValues(alpha: .45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: l.cardDetails,
          child: InkWell(
            onTap: onDetails,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canReorder)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Semantics(
                              label: l.reorderWord,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: .55,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.term,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              card.definition,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        tooltip: l.listenWord,
                        onPressed: onListen,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary.withValues(
                            alpha: .10,
                          ),
                          foregroundColor: colors.primary,
                        ),
                        icon: const Icon(Icons.volume_up_outlined, size: 20),
                      ),
                      PopupMenuButton<String>(
                        tooltip: l.wordActions,
                        enabled: !busy,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'details':
                              onDetails();
                            case 'edit':
                              onEdit();
                            case 'delete':
                              onDelete();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'details',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.info_outline),
                              title: Text(l.cardDetails),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.edit_outlined),
                              title: Text(l.editWordAction),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline,
                                color: colors.error,
                              ),
                              title: Text(
                                l.deleteWord,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.only(left: canReorder ? 28 : 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          label: Text(l.learned),
                          selected: card.mastered,
                          showCheckmark: false,
                          avatar: Icon(
                            card.mastered
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline,
                            size: 16,
                          ),
                          visualDensity: VisualDensity.compact,
                          onSelected: busy ? null : (_) => onLearned(),
                        ),
                        FilterChip(
                          label: Text(l.needsReview),
                          selected: card.starred,
                          showCheckmark: false,
                          avatar: Icon(
                            card.starred
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: card.starred
                                ? colors.tertiary
                                : colors.onSurfaceVariant,
                          ),
                          selectedColor: colors.tertiaryContainer,
                          visualDensity: VisualDensity.compact,
                          onSelected: busy ? null : (_) => onReview(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
