import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Circular animated checkbox used for tasks.
///
/// The visible circle is 26 dp; the tap area is 48 dp. TalkBack reads it
/// as a checkbox with [label] and its checked state.
class CircleCheck extends StatelessWidget {
  const CircleCheck({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;

  /// Null disables the control.
  final ValueChanged<bool>? onChanged;

  /// What is being checked, for screen readers (for example the task title).
  final String label;

  static const double _size = AppSizes.checkCircle;

  /// Light haptic on completing (a small reward), a softer tick on undo.
  /// Follows the system "touch feedback" setting.
  void _toggle() {
    final next = !value;
    // Fire and forget: haptics never block the UI.
    unawaited(
      next ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick(),
    );
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final borderColor = value
        ? colors.success
        : (enabled ? colors.border : colors.divider);

    return Semantics(
      checked: value,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? _toggle : null,
      child: InkResponse(
        onTap: enabled ? _toggle : null,
        radius: AppSizes.touchTarget / 2,
        child: SizedBox.square(
          dimension: AppSizes.touchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOutCubic,
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? colors.success : Colors.transparent,
                border: Border.all(
                  color: borderColor,
                  width: AppSizes.ringStroke,
                ),
              ),
              child: AnimatedSwitcher(
                duration: AppDurations.normal,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: value
                    ? Icon(
                        Symbols.check,
                        key: const ValueKey('checked'),
                        size: AppSizes.checkMark,
                        weight: 600,
                        color: colors.surface,
                      )
                    : const SizedBox.shrink(key: ValueKey('unchecked')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
