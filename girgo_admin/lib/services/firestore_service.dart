import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  /// Get all products including inactive ones (for admin panel)
  static Stream<List<Map<String, dynamic>>> getAllProducts() {
    return productsCollection.snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          ...data,
          'id': doc.id,
        };
      }).toList();

      products.sort((a, b) {
        final aOrder = (a['sortOrder'] as num?)?.toInt() ?? 1 << 30;
        final bOrder = (b['sortOrder'] as num?)?.toInt() ?? 1 << 30;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });

      return products;
    });
  }

  /// Add a product
  static Future<void> addProduct(Map<String, dynamic> productData) async {
    await productsCollection.add({
      ...productData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a product
  static Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    await productsCollection.doc(productId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a product permanently
  static Future<void> deleteProduct(String productId) async {
    await productsCollection.doc(productId).delete();
  }

  /// Toggle product active state
  static Future<void> setProductActiveState(String productId, bool isActive) async {
    await productsCollection.doc(productId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Persist visual ordering for products in admin/product screens.
  static Future<void> setProductsDisplayOrder(List<String> productIds) async {
    final batch = _firestore.batch();
    for (var i = 0; i < productIds.length; i++) {
      final id = productIds[i].trim();
      if (id.isEmpty) continue;
      batch.update(productsCollection.doc(id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ========== HOME OFFERS ==========
  
  /// Get all home offers (for admin)
  static Stream<List<Map<String, dynamic>>> getAllHomeOffers() {
    return homeOffersCollection
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return <String, dynamic>{
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  /// Add a home offer
  static Future<void> addHomeOffer(Map<String, dynamic> offerData) async {
    await homeOffersCollection.add({
      ...offerData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a home offer
  static Future<void> updateHomeOffer(String offerId, Map<String, dynamic> updates) async {
    await homeOffersCollection.doc(offerId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a home offer
  static Future<void> deleteHomeOffer(String offerId) async {
    await homeOffersCollection.doc(offerId).delete();
  }

  // ========== BLOGS ==========

  /// Get all blog posts
  static Stream<List<Map<String, dynamic>>> getAllBlogs() {
    return blogsCollection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              ...data,
              'id': doc.id,
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

  /// Delete a blog post
  static Future<void> deleteBlog(String blogId) async {
    await blogsCollection.doc(blogId).delete();
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
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await ordersCollection.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Shown in the customer app order detail (delivery updates, rider contact, etc.).
  static Future<void> updateOrderTrackingNote(String orderId, String? trackingNote) async {
    final note = trackingNote?.trim();
    if (note == null || note.isEmpty) {
      await ordersCollection.doc(orderId).update({
        'trackingNote': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ordersCollection.doc(orderId).update({
        'trackingNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ========== SUBSCRIPTIONS ==========

  /// Get all subscriptions (for admin)
  static Stream<List<Map<String, dynamic>>> getAllSubscriptions() {
    return subscriptionsCollection
        .snapshots()
        .map((snapshot) {
          final subscriptions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              ...data,
              'id': doc.id,
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

  /// Update subscription status
  static Future<void> updateSubscriptionStatus(String subscriptionId, String status) async {
    await subscriptionsCollection.doc(subscriptionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== USERS ==========

  /// Get all users (for admin)
  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return usersCollection
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return <String, dynamic>{
              ...data,
              'id': doc.id,
            };
          }).toList();
          
          // Sort by createdAt in memory (descending) to avoid index requirement
          users.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });
          
          return users;
        });
  }

  /// Check whether a user has admin privileges
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

  /// Delete a user record from Firestore.
  ///
  /// Note: This only removes the document from the "users" collection.
  /// It does not delete the user account from Firebase Authentication.
  static Future<void> deleteUser(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  /// Get user information by ID
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return {
        ...data,
        'id': doc.id,
      };
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // ========== APP CONFIG ==========

  static DocumentReference get appConfigDoc => appConfigCollection.doc('global');

  static Future<Map<String, dynamic>> getAppConfig() async {
    final doc = await appConfigDoc.get();
    if (!doc.exists) return {};
    return doc.data() as Map<String, dynamic>;
  }

  static Future<void> updateAppConfig(Map<String, dynamic> data) async {
    await appConfigDoc.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ========== HOME · FEATURED PRODUCTS ==========

  static DocumentReference get homeFeaturedConfigDoc => appConfigCollection.doc('home');

  static Stream<Map<String, dynamic>?> getHomeFeaturedConfigStream() {
    return homeFeaturedConfigDoc.snapshots().map((s) {
      if (!s.exists) return null;
      return s.data() as Map<String, dynamic>?;
    });
  }

  /// Ordered list of Firestore product document IDs (max 8) for the customer app home grid.
  /// [titles] is optional and aligned by index to [ids], used for compact card labels in app.
  static Future<void> setHomeFeaturedProductIds(
    List<String> ids, {
    List<String>? titles,
  }) async {
    final safeTitles = (titles ?? const <String>[])
        .map((e) => e.trim())
        .toList();
    await homeFeaturedConfigDoc.set(
      {
        'featuredProductIds': ids,
        'featuredProductTitles': safeTitles,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Remove custom list so the app uses its default category-based features section.
  static Future<void> clearHomeFeaturedOverride() async {
    await homeFeaturedConfigDoc.set(
      {
        'featuredProductIds': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

