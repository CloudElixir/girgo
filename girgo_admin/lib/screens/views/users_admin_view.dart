import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class UsersAdminView extends StatefulWidget {
  const UsersAdminView({super.key});

  @override
  State<UsersAdminView> createState() => _UsersAdminViewState();
}

class _UsersAdminViewState extends State<UsersAdminView> {
  String _searchQuery = '';
  String? _selectedRole;

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    try {
      await FirestoreService.setUserAdmin(userId, isAdmin: isAdmin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdmin ? 'User granted admin access' : 'Admin access revoked'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete user?'),
          content: const Text('This will remove the user record from Firestore. The user can still sign in unless their Auth account is deleted separately.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User record deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allUsers = snapshot.data!;
        
        // Filter users
        var filteredUsers = allUsers.where((user) {
          final matchesSearch = _searchQuery.isEmpty ||
              (user['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (user['email']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (user['id']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
          final isAdmin = user['isAdmin'] == true || user['role'] == 'admin';
          final matchesRole = _selectedRole == null ||
              (_selectedRole == 'Admin' && isAdmin) ||
              (_selectedRole == 'User' && !isAdmin);
          
          return matchesSearch && matchesRole;
        }).toList();

        return Column(
          children: [
            // Header with search and filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users by name, email, or ID...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedRole,
                        hint: const Text('All Roles'),
                        items: const [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'User',
                            child: Text('User'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _selectedRole = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Users list
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allUsers.isEmpty
                                ? 'No users found.'
                                : 'No users match your search.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isAdmin = user['isAdmin'] == true || user['role'] == 'admin';
                        final email = user['email'] ?? user['id'] ?? 'Unknown';
                        final name = user['name'] ?? 'Unknown User';
                        final phone = user['phone'] ?? '';
                        final createdAt = user['createdAt'];
                        final dateStr = createdAt != null
                            ? (createdAt as dynamic).toDate().toString().substring(0, 10)
                            : 'Unknown date';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? Colors.orange : Colors.blue,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email),
                                if (phone.isNotEmpty) Text(phone),
                                Text(
                                  'Joined: $dateStr',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    isAdmin ? 'Admin' : 'User',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: isAdmin
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isAdmin ? Colors.orange[700] : Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: isAdmin,
                                  onChanged: (value) => _toggleAdmin(
                                    user['id'] as String,
                                    value,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.redAccent,
                                  tooltip: 'Delete user',
                                  onPressed: () => _deleteUser(user['id'] as String),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
