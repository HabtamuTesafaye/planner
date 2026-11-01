import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/app_exception.dart';
import '../../../data/reminders/reminder_service.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../auth/providers/auth_providers.dart';

/// Daily reminder time and theme. Stored on the profile, so they follow the
/// account to a new phone. The reminder itself is scheduled on the device.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(ProfileRepository repo, String userId) action,
  ) async {
    final userId = ref.read(currentUserIdProvider).value;
    if (userId == null) return;
    try {
      await action(ref.read(profileRepositoryProvider), userId);
      ref.invalidate(currentProfileProvider);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Explains why, then asks Android for notification permission. The
  /// reminder time is saved either way; the app works without it.
  Future<bool> _askPermission(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('One gentle reminder a day'),
        content: const Text(
          'Planner can remind you once a day to pick your three tasks. '
          'Android will ask if notifications are OK. You can change this '
          'any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: context.colors.text),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    final granted = await ref.read(reminderServiceProvider).requestPermission();
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are off for Planner. You can allow them in '
            'Android settings.',
          ),
        ),
      );
    }
    return true;
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay? current,
  ) async {
    if (current == null && !await _askPermission(context, ref)) return;
    if (!context.mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Daily reminder',
    );
    if (picked != null && context.mounted) {
      await _save(context, ref, (r, id) => r.setReminderTime(id, picked));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final reminder = profile?.reminderTime;
    final theme = profile?.themeMode ?? ThemeMode.system;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Settings'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Symbols.notifications, color: context.colors.muted),
          title: const Text('Daily reminder'),
          subtitle: Text(
            reminder == null ? 'Off' : reminder.format(context),
            style: context.text.bodySmall,
          ),
          trailing: Switch(
            value: reminder != null,
            onChanged: (on) => on
                ? _pickTime(context, ref, reminder)
                : _save(context, ref, (r, id) => r.setReminderTime(id, null)),
          ),
          onTap: () => _pickTime(context, ref, reminder),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Theme', style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {theme},
          showSelectedIcon: false,
          onSelectionChanged: (s) =>
              _save(context, ref, (r, id) => r.setThemeMode(id, s.first)),
        ),
      ],
    );
  }
}
