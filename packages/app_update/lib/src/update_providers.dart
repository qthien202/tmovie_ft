import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:core/core.dart';

import 'app_update_info.dart';
import 'update_service.dart';

/// GitHub release-backed update service. Reuses the shared [dioProvider].
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    ref.watch(dioProvider),
    githubOwner: 'qthien202',
    githubRepo: 'tmovie_ft',
  );
});

/// Checks GitHub for a newer release than the currently installed version.
/// Returns null when up-to-date, on network failure, or when no APK asset exists.
final appUpdateCheckProvider =
    FutureProvider.autoDispose<AppUpdateInfo?>((ref) async {
  final service = ref.watch(updateServiceProvider);
  final packageInfo = await PackageInfo.fromPlatform();

  // Last segment of the application id, e.g. com.thientech.mobile -> "mobile".
  // Used to pick this app's APK from a release that bundles several apps.
  final appKeyword = packageInfo.packageName.split('.').last;

  final info = await service.checkForUpdate(apkKeyword: appKeyword);
  if (info == null || info.downloadUrl.isEmpty) return null;

  if (UpdateService.isNewerVersion(packageInfo.version, info.latestVersion)) {
    return info;
  }
  return null;
});

enum UpdateDownloadStatus { idle, downloading, downloaded, installing, error }

class UpdateDownloadState {
  final UpdateDownloadStatus status;
  final double progress;
  final String? errorMessage;
  final String? apkFilePath;

  const UpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
    this.apkFilePath,
  });

  UpdateDownloadState copyWith({
    UpdateDownloadStatus? status,
    double? progress,
    String? errorMessage,
    String? apkFilePath,
  }) {
    return UpdateDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      apkFilePath: apkFilePath ?? this.apkFilePath,
    );
  }
}

class UpdateDownloadNotifier extends StateNotifier<UpdateDownloadState> {
  final UpdateService _updateService;
  CancelToken? _cancelToken;

  UpdateDownloadNotifier(this._updateService)
      : super(const UpdateDownloadState());

  Future<void> startDownload(String downloadUrl) async {
    _cancelToken = CancelToken();
    state = state.copyWith(
      status: UpdateDownloadStatus.downloading,
      progress: 0.0,
    );

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/tmovie_update.apk';

      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await _updateService.downloadApk(
        url: downloadUrl,
        savePath: savePath,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(progress: received / total);
          }
        },
      );

      state = state.copyWith(
        status: UpdateDownloadStatus.downloaded,
        apkFilePath: savePath,
        progress: 1.0,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        state = const UpdateDownloadState();
      } else {
        state = state.copyWith(
          status: UpdateDownloadStatus.error,
          errorMessage: 'Tải thất bại',
        );
      }
    }
  }

  Future<void> installApk() async {
    if (state.apkFilePath == null) return;
    state = state.copyWith(status: UpdateDownloadStatus.installing);

    try {
      // Native channel name is derived per-app from the package id so the
      // same logic works on both com.thientech.tv and com.thientech.mobile.
      final packageInfo = await PackageInfo.fromPlatform();
      final channel = MethodChannel('${packageInfo.packageName}/updater');
      await channel.invokeMethod('installApk', {'filePath': state.apkFilePath});
    } catch (e) {
      state = state.copyWith(
        status: UpdateDownloadStatus.error,
        errorMessage: 'Cài đặt thất bại',
      );
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    state = const UpdateDownloadState();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}

final updateDownloadProvider = StateNotifierProvider.autoDispose<
    UpdateDownloadNotifier, UpdateDownloadState>((ref) {
  return UpdateDownloadNotifier(ref.watch(updateServiceProvider));
});
