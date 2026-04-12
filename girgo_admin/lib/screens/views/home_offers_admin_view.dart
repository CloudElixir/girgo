import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class HomeOffersAdminView extends StatefulWidget {
  const HomeOffersAdminView({super.key});

  @override
  State<HomeOffersAdminView> createState() => _HomeOffersAdminViewState();
}

class _HomeOffersAdminViewState extends State<HomeOffersAdminView> {
  // Keep inline image payload safely under Firestore document limits.
  static const int _maxInlineImageStringBytes = 900 * 1024;

  int _estimateDataUrlBytes(String dataUrl) => dataUrl.length;

  Future<String> _compressForFirestore(html.File file) async {
    final reader = html.FileReader()..readAsDataUrl(file);
    await reader.onLoadEnd.first;
    final rawDataUrl = reader.result as String?;
    if (rawDataUrl == null || rawDataUrl.isEmpty) {
      throw Exception('Unable to read image file');
    }

    final image = html.ImageElement(src: rawDataUrl);
    await image.onLoad.first;
    var sourceWidth = image.naturalWidth ?? image.width ?? 0;
    var sourceHeight = image.naturalHeight ?? image.height ?? 0;
    if (sourceWidth <= 0 || sourceHeight <= 0) return rawDataUrl;

    const maxDimension = 1200;
    final scale = math.min(1.0, maxDimension / math.max(sourceWidth, sourceHeight));
    final targetWidth = math.max(1, (sourceWidth * scale).round());
    final targetHeight = math.max(1, (sourceHeight * scale).round());

    final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(image, 0, 0, targetWidth, targetHeight);

    var quality = 0.82;
    var compressed = canvas.toDataUrl('image/jpeg', quality);
    while (_estimateDataUrlBytes(compressed) > _maxInlineImageStringBytes &&
        quality > 0.42) {
      quality -= 0.08;
      compressed = canvas.toDataUrl('image/jpeg', quality);
    }
    return compressed;
  }

  Future<void> _toggleOffer(String offerId, bool isActive) async {
    try {
      await FirestoreService.updateHomeOffer(offerId, {'isActive': isActive});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Offer activated' : 'Offer deactivated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  bool _isButtonEnabledOnOffer(Map<String, dynamic> offer) {
    final r = offer['isButtonEnabled'];
    if (r == null) return true;
    return r == true ||
        r == 1 ||
        (r is String && (r.toLowerCase() == 'true' || r == '1'));
  }

  Future<void> _toggleHomeOfferButton(String offerId, bool enabled) async {
    try {
      await FirestoreService.updateHomeOffer(offerId, {'isButtonEnabled': enabled});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Home banner button enabled' : 'Home banner button hidden'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService.deleteHomeOffer(offerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showAddEditOfferDialog([Map<String, dynamic>? offer]) {
    final isEditing = offer != null;
    final formKey = GlobalKey<FormState>();
    
    final titleController = TextEditingController(text: offer?['title'] ?? '');
    final subtitleController = TextEditingController(text: offer?['subtitle'] ?? '');
    final imageUrlController = TextEditingController(text: offer?['imageUrl'] ?? '');
    final buttonTextController = TextEditingController(text: offer?['buttonText'] ?? 'Shop Now');
    final buttonLinkController = TextEditingController(text: offer?['buttonLink'] ?? '/products');
    final priorityController = TextEditingController(text: offer?['priority']?.toString() ?? '1');
    var isActive = offer?['isActive'] ?? true;
    var isButtonEnabled = offer?['isButtonEnabled'] ?? true;
    DateTime? startDate = offer?['startDate'] != null 
        ? (offer!['startDate'] as dynamic).toDate() 
        : DateTime.now();
    DateTime? endDate = offer?['endDate'] != null 
        ? (offer!['endDate'] as dynamic).toDate() 
        : null;
    var hasEndDate = offer?['endDate'] != null;
    Future<void>? pendingImageUpload;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Home Offer' : 'Add New Home Offer'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Main offer text',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle',
                      hintText: 'Supporting text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Banner image *',
                            hintText: 'Upload or paste image URL',
                            border: OutlineInputBorder(),
                            helperText: 'Shown live in the customer app',
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (kIsWeb)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uploadInput = html.FileUploadInputElement()
                                ..accept = 'image/*'
                                ..click();
                              uploadInput.onChange.listen((e) async {
                                final files = uploadInput.files;
                                if (files == null || files.isEmpty) return;
                                final file = files[0];
                                if (file.size > 10 * 1024 * 1024) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image must be under 10MB')),
                                    );
                                  }
                                  return;
                                }
                                final uploadCompleter = Completer<void>();
                                pendingImageUpload = uploadCompleter.future;
                                try {
                                  final dataUrl = await _compressForFirestore(file);
                                  imageUrlController.text = dataUrl;
                                  setDialogState(() {});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image ready — saved inline in Firestore when you tap Update'),
                                      ),
                                    );
                                  }
                                } catch (err) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red.shade700,
                                        content: Text('Upload failed: $err'),
                                      ),
                                    );
                                  }
                                } finally {
                                  uploadCompleter.complete();
                                }
                              });
                            },
                            icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                            label: const Text('Upload'),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Upload is available in the web admin')),
                              );
                            },
                            icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                            label: const Text('Upload'),
                          ),
                        ),
                    ],
                  ),
                  if (imageUrlController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: (imageUrlController.text.startsWith('http') || imageUrlController.text.startsWith('data:'))
                            ? Image.network(
                                imageUrlController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFFE0E0E0),
                                  child: Center(child: Icon(Icons.broken_image)),
                                ),
                              )
                            : ColoredBox(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'App asset: ${imageUrlController.text}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: buttonTextController,
                          decoration: const InputDecoration(
                            labelText: 'Button Text',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: buttonLinkController,
                          decoration: const InputDecoration(
                            labelText: 'Button Link',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priorityController,
                    decoration: const InputDecoration(
                      labelText: 'Priority *',
                      hintText: 'Higher number = shown first',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(startDate != null 
                        ? DateFormat('MMM dd, yyyy').format(startDate!)
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Has End Date'),
                    value: hasEndDate,
                    onChanged: (value) => setDialogState(() {
                      hasEndDate = value ?? false;
                      if (!hasEndDate) endDate = null;
                    }),
                  ),
                  if (hasEndDate)
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(endDate != null 
                          ? DateFormat('MMM dd, yyyy').format(endDate!)
                          : 'Not set'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Offer active'),
                    subtitle: const Text('Show this banner on the app home when dates allow.'),
                    value: isActive,
                    onChanged: (value) => setDialogState(() {
                      isActive = value;
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('Show CTA button on app'),
                    subtitle: const Text('Turn off to hide the banner button in the customer app.'),
                    value: isButtonEnabled,
                    onChanged: (value) => setDialogState(() {
                      isButtonEnabled = value;
                    }),
                  ),
                ],
              ),
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pendingImageUpload != null) {
                  await pendingImageUpload;
                }
                if (formKey.currentState!.validate()) {
                  try {
                    final imageUrl = imageUrlController.text.trim();
                    if (imageUrl.startsWith('data:image') &&
                        _estimateDataUrlBytes(imageUrl) > _maxInlineImageStringBytes) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade700,
                            content: const Text('Image is too large for Firestore. Choose a smaller image.'),
                          ),
                        );
                      }
                      return;
                    }
                    final offerData = {
                      'title': titleController.text.trim(),
                      'subtitle': subtitleController.text.trim(),
                      'imageUrl': imageUrl,
                      'buttonText': buttonTextController.text.trim(),
                      'buttonLink': buttonLinkController.text.trim(),
                      'priority': int.parse(priorityController.text),
                      'isActive': isActive,
                      'isButtonEnabled': isButtonEnabled,
                      if (startDate != null) 'startDate': startDate,
                      if (hasEndDate && endDate != null) 'endDate': endDate,
                      if (!hasEndDate) 'endDate': null,
                    };

                    if (isEditing) {
                      await FirestoreService.updateHomeOffer(offer!['id'] as String, offerData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Offer updated')),
                        );
                      }
                    } else {
                      await FirestoreService.addHomeOffer(offerData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Offer added')),
                        );
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllHomeOffers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final offers = snapshot.data!;

        return Column(
          children: [
            // Header with Add button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Home Offers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditOfferDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Offer'),
                  ),
                ],
              ),
            ),
            
            // Offers list
            Expanded(
              child: offers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No offers found. Add your first offer!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: offers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        final isActive = offer['isActive'] == true;
                        final buttonOn = _isButtonEnabledOnOffer(offer);
                        final priority = offer['priority'] ?? 0;
                        final startDate = offer['startDate'];
                        final endDate = offer['endDate'];
                        
                        return Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _showAddEditOfferDialog(offer),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: _homeOfferListImage(offer['imageUrl']),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$priority',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Offer info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                offer['title'] ?? 'Untitled Offer',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                isActive ? 'Active' : 'Inactive',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor: isActive
                                                  ? Colors.green.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color: isActive ? Colors.green[700] : Colors.grey[700],
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                buttonOn ? 'Button on' : 'Button off',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor: buttonOn
                                                  ? Colors.amber.withOpacity(0.25)
                                                  : Colors.blueGrey.withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color: buttonOn ? Colors.orange.shade900 : Colors.blueGrey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (offer['subtitle'] != null && offer['subtitle'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            offer['subtitle'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          children: [
                                            if (startDate != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Start: ${DateFormat('MMM dd, yyyy').format((startDate as dynamic).toDate())}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            if (endDate != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.event, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'End: ${DateFormat('MMM dd, yyyy').format((endDate as dynamic).toDate())}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'Offer active',
                                        child: Switch(
                                          value: isActive,
                                          onChanged: (value) => _toggleOffer(
                                            offer['id'] as String,
                                            value,
                                          ),
                                        ),
                                      ),
                                      Tooltip(
                                        message: 'CTA button on app home',
                                        child: Switch(
                                          value: buttonOn,
                                          onChanged: (value) => _toggleHomeOfferButton(
                                            offer['id'] as String,
                                            value,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showAddEditOfferDialog(offer),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteOffer(offer['id'] as String),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _homeOfferListImage(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) {
      return ColoredBox(
        color: Colors.grey.shade300,
        child: Icon(Icons.image_outlined, color: Colors.grey.shade600),
      );
    }
    if (s.startsWith('http') || s.startsWith('data:')) {
      return Image.network(
        s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: Colors.grey.shade300,
          child: Icon(Icons.broken_image, color: Colors.grey.shade600),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
        },
      );
    }
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Icon(Icons.photo_library_outlined, color: Colors.grey.shade600, size: 28),
    );
  }
}
