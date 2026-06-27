class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final String tagName;
  final DateTime publishedAt;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.tagName,
    required this.publishedAt,
  });

  factory AppUpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    // Find the first .apk asset
    final assets = json['assets'] as List<dynamic>? ?? [];
    String downloadUrl = '';
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        break;
      }
    }

    return AppUpdateInfo(
      latestVersion: version,
      downloadUrl: downloadUrl,
      releaseNotes: json['body'] as String? ?? '',
      tagName: tagName,
      publishedAt: DateTime.tryParse(
            json['published_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
