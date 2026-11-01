import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// Today tab. Placeholder until its phase is built.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      title: 'Today',
      children: [
        EmptyState(
          icon: Symbols.edit_note,
          message: 'Nothing planned yet.',
          detail: 'Pick up to three things that matter today.',
        ),
      ],
    );
  }
}
