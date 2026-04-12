import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

/// Wrap admin-only widgets with this gate to ensure only admins can see them.
class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please sign in to access admin tools.';
        });
        return;
      }

      final isAdmin = await FirestoreService.isUserAdmin(user.uid);
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
        if (!isAdmin) {
          _error = 'Your account is not authorized for admin access.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to verify admin access: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Admin access required.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}


