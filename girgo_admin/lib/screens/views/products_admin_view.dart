import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../utils/data_url_image_decoder.dart';

class ProductsAdminView extends StatefulWidget {
  const ProductsAdminView({super.key});

  @override
  State<ProductsAdminView> createState() => _ProductsAdminViewState();
}

class _ProductsAdminViewState extends State<ProductsAdminView> {
  String _searchQuery = '';
  String? _selectedCategory;
  static const int _maxInlineImageStringBytes = 900 * 1024;
  bool _isReorderMode = false;
  bool _isSavingOrder = false;

  int _estimateDataUrlBytes(String dataUrl) => dataUrl.length;
  bool get _canReorderCurrentView =>
      _searchQuery.trim().isEmpty && _selectedCategory == null;

  Future<void> _saveReorderedProducts(List<Map<String, dynamic>> reordered) async {
    final ids = reordered
        .map((e) => (e['id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    setState(() => _isSavingOrder = true);
    try {
      await FirestoreService.setProductsDisplayOrder(ids);
    } finally {
      if (mounted) setState(() => _isSavingOrder = false);
    }
  }

  Future<void> _toggleProduct(String productId, bool isActive) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService.setProductActiveState(productId, !isActive);
      messenger.showSnackBar(
        SnackBar(
          content: Text(isActive ? 'Product disabled' : 'Product enabled'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update product: $e')),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
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
        await FirestoreService.deleteProduct(productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted')),
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

  void _showAddEditProductDialog([Map<String, dynamic>? product]) {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final categoryController = TextEditingController(text: product?['category'] ?? '');
    final imageController = TextEditingController(text: product?['image'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final subscriptionPriceController = TextEditingController(text: product?['subscriptionPrice']?.toString() ?? '');
    final quantityController = TextEditingController(text: product?['quantity'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    var isSubscriptionAvailable = product?['isSubscriptionAvailable'] ?? false;
    var isActive = product?['isActive'] ?? true;
    Future<void>? pendingImageUpload;
    Uint8List? pendingPreviewBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Milk, Ghee',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image Path *',
                      hintText: 'Upload image or paste URL/asset path',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (imageController.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: imageController.text.startsWith('data:image')
                            ? Image.memory(
                                DataUrlImageDecoder.decode(imageController.text),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => ColoredBox(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                              )
                            : imageController.text.startsWith('http')
                                ? Image.network(
                                    imageController.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                    ),
                                  )
                                : Image.asset(
                                    imageController.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                    ),
                                  ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 78,
                              maxWidth: 1400,
                              maxHeight: 1400,
                            );
                            if (picked == null) return;
                            final bytes = await picked.readAsBytes();
                            pendingPreviewBytes = bytes;
                            setDialogState(() {});
                            final uploadCompleter = Completer<void>();
                            pendingImageUpload = uploadCompleter.future;
                            try {
                              final ext = picked.name.toLowerCase();
                              final mimeType = ext.endsWith('.png')
                                  ? 'image/png'
                                  : ext.endsWith('.webp')
                                      ? 'image/webp'
                                      : 'image/jpeg';
                              final dataUrl =
                                  'data:$mimeType;base64,${base64Encode(bytes)}';
                              imageController.text = dataUrl;
                              pendingPreviewBytes = null;
                              setDialogState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image selected — saved inline in Firestore on Update'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Upload failed: $e')),
                                );
                              }
                            } finally {
                              uploadCompleter.complete();
                            }
                          },
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                  if (pendingPreviewBytes != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.memory(
                          pendingPreviewBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price (₹) *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: subscriptionPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Subscription Price (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 1 Litre, 250ml',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Subscription Available'),
                    value: isSubscriptionAvailable,
                    onChanged: (value) => setDialogState(() {
                      isSubscriptionAvailable = value ?? false;
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) => setDialogState(() {
                      isActive = value ?? true;
                    }),
                  ),
                ],
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
                    var imagePath = imageController.text.trim();
                    if (imagePath.isEmpty) {
                      throw Exception(
                        'Please upload image or paste a valid image path.',
                      );
                    }
                    if (imagePath.startsWith('data:image') &&
                        _estimateDataUrlBytes(imagePath) >
                            _maxInlineImageStringBytes) {
                      throw Exception(
                        'Image is too large for Firestore. Choose a smaller image.',
                      );
                    }
                    final productData = {
                      'name': nameController.text.trim(),
                      'category': categoryController.text.trim(),
                      'image': imagePath,
                      'price': double.parse(priceController.text),
                      'subscriptionPrice': subscriptionPriceController.text.isNotEmpty
                          ? double.parse(subscriptionPriceController.text)
                          : null,
                      'quantity': quantityController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'isSubscriptionAvailable': isSubscriptionAvailable,
                      'isActive': isActive,
                    };

                    if (isEditing) {
                      await FirestoreService.updateProduct(product!['id'] as String, productData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product updated')),
                        );
                      }
                    } else {
                      await FirestoreService.addProduct(productData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product added')),
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
      stream: FirestoreService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allProducts = snapshot.data!;
        final totalProducts = allProducts.length;
        final activeCount = allProducts.where((p) => p['isActive'] == true).length;
        final inactiveCount = totalProducts - activeCount;
        
        // Filter products
        var filteredProducts = allProducts.where((product) {
          final matchesSearch = _searchQuery.isEmpty ||
              (product['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (product['category']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final matchesCategory = _selectedCategory == null || 
              product['category']?.toString() == _selectedCategory;
          
          return matchesSearch && matchesCategory;
        }).toList();

        // Get unique categories
        final categories = allProducts
            .map((p) => p['category']?.toString())
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

        return Column(
          children: [
            // Header with Add button and filters
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
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 820;
                      final statCardWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;

                      Widget statCard({
                        required IconData icon,
                        required String label,
                        required int value,
                        required Color color,
                      }) {
                        return SizedBox(
                          width: statCardWidth,
                          child: Card(
                            elevation: 0,
                            color: color.withOpacity(0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: color.withOpacity(0.15)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          value.toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              statCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Total products',
                                value: totalProducts,
                                color: const Color(0xFF0B510E),
                              ),
                              statCard(
                                icon: Icons.check_circle_outline,
                                label: 'Active',
                                value: activeCount,
                                color: Colors.green,
                              ),
                              statCard(
                                icon: Icons.pause_circle_outline,
                                label: 'Inactive',
                                value: inactiveCount,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: isNarrow ? constraints.maxWidth : 460,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search products (name/category)...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                  ),
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                ),
                              ),
                              SizedBox(
                                width: isNarrow ? constraints.maxWidth : 240,
                                child: DropdownButtonFormField<String?>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  hint: const Text('All categories'),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All categories'),
                                    ),
                                    ...categories.map(
                                      (cat) => DropdownMenuItem<String?>(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) => setState(() => _selectedCategory = value),
                                ),
                              ),
                              SizedBox(
                                width: isNarrow ? constraints.maxWidth : null,
                                child: FilledButton.icon(
                                  onPressed: () => _showAddEditProductDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add product'),
                                ),
                              ),
                              SizedBox(
                                width: isNarrow ? constraints.maxWidth : null,
                                child: OutlinedButton.icon(
                                  onPressed: _isSavingOrder
                                      ? null
                                      : () {
                                          setState(() {
                                            _isReorderMode = !_isReorderMode;
                                          });
                                        },
                                  icon: Icon(
                                    _isReorderMode ? Icons.check : Icons.drag_indicator,
                                  ),
                                  label: Text(_isReorderMode ? 'Done Reordering' : 'Reorder'),
                                ),
                              ),
                            ],
                          ),
                          if (_isReorderMode && !_canReorderCurrentView)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Clear search/category filter to drag-reorder products.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Products list
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allProducts.isEmpty
                                ? 'No products found. Add your first product!'
                                : 'No products match your search.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : (_isReorderMode && _canReorderCurrentView
                      ? ReorderableListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final reordered = List<Map<String, dynamic>>.from(filteredProducts);
                            final moved = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, moved);
                            await _saveReorderedProducts(reordered);
                          },
                          itemBuilder: (context, index) => _buildProductCard(
                            filteredProducts[index],
                            key: ValueKey(filteredProducts[index]['id'] ?? 'p_$index'),
                            reorderIndex: index,
                            reorderMode: true,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildProductCard(
                            filteredProducts[index],
                            key: ValueKey(filteredProducts[index]['id'] ?? 'p_$index'),
                            reorderIndex: index,
                            reorderMode: false,
                          ),
                        )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product, {
    required Key key,
    required int reorderIndex,
    required bool reorderMode,
  }) {
    final isActive = product['isActive'] == true;
    final price = product['price'] ?? 0.0;
    final subscriptionPrice = product['subscriptionPrice'];
    final category = product['category'] ?? 'Uncategorized';
    final image = product['image']?.toString() ?? '';
    final hasImage = image.trim().isNotEmpty;
    final isHttpImage = image.startsWith('http://') || image.startsWith('https://');
    final isDataUrlImage = image.startsWith('data:image');

    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      child: InkWell(
        onTap: () => _showAddEditProductDialog(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (reorderMode) ...[
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.drag_indicator, color: Colors.grey),
                  ),
                ),
              ],
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: isDataUrlImage
                        ? Image.memory(
                            DataUrlImageDecoder.decode(image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                            ),
                          )
                        : isHttpImage
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                              )
                            : Image.asset(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'Unnamed product',
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        if (subscriptionPrice != null)
                          Text(
                            'Sub ₹$subscriptionPrice',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        Text(
                          product['quantity']?.toString().trim().isNotEmpty == true
                              ? product['quantity'].toString()
                              : '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ].where((w) => !(w is Text && (w.data ?? '').isEmpty)).toList(),
                    ),
                  ],
                ),
              ),
              if (!reorderMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (_) => _toggleProduct(
                        product['id'] as String,
                        isActive,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditProductDialog(product),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(product['id'] as String),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
