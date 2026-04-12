import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/products.dart';
import 'firestore_service.dart';

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
      if (cartJson == null) return [];

      final List<dynamic> cartData = json.decode(cartJson);
      return cartData.map((item) {
        final product = Products.allProducts.firstWhere(
          (p) => p.id == item['productId'],
        );
        return CartItem(
          product: product,
          quantity: item['quantity'],
          isSubscription: item['isSubscription'] ?? false,
          subscriptionType: item['subscriptionType'],
        );
      }).toList();
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

