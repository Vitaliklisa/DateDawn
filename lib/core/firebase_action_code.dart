String? findFirebaseActionCode(Uri uri, [int depth = 0]) {
  if (depth > 3) return null;

  final directCode =
      uri.queryParameters['oobCode'] ?? uri.queryParameters['oobcode'];
  if (directCode != null && directCode.isNotEmpty) return directCode;

  for (final key in const ['link', 'deep_link_id', 'continueUrl']) {
    final nested = uri.queryParameters[key];
    if (nested == null) continue;
    final nestedUri = Uri.tryParse(nested);
    if (nestedUri == null) continue;
    final code = findFirebaseActionCode(nestedUri, depth + 1);
    if (code != null) return code;
  }

  return null;
}
