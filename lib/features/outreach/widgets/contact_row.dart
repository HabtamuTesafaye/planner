import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/contact.dart';
import '../outreach_logic.dart';

/// One lead: name, business and owner, status (tap to change), follow-up
/// date (attention color when overdue) and a one-tap "Followed up".
class ContactRow extends StatelessWidget {
  const ContactRow({
    required this.contact,
    required this.today,
    required this.ownerName,
    required this.onOpen,
    required this.onStatus,
    required this.onFollowedUp,
    super.key,
  });

  final Contact contact;
  final DateTime today;
  final String? ownerName;
  final VoidCallback onOpen;
  final VoidCallback onStatus;
  final VoidCallback onFollowedUp;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final overdue = isOverdue(contact, today);
    final date = contact.nextFollowUp;
    final details = [
      if (contact.business.isNotEmpty) contact.business,
      ?ownerName,
      if (contact.price != null) Money.etb(contact.price!),
    ].join(' · ');

    return InkWell(
      onTap: onOpen,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: text.titleMedium),
                  if (details.isNotEmpty) Text(details, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ActionChip(
                        label: Text(contact.status.label),
                        onPressed: onStatus,
                        tooltip: 'Change status',
                      ),
                      if (date != null && !contact.status.isClosed)
                        Text(
                          followUpText(date, today),
                          style: text.labelMedium!.copyWith(
                            color: overdue ? colors.attention : colors.muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!contact.status.isClosed)
              IconButton(
                onPressed: onFollowedUp,
                tooltip: 'Followed up today',
                icon: Icon(
                  Symbols.event_available,
                  color: overdue ? colors.attention : colors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
