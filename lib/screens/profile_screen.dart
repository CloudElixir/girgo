import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tab_controller_provider.dart';
import 'login_screen.dart';
import '../utils/require_auth.dart';
import '../widgets/cart_icon_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String?> _userData = {'name': '', 'email': ''};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userData = {
        'name': prefs.getString('userName') ?? 'User',
        'email': prefs.getString('userEmail') ?? '',
      };
    });
  }

  Future<Map<String, String?>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName'),
      'email': prefs.getString('userEmail'),
    };
  }

  Future<void> _callSupport(BuildContext context) async {
    // Navigate to contact screen instead of directly calling
    Navigator.pushNamed(context, '/contact');
  }

  Future<void> _whatsappSupport() async {
    final uri = Uri.parse('https://wa.me/919964544144?text=Hello%20Girgo%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: const [
          CartIconButton(),
        ],
      ),
      body: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final authed = authProvider.isAuthenticated;
              return SingleChildScrollView(
                child: Column(
              children: [
                // Profile Header with decorative background
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0B510E),
                          Color(0xFF2D7C32),
                        ],
                      ),
                      image: const DecorationImage(
                        image: AssetImage('signup/homesign.PNG'),
                        fit: BoxFit.cover,
                        opacity: 0.18,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.85),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          authed ? (_userData['name'] ?? 'User') : 'Guest',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          authed
                              ? (_userData['email'] ?? '')
                              : 'Browse products freely — sign in to order',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (authed)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.pushNamed(context, '/edit-profile');
                              if (result == true) {
                                await _loadUserData();
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.large),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(
                                    popOnSuccess: true,
                                  ),
                                ),
                              );
                              if (mounted) await _loadUserData();
                            },
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('Sign in'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.large),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Wallet Card (Coming soon)
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wallet feature is coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Wallet Balance', style: AppTextStyles.bodySmall),
                              const Text(
                                '₹0',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tap to see what\'s coming next',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet top-up is coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Add Money'),
                        ),
                      ],
                    ),
                  ),
                ),
                // Account Section
                _buildSection(
                  title: 'Account',
                  children: [
                    _buildMenuItem(
                      icon: Icons.receipt,
                      title: 'My Orders',
                      onTap: () async {
                        if (!await ensureSignedIn(context) || !context.mounted) return;
                        Navigator.pushNamed(context, '/orders');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.repeat,
                      title: 'Subscriptions',
                      onTap: () async {
                        if (!await ensureSignedIn(context) || !context.mounted) return;
                        final tabController = Provider.of<TabControllerProvider>(context, listen: false);
                        tabController.setIndex(2);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.description,
                      title: 'Transactions',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transactions will be available soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Support Section
                _buildSection(
                  title: 'Support',
                  children: [
                    _buildMenuItem(
                      icon: Icons.phone,
                      title: 'Call Support',
                      onTap: () => _callSupport(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.chat,
                      title: 'WhatsApp Support',
                      onTap: _whatsappSupport,
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & FAQ',
                      onTap: () {
                        Navigator.pushNamed(context, '/help');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy-policy');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () {
                        Navigator.pushNamed(context, '/terms');
                      },
                    ),
                  ],
                ),
                if (authed) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await authProvider.signOut();
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign out error: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.logout),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDeleteAccountButton(context, authProvider),
                ],
              ],
              ),
            );
            },
          ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onPressed: () => _showDeleteAccountDialog(context, authProvider),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_forever),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await authProvider.deleteAccount();

      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 4),
          action: msg.contains('recent')
              ? SnackBarAction(
                  label: 'Sign out',
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                )
              : null,
        ),
      );
    }
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(title, style: AppTextStyles.heading3),
        ),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}

