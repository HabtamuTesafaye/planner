import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// Money tab. Placeholder until its phase is built.
class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      title: 'Money',
      children: [
        EmptyState(
          icon: Symbols.payments,
          message: 'No income logged this month.',
          detail: 'Entries you add count toward the monthly target.',
        ),
      ],
    );
  }
}
