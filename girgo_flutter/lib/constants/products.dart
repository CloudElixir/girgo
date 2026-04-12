class Product {
  final String id;
  final String name;
  final String category;
  final String image;
  final double price; // One-time purchase price
  final double? subscriptionPrice; // Subscription price per cycle (shown as /month in UI)
  final String quantity;
  final String description;
  final bool isSubscriptionAvailable;
  final int? sortOrder;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.price,
    this.subscriptionPrice,
    required this.quantity,
    required this.description,
    this.isSubscriptionAvailable = false,
    this.sortOrder,
  });
}

class Products {
  static final List<Product> allProducts = [
    // Raw Milk - 1 Litre (Trial + Monthly Subscription)
    Product(
      id: 'milk-1l',
      name: 'GirGo A2 Raw Milk — Fresh Gir Cow Milk Delivered Daily in Bengaluru',
      category: 'Milk',
      image: 'Products/A2 DESI GIR COW MILK.jpg',
      price: 150, // One-time purchase price
      subscriptionPrice: 3500, // Monthly subscription price
      quantity: '1 Litre',
      description: 'Fresh Gir cow milk delivered daily in Bengaluru.',
      isSubscriptionAvailable: true,
    ),
    // Raw Milk - 1/2 Litre (Monthly Subscription)
    Product(
      id: 'milk-500ml',
      name: 'GirGo A2 Raw Milk — Fresh Gir Cow Milk Delivered Daily in Bengaluru',
      category: 'Milk',
      image: 'Products/A2 DESI GIR COW MILK.jpg',
      price: 1820,
      subscriptionPrice: 1820,
      quantity: '½ Litre',
      description: 'Fresh Gir cow milk delivered daily in Bengaluru (½ litre).',
      isSubscriptionAvailable: true,
    ),
  ];

  static final List<String> categories = [
    'All',
    'Milk',
  ];
}

