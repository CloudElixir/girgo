/// Migration script to upload existing data to Firestore
/// Run this once to populate your Firestore database
/// 
/// Usage: Call this from your app's initialization or create a one-time migration screen

import '../services/firestore_service.dart';

class FirestoreMigration {
  /// Run complete migration
  static Future<void> runMigration() async {
    print('🚀 Starting Firestore migration...');
    
    try {
      // 1. Migrate products
      print('\n📦 Migrating products...');
      await FirestoreService.migrateProducts();
      
      // 2. Initialize home offer
      print('\n🎯 Initializing home offer...');
      await FirestoreService.initializeHomeOffer();
      
      print('\n✅ Migration completed successfully!');
      print('📊 Your Firestore database is now populated with:');
      print('   - All products from constants');
      print('   - Default home offer');
      print('\n💡 Next steps:');
      print('   1. Check Firestore console to verify data');
      print('   2. Update your app to read from Firestore instead of constants');
      print('   3. Build admin panel to manage this data');
      
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }
}

