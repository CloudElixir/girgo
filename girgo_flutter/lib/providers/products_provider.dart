import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../constants/products.dart';

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _error;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductsProvider() {
    loadProducts();
  }

  StreamSubscription? _productsSubscription;

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel existing subscription if any
      await _productsSubscription?.cancel();

      // Listen to Firestore stream for real-time updates
      final productsStream = FirestoreService.getProducts();
      
      _productsSubscription = productsStream.listen(
        (productsData) {
          _products = productsData.map((data) {
            return Product(
              // Must be Firestore document id (see FirestoreService merge order).
              id: (data['id'] as String?)?.trim() ?? '',
              name: data['name'] as String? ?? '',
              category: data['category'] as String? ?? '',
              image: data['image'] as String? ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              subscriptionPrice: (data['subscriptionPrice'] as num?)?.toDouble(),
              quantity: data['quantity'] as String? ?? '',
              description: data['description'] as String? ?? '',
              isSubscriptionAvailable: data['isSubscriptionAvailable'] as bool? ?? false,
              sortOrder: (data['sortOrder'] as num?)?.toInt(),
            );
          }).toList();

          // Extract unique categories
          _categories = ['All', ..._products.map((p) => p.category).toSet().toList()..sort()];
          
          _isLoading = false;
          _error = null;
          notifyListeners();
          
          if (kDebugMode) {
            print('✅ Products updated: ${_products.length} products loaded');
          }
        },
        onError: (e) {
          _isLoading = false;
          _error = e.toString();
          // Fallback to constants if Firestore fails
          _products = Products.allProducts;
          _categories = Products.categories;
          notifyListeners();
          if (kDebugMode) {
            print('❌ Error loading products from Firestore: $e');
            print('Falling back to constants');
          }
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      // Fallback to constants if Firestore fails
      _products = Products.allProducts;
      _categories = Products.categories;
      notifyListeners();
      if (kDebugMode) {
        print('❌ Error loading products from Firestore: $e');
        print('Falling back to constants');
      }
    }
  }

  void dispose() {
    _productsSubscription?.cancel();
  }

  List<Product> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    }

    final products = _products.where((p) => p.category == category).toList();

    // Sort ghee products by volume (ascending): 250ml, 500ml, 1 Litre, 3 Litres, 5 Litres, 10 Litres
    if (category == 'Ghee') {
      products.sort((a, b) => _quantityToMilliliters(a.quantity).compareTo(
            _quantityToMilliliters(b.quantity),
          ));
    }

    return products;
  }

  /// Converts a quantity string (e.g. "250ml", "1 Litre") to milliliters for sorting.
  int _quantityToMilliliters(String quantity) {
    final lower = quantity.toLowerCase().trim();

    if (lower.contains('½') ||
        RegExp(r'\b1\s*/\s*2\b').hasMatch(lower) ||
        lower.contains('half')) {
      if (lower.contains('l') ||
          lower.contains('litre') ||
          lower.contains('liter') ||
          lower.contains('ltr')) {
        return 500;
      }
    }

    // Common formats: "250ml", "500 ml", "1 litre", "3 litres", "10lt"
    final mlMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*ml").firstMatch(lower);
    if (mlMatch != null) {
      return (double.parse(mlMatch.group(1)!) * 1).round();
    }

    final litreMatch = RegExp(r"^(\d+(?:\.\d+)?)\s*(l|litre|litres|lt)").firstMatch(lower);
    if (litreMatch != null) {
      return (double.parse(litreMatch.group(1)!) * 1000).round();
    }

    if (RegExp(r'^\s*1\s*/\s*2\s*$').hasMatch(lower) ||
        lower == '½' ||
        (lower.contains('½') && !lower.contains('ml'))) {
      return 500;
    }

    // Fallback: try to parse as a raw number
    final numberMatch = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(lower);
    if (numberMatch != null) {
      return (double.parse(numberMatch.group(1)!) * 1000).round();
    }

    // Unknown format: treat as large so it appears last
    return 1000000;
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

