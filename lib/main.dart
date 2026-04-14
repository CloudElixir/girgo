import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/tab_controller_provider.dart';
import 'providers/products_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/help_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/migration_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_screen.dart';
import 'constants/theme.dart';
import 'services/push_notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Firebase background handler must be registered before [runApp] (FlutterFire requirement).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Release-safe: avoid blank screen if a subtree throws during build (e.g. bad asset on iOS).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Flutter widget error: ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
    // Never show a spinner for build failures — that looks like "infinite loading"
    // (bad for App Review and users). Show a simple recovery UI instead.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  Text(
                    kReleaseMode
                        ? 'Something went wrong loading this screen.\n'
                            'Please switch tabs or restart the app.'
                        : details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: kReleaseMode ? 15 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  debugPrint('APP START');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const GirgoStartup());
}

/// Shows an immediate loading UI, then completes Firebase core init without blocking [runApp] itself.
class GirgoStartup extends StatefulWidget {
  const GirgoStartup({super.key});

  @override
  State<GirgoStartup> createState() => _GirgoStartupState();
}

class _GirgoStartupState extends State<GirgoStartup> {
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 12));
      }
      debugPrint('FIREBASE INIT SUCCESS');
    } on TimeoutException catch (e) {
      debugPrint('FIREBASE INIT FAIL: timeout after 12s — $e');
    } catch (e, st) {
      debugPrint('FIREBASE INIT FAIL: $e');
      debugPrint('$st');
    }

    try {
      await FirebaseService.initialize();
    } catch (e, st) {
      debugPrint('FIREBASE INIT FAIL: FirebaseService — $e');
      debugPrint('$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              useMaterial3: true,
            ),
            home: Scaffold(
              backgroundColor: AppColors.primary,
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Girgo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint('FIREBASE INIT FAIL: ${snapshot.error}');
        }
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _pushSetupScheduled = false;

  @override
  Widget build(BuildContext context) {
    if (!_pushSetupScheduled) {
      _pushSetupScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Never block first frame: push permissions & FCM run after UI is visible.
        PushNotificationService.initialize(navigatorKey: appNavigatorKey);
      });
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => TabControllerProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Girgo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          useMaterial3: true,
        ),
        // Start normally, then fix deep links on web manually.
        initialRoute: '/',
        builder: (context, child) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              var path = Uri.base.path;
              if (path.endsWith('/')) {
                path = path.substring(0, path.length - 1);
              }
              if (path == '/migrate') {
                final current = ModalRoute.of(context)?.settings.name;
                if (current != '/migrate') {
                  Navigator.of(context).pushReplacementNamed('/migrate');
                }
              }
            });
          }
          return child ??
              const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
        },
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(popOnSuccess: false),
          '/home': (context) => const MainScreen(),
          '/billing': (context) => const BillingScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/transactions': (context) => const TransactionsScreen(),
          '/help': (context) => const HelpScreen(),
          '/contact': (context) => const ContactScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/migrate': (context) => const MigrationScreen(), // Temporary route for migration
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/terms': (context) => const TermsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Guest browsing (Home / Products / details) without login; sign-in is
    // required only for cart, checkout, and account-specific screens.
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductsScreen(),
    const SubscriptionsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowAddPhonePrompt();
    });
  }

  Future<void> _maybeShowAddPhonePrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final justLoggedInUid = prefs.getString('justLoggedInUid');
      if (justLoggedInUid == null || justLoggedInUid.isEmpty) return;

      // Clear the marker immediately so the prompt is shown at most once per login.
      await prefs.remove('justLoggedInUid');

      final skipKey = 'skipAddPhonePrompt_$justLoggedInUid';
      if (prefs.getBool(skipKey) == true) return;

      final localPhone = (prefs.getString('userMobile') ?? '').trim();
      final hasPhone = localPhone.isNotEmpty;
      if (hasPhone) return;

      if (!mounted) return;
      // Non-blocking, skippable prompt after login.
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: false,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add your phone number to unlock full features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can skip for now and continue using the app.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(skipKey, true);
                            } catch (_) {}
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/edit-profile');
                          },
                          child: const Text('Add phone'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Add phone prompt check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabControllerProvider>(
      builder: (context, tabController, child) {
        return Scaffold(
          body: IndexedStack(
            index: tabController.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabController.currentIndex,
            onTap: (index) {
              tabController.setIndex(index);
            },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Subscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
          ),
        );
      },
    );
  }
}
