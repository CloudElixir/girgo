import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/data_url_image_decoder.dart';

/// Admin: choose up to 8 products for the customer app home "Our Featured Products" grid.
/// Stored in Firestore `app_config/home` as `featuredProductIds` (ordered document IDs).
/// Clear override to restore the app default (first active product per category).
class HomeFeaturedAdminView extends StatefulWidget {
  const HomeFeaturedAdminView({super.key});

  @override
  State<HomeFeaturedAdminView> createState() => _HomeFeaturedAdminViewState();
}

class _HomeFeaturedAdminViewState extends State<HomeFeaturedAdminView> {
  static const int _maxSlots = 8;

  /// One entry per slot; null = empty slot (saved list skips nulls in order).
  final List<String?> _slots = List<String?>.filled(_maxSlots, null);
  final List<String> _titles = List<String>.filled(_maxSlots, '');

  bool _loading = true;

  StreamSubscription<Map<String, dynamic>?>? _homeConfigSub;

  @override
  void initState() {
    super.initState();
    _homeConfigSub = FirestoreService.getHomeFeaturedConfigStream().listen((data) {
      if (!mounted) return;
      final raw = data?['featuredProductIds'];
      setState(() {
        _loading = false;
        for (var i = 0; i < _maxSlots; i++) {
          _slots[i] = null;
          _titles[i] = '';
        }
        if (raw is List) {
          final ids = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
          // Only populate slots with IDs (validation happens in _save)
          for (var i = 0; i < _maxSlots && i < ids.length; i++) {
            _slots[i] = ids[i];
          }
        }
        final rawTitles = data?['featuredProductTitles'];
        if (rawTitles is List) {
          final titles = rawTitles.map((e) => e.toString()).toList();
          for (var i = 0; i < _maxSlots && i < titles.length; i++) {
            _titles[i] = titles[i];
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _homeConfigSub?.cancel();
    super.dispose();
  }

  Future<void> _save(List<Map<String, dynamic>> allProducts) async {
    final used = <String>{};
    final validIds = {for (final p in allProducts) p['id'].toString()};
    final out = <String>[];
    final outTitles = <String>[];
    for (var i = 0; i < _slots.length; i++) {
      final id = _slots[i];
      if (id == null || id.isEmpty) continue;
      if (used.contains(id)) continue;
      // Only add if the product actually exists
      if (!validIds.contains(id)) continue;
      used.add(id);
      out.add(id);
      outTitles.add(_titles[i].trim());
    }
    try {
      await FirestoreService.setHomeFeaturedProductIds(
        out,
        titles: outTitles,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(out.isEmpty
                ? 'Saved (empty — app will use default category grid until you add IDs)'
                : 'Saved ${out.length} featured product(s)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _resetDefault() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use app default?'),
        content: const Text(
          'The home screen will show the first active product in each category '
          '(Milk, Ghee, Paneer, …) again. Your custom list will be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FirestoreService.clearHomeFeaturedOverride();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset — customer app uses default features grid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        final active = products.where((p) => p['isActive'] != false).toList()
          ..sort((a, b) {
            final an = '${a['name'] ?? ''}'.toLowerCase();
            final bn = '${b['name'] ?? ''}'.toLowerCase();
            return an.compareTo(bn);
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home · Our Featured Products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick up to 8 products for the customer app home grid (4 per row). '
                'You can also set a compact display name per slot. Leave a slot empty to skip. '
                'Save — updates the live app over Firestore. Reset — use the built‑in default (one product per category).',
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const LinearProgressIndicator()
              else ...[
                ...List.generate(_maxSlots, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            'Slot ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              DropdownButtonFormField<String?>(
                                value: _slots[index],
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                hint: const Text('— None —'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('— None —'),
                                  ),
                                  ...active.map((p) {
                                    final id = p['id'] as String? ?? '';
                                    final name = p['name'] as String? ?? id;
                                    return DropdownMenuItem<String?>(
                                      value: id,
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _slots[index] = v;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: _titles[index],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  labelText: 'Short name (optional)',
                                  hintText: 'Small label shown in app',
                                ),
                                onChanged: (v) {
                                  _titles[index] = v;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _slotPreview(_slots[index], active),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _loading ? null : () => _save(products),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetDefault,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to app default'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _slotPreview(String? id, List<Map<String, dynamic>> products) {
    if (id == null || id.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined, size: 28),
      );
    }
    Map<String, dynamic>? p;
    for (final e in products) {
      if (e['id'] == id) {
        p = e;
        break;
      }
    }
    if (p == null) {
      return const SizedBox(width: 56, height: 56, child: Icon(Icons.error_outline));
    }
    final img = p['image'] as String? ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: _tinyImage(img),
      ),
    );
  }

  Widget _tinyImage(String img) {
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    if (img.startsWith('data:image')) {
      return Image.memory(
        DataUrlImageDecoder.decode(img),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.phone_android, size: 28),
    );
  }
}
