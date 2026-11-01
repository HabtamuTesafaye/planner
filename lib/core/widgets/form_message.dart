import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Inline message under a form: errors in the attention color, notices in
/// muted text. Announced by TalkBack when it appears.
class FormMessage extends StatelessWidget {
  const FormMessage({
    required this.message,
    this.isError = true,
    this.action,
    super.key,
  });

  final String? message;
  final bool isError;

  /// Optional small action, for example "Send the email again".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isError ? colors.attention : colors.muted;
    return AnimatedSize(
      duration: AppDurations.normal,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isError ? Symbols.error : Symbols.info,
                          size: AppSizes.iconSmall,
                          color: color,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            message!,
                            style: context.text.bodyMedium!.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ?action,
                  ],
                ),
              ),
            ),
    );
  }
}
