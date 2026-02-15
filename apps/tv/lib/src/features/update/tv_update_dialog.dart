import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

import '../../shared/tv_design_system.dart';
import '../../shared/widgets/tv_focus_button.dart';
import 'tv_update_providers.dart';

class TvUpdateDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const TvUpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => TvUpdateDialog(updateInfo: updateInfo),
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
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: TvDesignSystem.surface,
              borderRadius: BorderRadius.circular(TvDesignSystem.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Update icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TvDesignSystem.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TvDesignSystem.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: TvDesignSystem.primary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Phiên bản mới đã sẵn sàng',
                  style: TvDesignSystem.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Version
                Text(
                  'v${updateInfo.latestVersion}',
                  style: TvDesignSystem.titleLarge.copyWith(
                    color: TvDesignSystem.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Release notes
                if (updateInfo.releaseNotes.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Text(
                        updateInfo.releaseNotes,
                        style: TvDesignSystem.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Progress bar
                if (downloadState.status ==
                    UpdateDownloadStatus.downloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      TvDesignSystem.radiusFull,
                    ),
                    child: LinearProgressIndicator(
                      value: downloadState.progress,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        TvDesignSystem.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(downloadState.progress * 100).toStringAsFixed(0)}%',
                    style: TvDesignSystem.labelLarge.copyWith(
                      color: TvDesignSystem.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error message
                if (downloadState.status == UpdateDownloadStatus.error) ...[
                  Text(
                    downloadState.errorMessage ?? 'Đã xảy ra lỗi',
                    style: TvDesignSystem.bodyMedium.copyWith(
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                _buildActionButtons(context, ref, downloadState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    UpdateDownloadState downloadState,
  ) {
    switch (downloadState.status) {
      case UpdateDownloadStatus.idle:
      case UpdateDownloadStatus.error:
        return FocusTraversalGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TvFocusButton(
                icon: Icons.download_rounded,
                label: 'Cập nhật',
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
                label: 'Để sau',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

      case UpdateDownloadStatus.downloading:
        return TvFocusButton(
          icon: Icons.cancel_rounded,
          label: 'Hủy',
          autofocus: true,
          onPressed: () {
            ref.read(updateDownloadProvider.notifier).cancelDownload();
          },
        );

      case UpdateDownloadStatus.downloaded:
        return TvFocusButton(
          icon: Icons.install_mobile_rounded,
          label: 'Cài đặt ngay',
          isPrimary: true,
          autofocus: true,
          onPressed: () {
            ref.read(updateDownloadProvider.notifier).installApk();
          },
        );

      case UpdateDownloadStatus.installing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: TvDesignSystem.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Đang cài đặt...',
              style: TvDesignSystem.labelLarge,
            ),
          ],
        );
    }
  }
}
