import 'package:web/web.dart' as web;

/// Navigates the browser to [url].
void redirectToUrl(String url) => web.window.location.href = url;

/// The current page origin, e.g. "http://localhost:56120".
String get webOrigin => web.window.location.origin;
