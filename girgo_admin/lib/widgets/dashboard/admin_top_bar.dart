import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../theme/admin_theme.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({
    super.key,
    required this.sectionTitle,
    this.subtitle,
    this.compact = false,
  });

  final String sectionTitle;
  final String? subtitle;
  final bool compact;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: GirgoBrand.white,
      child: Container(
        decoration: const BoxDecoration(
          color: GirgoBrand.white,
          border: Border(
            bottom: BorderSide(color: GirgoBrand.borderLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (compact) ...[
                    Builder(
                      builder: (ctx) => IconButton(
                        tooltip: 'Menu',
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: GirgoBrand.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle ?? 'Store overview & operations',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: GirgoBrand.blackMuted.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You’re all caught up — no new notifications.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: GirgoBrand.blackMuted.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final user = auth.user;
                      if (user == null) return const SizedBox.shrink();
                      final email = user.email ?? 'Account';
                      return PopupMenuButton<String>(
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: GirgoBrand.greenSoft,
                                backgroundImage:
                                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                                child: user.photoURL == null
                                    ? Text(
                                        email.isNotEmpty ? email[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: GirgoBrand.green,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                              if (MediaQuery.sizeOf(context).width > 520) ...[
                                const SizedBox(width: 10),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: GirgoBrand.black,
                                        ),
                                      ),
                                      Text(
                                        'Administrator',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: GirgoBrand.blackMuted.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: GirgoBrand.blackMuted.withValues(alpha: 0.6),
                                ),
                              ],
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.person_outline_rounded, size: 20),
                              title: const Text('Signed in'),
                              subtitle: Text(
                                email,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'signout',
                            child: const ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.logout_rounded, size: 20, color: Color(0xFFB3261E)),
                              title: Text('Sign out'),
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'signout') {
                            await context.read<AuthProvider>().signOut();
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
