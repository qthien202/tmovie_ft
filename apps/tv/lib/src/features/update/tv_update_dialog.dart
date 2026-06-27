import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_button.dart';
import 'package:app_update/app_update.dart';

class TvUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const TvUpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Update Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) =>
          TvUpdateDialog(updateInfo: updateInfo),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutQuart,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15 * anim1.value,
            sigmaY: 15 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);

    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape)) {
          if (downloadState.status == UpdateDownloadStatus.idle ||
              downloadState.status == UpdateDownloadStatus.error) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 640,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: TvDesignSystem.primary.withValues(alpha: 0.1),
                  blurRadius: 100,
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon + Title row
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: TvDesignSystem.primary.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TvDesignSystem.primary.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            color: TvDesignSystem.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PHIÊN BẢN MỚI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TvDesignSystem.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: TvDesignSystem.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'v${updateInfo.latestVersion}',
                                  style: const TextStyle(
                                    color: TvDesignSystem.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Release Notes (compact)
                    if (updateInfo.releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Text(
                              updateInfo.releaseNotes,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Progress or Actions
                    _buildDynamicContent(context, ref, downloadState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicContent(
    BuildContext context,
    WidgetRef ref,
    UpdateDownloadState state,
  ) {
    if (state.status == UpdateDownloadStatus.downloading) {
      return Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 14,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TvDesignSystem.primary,
                  ),
                ),
              ),
              // Particle effect simulation could go here
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đang tải xuống...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(state.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: TvDesignSystem.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TvFocusButton(
            icon: Icons.close_rounded,
            label: 'HỦY TẢI',
            onPressed: () =>
                ref.read(updateDownloadProvider.notifier).cancelDownload(),
          ),
        ],
      );
    }

    if (state.status == UpdateDownloadStatus.error) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 12),
                Text(
                  state.errorMessage ?? 'Lỗi tải xuống phiên bản mới',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildIdleActions(context, ref),
        ],
      );
    }

    if (state.status == UpdateDownloadStatus.downloaded) {
      return TvFocusButton(
        icon: Icons.install_mobile_rounded,
        label: 'CÀI ĐẶT NGAY',
        isPrimary: true,
        autofocus: true,
        onPressed: () => ref.read(updateDownloadProvider.notifier).installApk(),
      );
    }

    if (state.status == UpdateDownloadStatus.installing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: TvDesignSystem.primary,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(width: 20),
          const Text(
            'ĐANG CHUẨN BỊ CÀI ĐẶT...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

    return _buildIdleActions(context, ref);
  }

  Widget _buildIdleActions(BuildContext context, WidgetRef ref) {
    return FocusTraversalGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TvFocusButton(
            icon: Icons.bolt_rounded,
            label: 'CẬP NHẬT NGAY',
            isPrimary: true,
            autofocus: true,
            onPressed: () {
              ref
                  .read(updateDownloadProvider.notifier)
                  .startDownload(updateInfo.downloadUrl);
            },
          ),
          const SizedBox(width: 24),
          TvFocusButton(
            icon: Icons.schedule_rounded,
            label: 'ĐỂ SAU',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
