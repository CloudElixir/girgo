import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../constants/products.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  Map<String, double> _totals = {'subtotal': 0, 'deliveryFee': 0, 'total': 0};

  List<CartItem> get cartItems => _cartItems;
  Map<String, double> get totals => _totals;
  int get cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _cartItems = await _cartService.getCart();
    _totals = await _cartService.getCartTotal();
    notifyListeners();
  }

  Future<void> addToCart(Product product, {int quantity = 1, bool isSubscription = false, String? subscriptionType}) async {
    await _cartService.addToCart(product, quantity: quantity, isSubscription: isSubscription, subscriptionType: subscriptionType);
    await loadCart();
  }

  Future<void> removeFromCart(String productId, {bool isSubscription = false}) async {
    await _cartService.removeFromCart(productId, isSubscription: isSubscription);
    await loadCart();
  }

  Future<void> updateQuantity(String productId, int quantity, {bool isSubscription = false}) async {
    await _cartService.updateQuantity(productId, quantity, isSubscription: isSubscription);
    await loadCart();
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
    await loadCart();
  }
}

