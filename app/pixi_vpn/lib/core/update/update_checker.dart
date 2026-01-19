class UpdateInfo {
  final String version;
  final String title;
  final String content;
  final String url;
  final bool force;

  UpdateInfo({
    required this.version,
    required this.title,
    required this.content,
    required this.url,
    required this.force,
  });
}

abstract class UpdateChecker {
  Future<UpdateInfo?> fetchUpdateInfo();
}
