/// Bundled images live under [singup/] per [pubspec.yaml]. Older code and
/// Firestore documents may still reference [signup/] or [homesign.PNG].
String normalizeBundledAssetPath(String raw) {
  var p = raw.trim();
  if (p.isEmpty) {
    return 'singup/homebg.PNG';
  }
  if (p.startsWith('signup/')) {
    p = 'singup/${p.substring('signup/'.length)}';
  }
  p = p.replaceAll('homesign.PNG', 'homebg.PNG');
  return p;
}
