import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../team/providers/team_providers.dart';

/// Shown while the session and team load. If the team cannot be loaded
/// (for example, no connection), it explains why and offers a retry.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  Future<void> _signOut(WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AppException catch (e, s) {
      Log.error('Sign out failed', e, s);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(currentTeamProvider);
    final error = team.hasError && !team.isLoading ? team.error : null;
    final text = context.text;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl * 2,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                Text('Planner', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.xl),
                if (error == null)
                  const SkeletonList()
                else ...[
                  Text(AppException.from(error).message, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () => ref.invalidate(currentTeamProvider),
                    child: const Text('Try again'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _signOut(ref),
                    child: const Text('Sign out'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
