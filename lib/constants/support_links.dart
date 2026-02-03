/// External links for supporting the app and community engagement.
/// All links open in external browser to maintain privacy.
class SupportLinks {
  SupportLinks._(); // Private constructor to prevent instantiation.

  // Donation platforms - Replace with your actual links.
  static const String kofiUrl = 'https://ko-fi.com/yourname';
  static const String githubSponsors = 'https://github.com/sponsors/yourname';
  static const String paypalUrl = 'https://paypal.me/yourname';

  // Repository links.
  static const String githubRepo = 'https://github.com/yourname/myledger';
  static const String githubIssues = 'https://github.com/yourname/myledger/issues';

  // App store links - Update with actual IDs.
  static const String appStoreUrl = 'https://apps.apple.com/app/idYOURAPPID';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourname.myledger';

  // Website and contact.
  static const String website = 'https://myledger.app';
  static const String email = 'support@myledger.app';

  /// Validates that all URLs are properly formatted.
  static bool validateUrls() {
    final urls = [
      kofiUrl,
      githubSponsors,
      paypalUrl,
      githubRepo,
      githubIssues,
      appStoreUrl,
      playStoreUrl,
      website,
    ];

    return urls.every((url) => Uri.tryParse(url)?.hasAbsolutePath ?? false);
  }
}
