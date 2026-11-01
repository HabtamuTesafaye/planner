import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/contact.dart';
import '../providers/outreach_providers.dart';

/// "Mine / Everyone" (team spaces only) and status chips with counts.
class OutreachFilters extends ConsumerWidget {
  const OutreachFilters({
    required this.contacts,
    required this.showMine,
    super.key,
  });

  final List<Contact> contacts;
  final bool showMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(outreachFilterProvider);
    final notifier = ref.read(outreachFilterProvider.notifier);
    int count(ContactStatus s) => contacts.where((c) => c.status == s).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMine) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Everyone')),
              ButtonSegment(value: true, label: Text('Mine')),
            ],
            selected: {filter.mineOnly},
            showSelectedIcon: false,
            onSelectionChanged: (s) => notifier.setMineOnly(mineOnly: s.first),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text('All ${contacts.length}'),
                selected: filter.status == null,
                onSelected: (_) => notifier.setStatus(null),
              ),
              for (final s in ContactStatus.values)
                if (count(s) > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FilterChip(
                    label: Text('${s.label} ${count(s)}'),
                    selected: filter.status == s,
                    onSelected: (on) => notifier.setStatus(on ? s : null),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
