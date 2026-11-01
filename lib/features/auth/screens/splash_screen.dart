import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../team/providers/team_providers.dart';

/// Shown while the session and team load. The mark sits exactly where the
/// native launch screen shows it, so launch feels like one continuous
/// moment. If loading is slow, a short note fades in; if it fails (for
/// example, no connection), it explains why and offers a retry.
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
      body: Stack(
        children: [
          // Default size (96) matches the mark on the native launch screen.
          const Center(child: BrandMark()),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppDurations.normal),
                    child: error == null
                        ? FadeSlideIn(
                            key: const ValueKey('slow'),
                            delay: const Duration(milliseconds: 1500),
                            child: Text(
                              'Getting your team ready…',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium!.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          )
                        : Column(
                            key: const ValueKey('error'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppException.from(error).message,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FilledButton(
                                onPressed: () =>
                                    ref.invalidate(currentTeamProvider),
                                child: const Text('Try again'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: () => _signOut(ref),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
