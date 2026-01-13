import 'package:get/get_utils/src/platform/platform.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches an external link with platform-aware defaults.
/// Returns `true` if launch succeeded, `false` otherwise.
Future<bool> launchExternalLink(Uri uri) async {
  // Normalize URI and strip whitespace
  final normalized = uri.toString().trim();
  if (normalized.isEmpty) return false;

  uri = Uri.parse(normalized);

  // Ensure scheme so macOS can open (e.g., add https if missing)
  if (uri.scheme.isEmpty) {
    uri = uri.replace(scheme: 'https');
  }

  final preferredMode =
      GetPlatform.isMacOS ? LaunchMode.platformDefault : LaunchMode.externalApplication;

  for (final mode in <LaunchMode>[
    preferredMode,
    LaunchMode.platformDefault,
    LaunchMode.externalApplication,
    LaunchMode.inAppBrowserView,
  ]) {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) return true;
    } catch (_) {
      // Try next mode
    }
  }
  return false;
}
