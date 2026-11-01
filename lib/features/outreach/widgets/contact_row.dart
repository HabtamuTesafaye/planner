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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
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
                      _StatusPill(status: contact.status, onTap: onStatus),
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

/// Soft tinted status label; tap to change. Won leads read green, dropped
/// ones muted, open ones in the accent tint. The word always says it, so
/// color is never the only signal.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.onTap});

  final ContactStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (status) {
      ContactStatus.paid => (colors.successSoft, colors.success),
      ContactStatus.dead => (colors.surfaceSunken, colors.muted),
      _ => (colors.accentSoft, colors.accentText),
    };
    return Semantics(
      button: true,
      label: 'Status ${status.label}. Double tap to change.',
      excludeSemantics: true,
      // The touch area is 48 dp tall; only the small pill inside is painted.
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: bg,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.label,
                      style: context.text.labelMedium!.copyWith(color: fg),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Symbols.expand_more,
                      size: AppSizes.tagIcon,
                      color: fg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
