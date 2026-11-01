import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';

/// One round, colored shortcut.
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    required this.tone,
  });

  final IconData icon;
  final String label;

  /// What it does, for TalkBack ("New project in Personal").
  final String hint;
  final VoidCallback onTap;
  final QuickTone tone;
}

enum QuickTone { accent, teal, amber, success }

/// A row of round shortcuts at the top of Today: start the things you
/// most often do in the current space without switching tabs.
class QuickActions extends StatelessWidget {
  const QuickActions({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final action in actions)
          Expanded(child: _QuickActionButton(action: action)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (action.tone) {
      QuickTone.accent => (c.accentText, c.accentSoft),
      QuickTone.teal => (c.teal, c.tealSoft),
      QuickTone.amber => (c.amber, c.amberSoft),
      QuickTone.success => (c.success, c.successSoft),
    };
    return Semantics(
      button: true,
      label: action.hint,
      excludeSemantics: true,
      child: InkWell(
        onTap: action.onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Container(
                width: AppSizes.quickAction,
                height: AppSizes.quickAction,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(action.icon, color: fg, size: AppSizes.icon),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: context.text.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icons for the Today shortcuts, kept here so the screen stays short.
abstract final class QuickIcons {
  static const IconData project = Symbols.create_new_folder;
  static const IconData contact = Symbols.person_add;
  static const IconData income = Symbols.add_card;
  static const IconData review = Symbols.rate_review;
}
