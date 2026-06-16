import '../config/env.dart';

/// 이미지 경로/URL을 화면 표시용으로 변환한다.
/// - http(s), content://, file:// → 그대로
/// - 기기 로컬 파일(이미지 피커) → 그대로
/// - 서버 상대 경로 → [Env.serverBaseUrl] 접두
String resolveImageUrl(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('content://') || trimmed.startsWith('file://')) {
    return trimmed;
  }
  if (_isLocalFilePath(trimmed)) return trimmed;
  return trimmed.startsWith('/')
      ? '${Env.serverBaseUrl}$trimmed'
      : '${Env.serverBaseUrl}/$trimmed';
}

bool _isLocalFilePath(String path) {
  if (!path.startsWith('/')) return false;
  const prefixes = [
    '/var/',
    '/private/',
    '/data/',
    '/Users/',
    '/tmp/',
    '/storage/',
  ];
  for (final prefix in prefixes) {
    if (path.startsWith(prefix)) return true;
  }
  return false;
}
