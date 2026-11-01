import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../../../data/models/team_member.dart';

/// Asks before leaving and says exactly what will happen.
Future<bool> confirmLeaveSpace(
  BuildContext context, {
  required String spaceName,
  required List<TeamMember> members,
  required String? myUserId,
}) async {
  final others = members.where((m) => m.userId != myUserId).toList();
  final iAmOwner = members.any((m) => m.userId == myUserId && m.isOwner);

  final String consequence;
  if (others.isEmpty) {
    consequence =
        "You're the only member, so the space and everything in it "
        'will be deleted.';
  } else if (iAmOwner) {
    consequence =
        '${others.first.displayName} becomes the owner. You can join again '
        'later with the invite code.';
  } else {
    consequence = 'You can join again later with the invite code.';
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Leave $spaceName?'),
      content: Text(consequence),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: context.colors.text),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.attention,
          ),
          child: const Text('Leave space'),
        ),
      ],
    ),
  );
  return result ?? false;
}
