/// Parses and matches customer PIN codes against admin-configured rules.
///
/// Rules are stored as trimmed strings:
/// - Exact match: `560088`
/// - Prefix match: `5600*` (asterisk = "starts with" the preceding characters)
class PincodeServiceArea {
  PincodeServiceArea._();

  static final RegExp _splitPins = RegExp(r'[,\n;]+');

  /// Splits a comma/newline-separated PIN field into individual rules.
  static List<String> parseRulesFromRaw(String raw) {
    final out = <String>[];
    for (final part in raw.split(_splitPins)) {
      final t = part.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  /// Builds the flat rule list from Firestore [deliveryZones] (list of maps).
  static List<String> rulesFromDeliveryZones(dynamic zones) {
    if (zones is! List) return [];
    final out = <String>[];
    for (final z in zones) {
      if (z is! Map) continue;
      final raw = z['pinCodes']?.toString() ?? '';
      out.addAll(parseRulesFromRaw(raw));
    }
    return out;
  }

  /// Whether [pin] (typically 6 digits) is allowed by [rules].
  static bool pinMatchesAnyRule(String pin, List<String> rules) {
    final p = pin.trim();
    if (p.isEmpty || rules.isEmpty) return false;
    for (final rule in rules) {
      if (_matchesRule(p, rule)) return true;
    }
    return false;
  }

  static bool _matchesRule(String pin, String rule) {
    final r = rule.trim();
    if (r.isEmpty) return false;
    if (r.endsWith('*')) {
      final prefix = r.substring(0, r.length - 1).trim();
      if (prefix.isEmpty) return false;
      return pin.startsWith(prefix);
    }
    return pin == r;
  }

  /// Expands one [rule] into concrete 6-digit PINs for a dropdown (India-style).
  /// Exact `560088` → one PIN. `5600*` → 560000–560099. Large ranges (e.g. `56*`) are skipped.
  static List<String> expandRuleToPins(String rule, {int maxPins = 200}) {
    final r = rule.trim();
    if (r.isEmpty) return [];
    if (!r.endsWith('*')) {
      if (r.length == 6 && RegExp(r'^\d{6}$').hasMatch(r)) return [r];
      return [];
    }
    final prefix = r.substring(0, r.length - 1).trim();
    if (prefix.isEmpty || !RegExp(r'^\d+$').hasMatch(prefix)) return [];
    if (prefix.length > 6) return [];
    final start = int.parse(prefix.padRight(6, '0'));
    final end = int.parse(prefix.padRight(6, '9'));
    final count = end - start + 1;
    if (count > maxPins) return [];
    final out = <String>[];
    for (var i = start; i <= end && out.length < maxPins; i++) {
      out.add(i.toString().padLeft(6, '0'));
    }
    return out;
  }

  /// All PINs to offer in a dropdown, sorted, deduped, capped for performance.
  /// [maxPerRule] must cover e.g. `560*` (1000 PINs) so common India patterns work.
  static List<String> dropdownPinsFromRules(
    List<String> rules, {
    int maxPerRule = 1200,
    int maxTotal = 2500,
  }) {
    final set = <String>{};
    for (final rule in rules) {
      for (final p in expandRuleToPins(rule, maxPins: maxPerRule)) {
        if (set.length >= maxTotal) break;
        set.add(p);
      }
      if (set.length >= maxTotal) break;
    }
    final list = set.toList()..sort();
    return list;
  }
}
