import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/contact.dart';

/// Quick status change. Returns the chosen status.
Future<ContactStatus?> pickStatus(BuildContext context, ContactStatus current) {
  return showAppSheet<ContactStatus>(
    context,
    SheetFrame(
      title: 'Status',
      children: [
        for (final s in ContactStatus.values)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            title: Text(s.label),
            trailing: s == current
                ? Icon(Symbols.check, color: context.colors.accentText)
                : null,
            onTap: () => Navigator.of(context).pop(s),
          ),
      ],
    ),
  );
}

/// Date picker for the next follow-up, themed and limited to sensible dates.
Future<DateTime?> pickFollowUp(
  BuildContext context, {
  required DateTime today,
  DateTime? initial,
}) {
  final suggested = initial != null && !initial.isBefore(today)
      ? initial
      : today.add(const Duration(days: 3));
  return showDatePicker(
    context: context,
    initialDate: suggested,
    firstDate: today,
    lastDate: DateTime(today.year + 2, today.month, today.day),
    helpText: 'Next follow-up',
  );
}
