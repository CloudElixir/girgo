import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/migrate_to_firestore.dart';

/// One-time migration screen to upload data to Firestore
/// Remove this screen after migration is complete
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isMigrating = false;
  String _status = 'Ready to migrate';
  bool _migrationComplete = false;

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Initializing Firebase...';
    });

    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      
      setState(() {
        _status = 'Migrating data to Firestore...';
      });

      // Run migration
      await FirestoreMigration.runMigration();

      setState(() {
        _isMigrating = false;
        _migrationComplete = true;
        _status = '✅ Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Migrate Data to Firestore',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _migrationComplete ? Colors.green : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_migrationComplete)
              ElevatedButton(
                onPressed: _isMigrating ? null : _runMigration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: _isMigrating
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Migrating...'),
                        ],
                      )
                    : const Text('Start Migration'),
              ),
            if (_migrationComplete) ...[
              const SizedBox(height: 16),
              const Text(
                '✅ Your data has been uploaded to Firestore!\n\n'
                'You can now:\n'
                '1. Check Firebase Console to verify\n'
                '2. Update app to read from Firestore\n'
                '3. Build admin panel to manage data',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

