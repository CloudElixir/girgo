import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

/// Returns true if the user is signed in. If not, presents [LoginScreen] in a
/// modal sheet (add to cart, checkout, account actions) and returns true only
/// after a successful sign-in (or false if dismissed).
Future<bool> ensureSignedIn(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (auth.isAuthenticated) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final h = MediaQuery.sizeOf(sheetContext).height;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          height: h * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: const LoginScreen(popOnSuccess: true),
        ),
      );
    },
  );

  if (!context.mounted) return false;
  if (result == true) return true;

  return Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
}
