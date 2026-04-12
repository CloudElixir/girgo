import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/products.dart';
import 'firestore_service.dart';

Map<String, dynamic> _productToMap(Product p) => {
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'image': p.image,
      'price': p.price,
      'subscriptionPrice': p.subscriptionPrice,
      'quantity': p.quantity,
      'description': p.description,
      'isSubscriptionAvailable': p.isSubscriptionAvailable,
    };

bool _readBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

double? _readDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

Product _productFromMap(Map<String, dynamic> m) {
  return Product(
    id: m['id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    category: m['category']?.toString() ?? '',
    image: m['image']?.toString() ?? '',
    price: _readDouble(m['price']) ?? 0.0,
    subscriptionPrice: _readDouble(m['subscriptionPrice']),
    quantity: m['quantity']?.toString() ?? '',
    description: m['description']?.toString() ?? '',
    isSubscriptionAvailable: _readBool(m['isSubscriptionAvailable']),
  );
}

class CartItem {
  final Product product;
  int quantity;
  final bool isSubscription;
  final String? subscriptionType;

  CartItem({
    required this.product,
    required this.quantity,
    this.isSubscription = false,
    this.subscriptionType,
  });

  Map<String, dynamic> toJson() => {
        'productId': product.id,
        // Full snapshot so Firestore-backed SKUs (not in Products.allProducts) round-trip.
        'product': _productToMap(product),
        'quantity': quantity,
        'isSubscription': isSubscription,
        'subscriptionType': subscriptionType,
      };

  double get totalPrice {
    final price = isSubscription && product.subscriptionPrice != null
        ? product.subscriptionPrice!
        : product.price;
    return price * quantity;
  }
}

class CartService {
  static const String _cartKey = 'girgo_cart';

  Future<List<CartItem>> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson == null || cartJson.isEmpty) return [];

      final List<dynamic> cartData = json.decode(cartJson) as List<dynamic>;
      final out = <CartItem>[];
      for (final raw in cartData) {
        try {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          final productSnap = item['product'];
          final Product product;
          if (productSnap is Map) {
            product = _productFromMap(
              Map<String, dynamic>.from(productSnap),
            );
          } else {
            // Legacy: only productId (must exist in Products.allProducts).
            final id = item['productId']?.toString();
            if (id == null || id.isEmpty) continue;
            Product? legacy;
            for (final p in Products.allProducts) {
              if (p.id == id) {
                legacy = p;
                break;
              }
            }
            if (legacy == null) continue;
            product = legacy;
          }
          if (product.id.isEmpty) continue;
          out.add(
            CartItem(
              product: product,
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              isSubscription: _readBool(item['isSubscription']),
              subscriptionType: item['subscriptionType']?.toString(),
            ),
          );
        } catch (e) {
          print('Skipping corrupt cart line: $e');
        }
      }
      return out;
    } catch (e) {
      print('Get Cart Error: $e');
      return [];
    }
  }

  Future<void> addToCart(
    Product product, {
    int quantity = 1,
    bool isSubscription = false,
    String? subscriptionType,
  }) async {
    try {
      final cart = await getCart();
      final existingIndex = cart.indexWhere(
        (item) => item.product.id == product.id && item.isSubscription == isSubscription,
      );

      if (existingIndex >= 0) {
        cart[existingIndex].quantity += quantity;
      } else {
        cart.add(CartItem(
          product: product,
          quantity: quantity,
          isSubscription: isSubscription,
          subscriptionType: subscriptionType,
        ));
      }

      await _saveCart(cart);
    } catch (e) {
      print('Add to Cart Error: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId, {bool isSubscription = false}) async {
    try {
      final cart = await getCart();
      cart.removeWhere(
        (item) => item.product.id == productId && item.isSubscription == isSubscription,
      );
      await _saveCart(cart);
    } catch (e) {
      print('Remove from Cart Error: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity, {bool isSubscription = false}) async {
    try {
      final cart = await getCart();
      final item = cart.firstWhere(
        (item) => item.product.id == productId && item.isSubscription == isSubscription,
      );
      
      if (quantity <= 0) {
        await removeFromCart(productId, isSubscription: isSubscription);
      } else {
        item.quantity = quantity;
        await _saveCart(cart);
      }
    } catch (e) {
      print('Update Quantity Error: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
    } catch (e) {
      print('Clear Cart Error: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getCartTotal() async {
    try {
      final cart = await getCart();
      final subtotal = cart.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final deliveryFeeFromConfig = await FirestoreService.getDeliveryFee();
      final deliveryFee = deliveryFeeFromConfig ?? 0.0;
      final total = subtotal + deliveryFee;

      return {
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
      };
    } catch (e) {
      print('Get Cart Total Error: $e');
      return {'subtotal': 0, 'deliveryFee': 0, 'total': 0};
    }
  }

  Future<void> _saveCart(List<CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = json.encode(cart.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }
}

