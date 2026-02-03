import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for launching URLs in external browser.
/// Ensures all external links maintain user privacy.
class UrlLauncherHelper {
  UrlLauncherHelper._(); // Private constructor.

  /// Launches a URL in the external browser with proper error handling.
  ///
  /// Uses LaunchMode.externalApplication to ensure links open
  /// in device's default browser, not in-app webview.
  ///
  /// Parameters:
  ///   - context: BuildContext for showing error messages.
  ///   - url: The URL string to launch.
  ///   - errorMessage: Optional custom error message.
  static Future<void> launchURL(
    BuildContext context,
    String url, {
    String? errorMessage,
  }) async {
    // Validate URL format.
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) {
      if (context.mounted) {
        _showError(context, 'Invalid URL format: $url');
      }
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        throw Exception('No app available to open this URL');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Critical for privacy.
      );

      if (!launched) {
        throw Exception('Failed to launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(
          context,
          errorMessage ?? 'Could not open link. Please try again later.',
        );
      }
    }
  }

  /// Launches email client with optional subject and body.
  static Future<void> launchEmail(
    BuildContext context,
    String email, {
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      }),
    );

    await launchURL(
      context,
      uri.toString(),
      errorMessage: 'Could not open email client',
    );
  }

  /// Encodes query parameters for URI.
  static String? _encodeQueryParameters(Map<String, String> params) {
    if (params.isEmpty) return null;

    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Shows error message using SnackBar.
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
