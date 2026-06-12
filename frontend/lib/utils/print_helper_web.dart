// Web-only implementation using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void printReceiptHtmlImpl(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoke URL after a minute to free memory
  Future.delayed(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
}
