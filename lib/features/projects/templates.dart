import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Built-in project templates. They live in the app (not the database):
/// only the key is stored on the project. Keys match the database check.
enum ProjectTemplate {
  blank(
    'blank',
    'Blank',
    'Start empty and add your own steps.',
    Symbols.draft,
    [],
  ),
  client(
    'client',
    'Client project',
    'From first call to final payment.',
    Symbols.handshake,
    [
      'Kick-off call and goals',
      'Send proposal and price',
      'Agree on scope and dates',
      'First draft',
      'Client feedback round',
      'Final delivery',
      'Send invoice',
    ],
  ),
  launch(
    'launch',
    'Product launch',
    'Get something new out the door.',
    Symbols.rocket_launch,
    [
      'Define who it is for',
      'Write the one-line pitch',
      'Build the first version',
      'Test with three people',
      'Prepare launch post',
      'Launch and share',
      'Collect feedback',
    ],
  ),
  content(
    'content',
    'Content plan',
    'A steady rhythm of posts or videos.',
    Symbols.edit_note,
    [
      'List 10 topic ideas',
      'Pick this week’s topic',
      'Draft',
      'Edit and design',
      'Publish',
      'Reply to comments',
    ],
  ),
  event(
    'event',
    'Event',
    'Plan a meetup, workshop or launch party.',
    Symbols.event,
    [
      'Pick date and place',
      'Set a budget',
      'Invite guests',
      'Confirm speakers or helpers',
      'Prepare materials',
      'Day-of checklist',
      'Thank-you follow-up',
    ],
  );

  const ProjectTemplate(
    this.key,
    this.label,
    this.description,
    this.icon,
    this.steps,
  );

  final String key;
  final String label;
  final String description;
  final IconData icon;
  final List<String> steps;

  static ProjectTemplate fromKey(String key) =>
      values.firstWhere((t) => t.key == key, orElse: () => blank);
}
