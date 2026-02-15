import 'package:dio/dio.dart';
import '../models/app_update_info.dart';

class UpdateService {
  final Dio _dio;
  final String githubOwner;
  final String githubRepo;

  /// Separate Dio instance for downloading APKs (no logger interceptor).
  late final Dio _downloadDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
  ));

  UpdateService(
    this._dio, {
    required this.githubOwner,
    required this.githubRepo,
  });

  /// Fetch the latest release from GitHub.
  /// Returns null if network fails or no release found.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return AppUpdateInfo.fromGitHubRelease(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if [remote] is newer than [current].
  static bool isNewerVersion(String current, String remote) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final remoteParts = remote.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final c = (i < currentParts.length ? currentParts[i] : 0) ?? 0;
      final r = (i < remoteParts.length ? remoteParts[i] : 0) ?? 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Download the APK to [savePath] with progress tracking.
  /// Uses a separate Dio instance without logger interceptors.
  Future<void> downloadApk({
    required String url,
    required String savePath,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    await _downloadDio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
  }
}
