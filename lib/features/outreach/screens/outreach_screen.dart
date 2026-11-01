import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// Outreach tab. Placeholder until its phase is built.
class OutreachScreen extends StatelessWidget {
  const OutreachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      title: 'Outreach',
      children: [
        EmptyState(
          icon: Symbols.handshake,
          message: 'No contacts yet.',
          detail: 'Add the first business you message.',
        ),
      ],
    );
  }
}
