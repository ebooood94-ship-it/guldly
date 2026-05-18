// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Navigates the browser to [url].
void redirectToUrl(String url) => html.window.location.href = url;

/// The current page origin, e.g. "http://localhost:56120".
String get webOrigin => html.window.location.origin;
