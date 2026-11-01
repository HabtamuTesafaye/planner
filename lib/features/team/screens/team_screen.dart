import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';

/// Team tab. Placeholder until its phase is built.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      title: 'Team',
      children: [
        EmptyState(
          icon: Symbols.group,
          message: 'Your team shows up here.',
          detail: "Once you create or join a team, you'll see each other's progress.",
        ),
      ],
    );
  }
}
