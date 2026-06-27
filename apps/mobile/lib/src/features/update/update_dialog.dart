import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_update/app_update.dart';
import 'package:design_system/design_system.dart';

/// Material update dialog for the mobile app. Mirrors the TV update flow but
/// uses touch-friendly Material controls. Consumes the shared providers in
/// `package:app_update` (download state + install via native channel).
class UpdateDialog extends ConsumerWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(updateDownloadProvider);

    return Dialog(
      backgroundColor: AppColors.container,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryValue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.primaryValue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phiên bản mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${updateInfo.latestVersion}',
                        style: const TextStyle(
                          color: AppColors.primaryValue,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildContent(context, ref, download),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UpdateDownloadState state,
  ) {
    final notifier = ref.read(updateDownloadProvider.notifier);

    switch (state.status) {
      case UpdateDownloadStatus.downloading:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryValue),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đang tải xuống...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${(state.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.primaryValue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: notifier.cancelDownload,
                child: const Text('Huỷ'),
              ),
            ),
          ],
        );

      case UpdateDownloadStatus.downloaded:
        return AppButton(
          label: 'Cài đặt ngay',
          icon: Icons.install_mobile_rounded,
          expanded: true,
          onPressed: notifier.installApk,
        );

      case UpdateDownloadStatus.installing:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryValue,
                ),
              ),
              SizedBox(width: 14),
              Text(
                'Đang mở trình cài đặt...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

      case UpdateDownloadStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              state.errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _idleActions(context, notifier),
          ],
        );

      case UpdateDownloadStatus.idle:
        return _idleActions(context, notifier);
    }
  }

  Widget _idleActions(BuildContext context, UpdateDownloadNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: AppButton.ghost(
            label: 'Để sau',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'Cập nhật ngay',
            onPressed: () => notifier.startDownload(updateInfo.downloadUrl),
          ),
        ),
      ],
    );
  }
}
