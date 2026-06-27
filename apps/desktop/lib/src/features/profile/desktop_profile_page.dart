import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import '../../shared/desktop_design_system.dart';

class DesktopProfilePage extends ConsumerWidget {
  const DesktopProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cá nhân',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          authState.when(
            data: (user) {
              if (user == null) {
                return _buildNotLoggedIn(ref);
              }
              return _buildProfile(context, ref, user);
            },
            loading: () =>
                const CircularProgressIndicator(color: DS.primary),
            error: (_, _) => _buildNotLoggedIn(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập để đồng bộ dữ liệu',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(authServiceProvider).signInWithGoogle();
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Đăng nhập với Google'),
            style: FilledButton.styleFrom(
              backgroundColor: DS.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, dynamic user) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: DS.surfaceLight,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person_rounded,
                      color: DS.textMuted, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Người dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: const TextStyle(
                      color: DS.textMuted,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded,
                size: 18, color: Colors.redAccent),
            label: const Text('Đăng xuất',
                style: TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
