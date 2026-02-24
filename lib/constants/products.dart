class Product {
  final String id;
  final String name;
  final String category;
  final String image;
  final double price; // One-time purchase price
  final double? subscriptionPrice; // Subscription price per day
  final String quantity;
  final String description;
  final bool isSubscriptionAvailable;

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
  });
}

class Products {
  static final List<Product> allProducts = [
    // Milk - 1 Litre (with Subscription and One-time options)
    Product(
      id: 'milk-1l',
      name: 'A2 Desi Gir Cow Milk',
      category: 'Milk',
      image: 'Products/A2 DESI GIR COW MILK.jpg',
      price: 150, // One-time purchase price
      subscriptionPrice: 120, // Subscription price per day
      quantity: '1 Litre',
      description: 'Fresh and pure A2 desi Gir cow milk, directly sourced from Girgo farms.',
      isSubscriptionAvailable: true,
    ),
    // Milk - 1/2 Litre (with Subscription option)
    Product(
      id: 'milk-500ml',
      name: 'A2 Desi Gir Cow Milk',
      category: 'Milk',
      image: 'Products/A2 DESI GIR COW MILK.jpg',
      price: 60, // One-time purchase price (same as subscription)
      subscriptionPrice: 60, // Subscription price per day
      quantity: '½ Litre',
      description: 'Fresh and pure A2 desi Gir cow milk, directly sourced from Girgo farms.',
      isSubscriptionAvailable: true,
    ),
    // Ghee
    Product(
      id: 'ghee-250ml',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 729,
      quantity: '250ml',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    Product(
      id: 'ghee-500ml',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 1378,
      quantity: '500ml',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    Product(
      id: 'ghee-1l',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 2780,
      quantity: '1 Litre',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    Product(
      id: 'ghee-3l',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 8299,
      quantity: '3 Litres',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    Product(
      id: 'ghee-5l',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 12699,
      quantity: '5 Litres',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    Product(
      id: 'ghee-10l',
      name: 'A2 Bilona Ghee',
      category: 'Ghee',
      image: 'Products/A2 BILONA GHEE.jpg',
      price: 26599,
      quantity: '10 Litres',
      description: '100% pure A2 bilona ghee prepared traditionally from Girgo milk.',
    ),
    // Gomutra
    Product(
      id: 'gomutra-1l',
      name: 'Gomutra (Cow Urine)',
      category: 'Gomutra',
      image: 'Products/GOMUTRA (COW URINE).jpg',
      price: 50,
      quantity: '1 Litre',
      description: 'Freshly distilled gomutra from native cows, hygienically processed.',
    ),
    // Pachagavya
    Product(
      id: 'pachagavya-1l',
      name: 'Panchgavya Cow Dung Cake',
      category: 'Pachagavya',
      image: 'Products/PANCHGAVYA COW DUNG CAKE.jpg',
      price: 150,
      quantity: '1 Litre',
      description: 'Organic Panchgavya for agricultural and spiritual use.',
    ),
    // Cowdung Diyas
    Product(
      id: 'cowdung-diya',
      name: 'Cow Dung Diyas (Lamps)',
      category: 'Diyas',
      image: 'Products/COW DUNG DIYAS (LAMPS).jpg',
      price: 150,
      quantity: '1 piece',
      description: 'Handcrafted eco-friendly diyas made from cow dung.',
    ),
    // Dhoopa
    Product(
      id: 'dhoopa-1',
      name: 'Herbal Dhoop Sticks',
      category: 'Dhoopa',
      image: 'Products/HERBAL DHOOP STICKS.jpg',
      price: 120,
      quantity: '1 piece',
      description: 'Natural herbal dhoop sticks for puja and home purification.',
    ),
    Product(
      id: 'dhoopa-15',
      name: 'Herbal Dhoop Sticks - Combo Pack',
      category: 'Dhoopa',
      image: 'Products/HERBAL DHOOP STICKS.jpg',
      price: 150,
      quantity: '15 pieces',
      description: 'Natural herbal dhoop sticks for puja and home purification. Combo pack of 15 pieces.',
    ),
    // Paneer
    Product(
      id: 'paneer-250g',
      name: 'A2 Desi Paneer',
      category: 'Paneer',
      image: 'Products/A2 Desi Paneer.jpg',
      price: 150,
      quantity: '250g',
      description: 'Fresh, soft, organic A2 desi paneer made from Girgo cow milk.',
    ),
    Product(
      id: 'paneer-500g',
      name: 'A2 Desi Paneer',
      category: 'Paneer',
      image: 'Products/A2 Desi Paneer.jpg',
      price: 300,
      quantity: '500g',
      description: 'Fresh, soft, organic A2 desi paneer made from Girgo cow milk.',
    ),
  ];

  static final List<String> categories = [
    'All',
    'Milk',
    'Ghee',
    'Gomutra',
    'Pachagavya',
    'Diyas',
    'Dhoopa',
    'Paneer',
  ];
}

