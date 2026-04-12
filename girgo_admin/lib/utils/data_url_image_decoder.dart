import 'dart:convert';
import 'dart:typed_data';

/// Decodes `data:image/...;base64,...` into bytes with a small in-memory cache.
class DataUrlImageDecoder {
  static const int maxEntries = 30;
  static final _cache = <String, Uint8List>{};
  static final _lruKeys = <String>[];

  static Uint8List decode(String dataUrl) {
    if (!dataUrl.startsWith('data:') || dataUrl.isEmpty) return Uint8List(0);

    final cached = _cache[dataUrl];
    if (cached != null) {
      _touch(dataUrl);
      return cached;
    }

    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) return Uint8List(0);
      final base64Part = dataUrl.substring(commaIndex + 1);
      final bytes = base64Decode(base64Part);

      _cache[dataUrl] = bytes;
      _lruKeys.add(dataUrl);
      if (_lruKeys.length > maxEntries) {
        final oldestKey = _lruKeys.removeAt(0);
        _cache.remove(oldestKey);
      }
      return bytes;
    } catch (_) {
      return Uint8List(0);
    }
  }

  static void _touch(String key) {
    final i = _lruKeys.indexOf(key);
    if (i >= 0) {
      _lruKeys.removeAt(i);
      _lruKeys.add(key);
    }
  }
}

