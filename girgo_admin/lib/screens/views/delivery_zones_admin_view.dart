import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class _ZoneEditors {
  _ZoneEditors({
    required this.name,
    required this.pinCodes,
    required this.minOrder,
    required this.deliveryPrice,
  });

  final TextEditingController name;
  final TextEditingController pinCodes;
  final TextEditingController minOrder;
  final TextEditingController deliveryPrice;

  void dispose() {
    name.dispose();
    pinCodes.dispose();
    minOrder.dispose();
    deliveryPrice.dispose();
  }
}

/// Delivery areas for the customer app checkout PIN filter.
///
/// PINs: comma or newline separated. Suffix `*` = prefix match (e.g. `5600*`).
class DeliveryZonesAdminView extends StatefulWidget {
  const DeliveryZonesAdminView({super.key});

  @override
  State<DeliveryZonesAdminView> createState() => _DeliveryZonesAdminViewState();
}

class _DeliveryZonesAdminViewState extends State<DeliveryZonesAdminView> {
  bool _loading = true;
  final List<_ZoneEditors> _zones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final z in _zones) {
      z.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final config = await FirestoreService.getAppConfig();
      final raw = config['deliveryZones'];
      if (raw is List && raw.isNotEmpty) {
        for (final item in raw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          _zones.add(
            _ZoneEditors(
              name: TextEditingController(text: m['name']?.toString() ?? ''),
              pinCodes: TextEditingController(text: m['pinCodes']?.toString() ?? ''),
              minOrder: TextEditingController(
                text: _numToField(m['minOrder']),
              ),
              deliveryPrice: TextEditingController(
                text: _numToField(m['deliveryPrice']),
              ),
            ),
          );
        }
      } else {
        _zones.add(_emptyZone());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load zones: $e')),
        );
      }
      if (_zones.isEmpty) _zones.add(_emptyZone());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _numToField(dynamic v) {
    if (v == null) return '';
    if (v is num) return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return v.toString();
  }

  _ZoneEditors _emptyZone() {
    return _ZoneEditors(
      name: TextEditingController(text: 'Local Delivery'),
      pinCodes: TextEditingController(),
      minOrder: TextEditingController(text: '0'),
      deliveryPrice: TextEditingController(text: '0'),
    );
  }

  void _addZone() {
    setState(() {
      _zones.add(_emptyZone()..name.text = 'Zone ${_zones.length + 1}');
    });
  }

  void _removeZone(int i) {
    if (_zones.length <= 1) {
      setState(() {
        _zones[i].name.clear();
        _zones[i].pinCodes.clear();
        _zones[i].minOrder.text = '0';
        _zones[i].deliveryPrice.text = '0';
      });
      return;
    }
    setState(() {
      _zones[i].dispose();
      _zones.removeAt(i);
    });
  }

  Set<String> _collectRules(List<Map<String, dynamic>> zonesPayload) {
    final out = <String>{};
    for (final z in zonesPayload) {
      final raw = z['pinCodes']?.toString() ?? '';
      for (final part in raw.split(RegExp(r'[,\n;]+'))) {
        final t = part.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    return out;
  }

  Future<void> _save() async {
    final payload = <Map<String, dynamic>>[];
    for (final z in _zones) {
      final name = z.name.text.trim();
      final pins = z.pinCodes.text.trim();
      if (name.isEmpty && pins.isEmpty) continue;
      final minO = double.tryParse(z.minOrder.text.trim());
      final del = double.tryParse(z.deliveryPrice.text.trim());
      payload.add({
        'name': name.isEmpty ? 'Zone' : name,
        'pinCodes': pins,
        if (minO != null) 'minOrder': minO,
        if (del != null) 'deliveryPrice': del,
      });
    }

    try {
      if (payload.isEmpty) {
        await FirestoreService.updateAppConfig({
          'deliveryZones': FieldValue.delete(),
          'serviceablePinRules': FieldValue.delete(),
        });
      } else {
        final rules = _collectRules(payload).toList()..sort();
        await FirestoreService.updateAppConfig({
          'deliveryZones': payload,
          'serviceablePinRules': rules,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              payload.isEmpty
                  ? 'Delivery zones cleared — all PINs allowed'
                  : 'Delivery zones saved (${payload.length} zone${payload.length == 1 ? '' : 's'})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Delivery zones',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _addZone,
                icon: const Icon(Icons.add),
                label: const Text('Add zone'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customer checkout allows payment only if the PIN matches a rule in this list. '
            'Leave all zones empty and save to allow every PIN.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...List.generate(_zones.length, (i) {
            final z = _zones[i];
            final pinLen = z.pinCodes.text.length;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Zone ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove zone',
                          onPressed: () => _removeZone(i),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: z.name,
                      decoration: const InputDecoration(
                        labelText: 'Zone name',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: z.pinCodes,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'PIN codes',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText:
                            'Enter PIN codes separated by a comma. For a range by prefix, add * after the shared digits (e.g. 5600*).',
                        counterText: '$pinLen chars',
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: z.minOrder,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Minimum order price (₹)',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: z.deliveryPrice,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Delivery price (₹)',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
