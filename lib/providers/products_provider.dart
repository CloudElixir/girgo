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
              id: data['id'] as String? ?? '',
              name: data['name'] as String? ?? '',
              category: data['category'] as String? ?? '',
              image: data['image'] as String? ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              subscriptionPrice: (data['subscriptionPrice'] as num?)?.toDouble(),
              quantity: data['quantity'] as String? ?? '',
              description: data['description'] as String? ?? '',
              isSubscriptionAvailable: data['isSubscriptionAvailable'] as bool? ?? false,
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
    return _products.where((p) => p.category == category).toList();
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

