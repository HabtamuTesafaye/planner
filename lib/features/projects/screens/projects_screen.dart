import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../space/widgets/space_switcher.dart';

/// Projects tab. Placeholder until Phase 3b.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      title: 'Projects',
      top: SpaceSwitcher(),
      children: [
        EmptyState(
          icon: Symbols.folder_open,
          message: 'No projects yet.',
          detail: 'Start one from a template and keep its steps here.',
        ),
      ],
    );
  }
}
