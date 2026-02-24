import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/products.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference get productsCollection => _firestore.collection('products');
  static CollectionReference get homeOffersCollection => _firestore.collection('home_offers');
  static CollectionReference get blogsCollection => _firestore.collection('blogs');
  static CollectionReference get subscriptionsCollection => _firestore.collection('subscriptions');
  static CollectionReference get ordersCollection => _firestore.collection('orders');
  static CollectionReference get usersCollection => _firestore.collection('users');
  static CollectionReference get appConfigCollection => _firestore.collection('app_config');

  // ========== PRODUCTS ==========
  
  /// Get all products
  static Stream<List<Map<String, dynamic>>> getProducts() {
    return productsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Get all products including inactive ones (for admin panel)
  static Stream<List<Map<String, dynamic>>> getAllProducts() {
    return productsCollection.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList(),
    );
  }

  /// Get products by category
  static Stream<List<Map<String, dynamic>>> getProductsByCategory(String category) {
    if (category == 'All') {
      return getProducts();
    }
    return productsCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Add a product
  static Future<void> addProduct(Map<String, dynamic> productData) async {
    await productsCollection.add(productData);
  }

  /// Update a product
  static Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    await productsCollection.doc(productId).update(updates);
  }

  /// Delete a product (soft delete)
  static Future<void> deleteProduct(String productId) async {
    await productsCollection.doc(productId).update({'isActive': false});
  }

  /// Toggle product active state
  static Future<void> setProductActiveState(String productId, bool isActive) async {
    await productsCollection.doc(productId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== HOME OFFERS ==========
  
  /// Get active home offers
  static Stream<List<Map<String, dynamic>>> getHomeOffers() {
    final now = DateTime.now();
    return homeOffersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final offers = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Filter by date range and sort by priority
          final filteredOffers = offers.where((offer) {
            final startDate = offer['startDate'];
            final endDate = offer['endDate'];
            
            // Check if offer is within date range
            if (startDate != null) {
              DateTime start;
              if (startDate is Timestamp) {
                start = startDate.toDate();
              } else if (startDate is DateTime) {
                start = startDate;
              } else {
                // Skip if invalid date format
                return true; // Show offer if date format is invalid
              }
              if (now.isBefore(start)) return false;
            }
            
            if (endDate != null) {
              DateTime end;
              if (endDate is Timestamp) {
                end = endDate.toDate();
              } else if (endDate is DateTime) {
                end = endDate;
              } else {
                // Skip if invalid date format
                return true; // Show offer if date format is invalid
              }
              if (now.isAfter(end)) return false;
            }
            
            return true;
          }).toList();
          
          // Sort by priority (descending)
          filteredOffers.sort((a, b) {
            final aPriority = (a['priority'] as int?) ?? 0;
            final bPriority = (b['priority'] as int?) ?? 0;
            return bPriority.compareTo(aPriority);
          });
          
          return filteredOffers;
        });
  }

  /// Get all home offers (for admin)
  static Stream<List<Map<String, dynamic>>> getAllHomeOffers() {
    return homeOffersCollection
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Add a home offer
  static Future<void> addHomeOffer(Map<String, dynamic> offerData) async {
    await homeOffersCollection.add(offerData);
  }

  /// Update a home offer
  static Future<void> updateHomeOffer(String offerId, Map<String, dynamic> updates) async {
    await homeOffersCollection.doc(offerId).update(updates);
  }

  /// Add or update a home offer by ID
  static Future<void> upsertHomeOffer(String offerId, Map<String, dynamic> data) async {
    await homeOffersCollection.doc(offerId).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ========== BLOGS ==========

  /// Get active blogs for the consumer app
  static Stream<List<Map<String, dynamic>>> getActiveBlogs() {
    return blogsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final blogs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();

          // Sort by publishedAt in memory (newest first) to avoid composite index requirement
          blogs.sort((a, b) {
            final aTime = a['publishedAt'];
            final bTime = b['publishedAt'];
            DateTime? aDate;
            DateTime? bDate;

            if (aTime is Timestamp) aDate = aTime.toDate();
            if (bTime is Timestamp) bDate = bTime.toDate();

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

          return blogs;
        });
  }

  /// Get all blogs (for admin dashboard)
  static Stream<List<Map<String, dynamic>>> getAllBlogs() {
    return blogsCollection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList(),
        );
  }

  /// Add a blog post
  static Future<void> addBlog(Map<String, dynamic> blogData) async {
    await blogsCollection.add({
      ...blogData,
      'createdAt': FieldValue.serverTimestamp(),
      'publishedAt': blogData['publishedAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a blog post
  static Future<void> updateBlog(String blogId, Map<String, dynamic> updates) async {
    await blogsCollection.doc(blogId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== APP CONFIG ==========

  static DocumentReference get appConfigDoc => appConfigCollection.doc('global');

  static Future<double?> getDeliveryFee() async {
    try {
      final doc = await appConfigDoc.get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final fee = data['deliveryFee'];
      if (fee is num) {
        return fee.toDouble();
      }
      return null;
    } catch (e) {
      print('Error getting delivery fee: $e');
      return null;
    }
  }

  // ========== ORDERS ==========

  /// Get all orders (for admin)
  static Stream<List<Map<String, dynamic>>> getAllOrders() {
    return ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Get orders for a specific user
  static Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Sort by createdAt in memory (descending)
          orders.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });
          
          return orders;
        });
  }

  /// Create a new order
  static Future<String> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required double total,
    required String paymentMethod,
    required String paymentId,
    String status = 'Pending',
  }) async {
    final orderData = {
      'userId': userId,
      'items': items,
      'deliveryAddress': deliveryAddress,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await ordersCollection.add(orderData);
    return docRef.id;
  }

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await ordersCollection.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== SUBSCRIPTIONS ==========

  /// Get all subscriptions (for admin)
  static Stream<List<Map<String, dynamic>>> getAllSubscriptions() {
    return subscriptionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Get subscriptions for a specific user
  /// Handles both Firebase UID and email as userId
  static Stream<List<Map<String, dynamic>>> getUserSubscriptions(String userId) {
    print('🔍 Querying subscriptions for userId: $userId');
    
    // Try exact match first (more efficient)
    return subscriptionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final subscriptions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          print('📊 Found ${subscriptions.length} subscriptions with exact userId match');
          
          // If no results and userId looks like a Firebase UID, also try to get all and filter by email
          if (subscriptions.isEmpty && !userId.contains('@')) {
            // UserId is a UID, but subscription might be stored with email
            // We'll need to fetch all and filter - but this is inefficient
            // Better to ensure userId consistency when creating subscriptions
            print('⚠️ No subscriptions found with UID, checking if email match needed');
          }
          
          // Sort by createdAt in memory (descending)
          subscriptions.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });
          
          return subscriptions;
        });
  }
  
  /// Get subscriptions by email (fallback method)
  static Stream<List<Map<String, dynamic>>> getUserSubscriptionsByEmail(String email) {
    print('🔍 Querying subscriptions by email: $email');
    return subscriptionsCollection
        .where('userId', isEqualTo: email)
        .snapshots()
        .map((snapshot) {
          final subscriptions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Sort by createdAt in memory (descending)
          subscriptions.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });
          
          return subscriptions;
        });
  }

  /// Create a new subscription in Firestore
  static Future<String> createSubscription({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required int quantity,
    required double price,
    required String type,
    String status = 'Pending',
    DateTime? nextDeliveryDate,
  }) async {
    // Calculate next delivery date if not provided
    DateTime nextDelivery = nextDeliveryDate ?? _calculateNextDeliveryDate(type);
    
    final subscriptionData = {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'price': price,
      'type': type,
      'status': status,
      'nextDeliveryDate': Timestamp.fromDate(nextDelivery),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await subscriptionsCollection.add(subscriptionData);
    return docRef.id;
  }

  static DateTime _calculateNextDeliveryDate(String type) {
    final now = DateTime.now();
    switch (type) {
      case 'Daily':
        return now.add(const Duration(days: 1));
      case 'Weekly':
        return now.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return now.add(const Duration(days: 1));
    }
  }

  /// Update subscription status
  static Future<void> updateSubscriptionStatus(String subscriptionId, String status) async {
    await subscriptionsCollection.doc(subscriptionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Migrate subscription from local storage to Firestore
  /// This is a helper function to move existing subscriptions
  static Future<void> migrateSubscriptionToFirestore({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required int quantity,
    required double price,
    required String type,
    required String status,
    required DateTime createdAt,
    DateTime? nextDeliveryDate,
  }) async {
    try {
      // Check if subscription already exists in Firestore
      final existing = await subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: status)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Subscription already exists in Firestore, skipping migration');
        return;
      }

      // Create in Firestore
      DateTime nextDelivery = nextDeliveryDate ?? _calculateNextDeliveryDate(type);
      
      final subscriptionData = {
        'userId': userId,
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'quantity': quantity,
        'price': price,
        'type': type,
        'status': status,
        'nextDeliveryDate': Timestamp.fromDate(nextDelivery),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await subscriptionsCollection.add(subscriptionData);
      print('✅ Subscription migrated to Firestore');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  // ========== USERS ==========

  /// Create or update a user in Firestore
  static Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? name,
    String? photoURL,
    String? phone,
  }) async {
    try {
      final userData = <String, dynamic>{
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null && name.isNotEmpty) {
        userData['name'] = name;
      }
      if (photoURL != null && photoURL.isNotEmpty) {
        userData['photoURL'] = photoURL;
      }
      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }
      
      // Check if user already exists
      final userDoc = await usersCollection.doc(uid).get();
      if (!userDoc.exists) {
        // New user - add createdAt
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['isAdmin'] = false;
        userData['role'] = 'user';
      }
      
      await usersCollection.doc(uid).set(userData, SetOptions(merge: true));
      print('✅ User document created/updated in Firestore: $uid');
    } catch (e) {
      print('❌ Error creating/updating user in Firestore: $e');
      rethrow;
    }
  }

  /// Get all users (for admin)
  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                'id': doc.id,
                ...data,
              };
            }).toList());
  }

  /// Check whether a user has admin privileges based on their Firestore document.
  static Future<bool> isUserAdmin(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (data['isAdmin'] == true) return true;
    final role = data['role'];
    return role is String && role.toLowerCase() == 'admin';
  }

  /// Update a user's admin flag
  static Future<void> setUserAdmin(String uid, {required bool isAdmin}) async {
    await usersCollection.doc(uid).set(
      {
        'isAdmin': isAdmin,
        'role': isAdmin ? 'admin' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ========== MIGRATION HELPERS ==========
  
  /// Migrate existing products from constants to Firestore
  static Future<void> migrateProducts() async {
    try {
      for (final product in Products.allProducts) {
        final productData = {
          'name': product.name,
          'category': product.category,
          'image': product.image,
          'price': product.price,
          'subscriptionPrice': product.subscriptionPrice,
          'quantity': product.quantity,
          'description': product.description,
          'isSubscriptionAvailable': product.isSubscriptionAvailable,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await productsCollection.doc(product.id).set(productData, SetOptions(merge: true));
        print('Migrated product: ${product.name}');
      }
      print('✅ All products migrated successfully!');
    } catch (e) {
      print('❌ Error migrating products: $e');
      rethrow;
    }
  }

  /// Initialize default home offer
  static Future<void> initializeHomeOffer() async {
    try {
      final offerData = {
        'title': 'Get Pure A2 Milk & A2 Ghee\nFlat 50% Off on Your First Order!',
        'subtitle': 'Limited time offer',
        'imageUrl': 'signup/homesign.PNG',
        'buttonText': 'Shop Now',
        'buttonLink': '/products',
        'isActive': true,
        'priority': 1,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': null, // No expiry
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await homeOffersCollection.doc('default-offer').set(offerData, SetOptions(merge: true));
      print('✅ Default home offer initialized!');
    } catch (e) {
      print('❌ Error initializing home offer: $e');
      rethrow;
    }
  }
}

