String? sanitizeCoverUrl(String? url) {
  if (url == null || url.isEmpty) {
    return url;
  }

  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.queryParameters.isEmpty) {
    return url;
  }

  final params = Map<String, String>.from(parsed.queryParameters);
  final keysToRemove = params.keys
      .where((key) => key.toLowerCase() == 'referer')
      .toList();
  if (keysToRemove.isEmpty) {
    return url;
  }
  for (final key in keysToRemove) {
    params.remove(key);
  }

  final sanitized = parsed.replace(
    queryParameters: params.isEmpty ? null : params,
  );
  return sanitized.toString();
}
