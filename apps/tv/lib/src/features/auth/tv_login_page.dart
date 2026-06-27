import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_button.dart';

class TvLoginPage extends ConsumerWidget {
  const TvLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TvDesignSystem.background,
      body: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape)) {
            context.pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TvDesignSystem.primary.withValues(alpha: 0.06),
                    TvDesignSystem.background,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: TvDesignSystem.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TvDesignSystem.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: TvDesignSystem.primary,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'TMovie',
                    style: TvDesignSystem.displayMedium.copyWith(
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đăng nhập để đồng bộ dữ liệu',
                    style: TvDesignSystem.titleLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Google Sign-In Button
                  TvFocusButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Đăng nhập bằng Google',
                    isPrimary: true,
                    autofocus: true,
                    onPressed: () async {
                      final authService = ref.read(authServiceProvider);
                      final user = await authService.signInWithGoogle();
                      if (user != null && context.mounted) {
                        context.go('/home');
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Skip Button
                  TvFocusButton(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Bỏ qua, xem ngay',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
