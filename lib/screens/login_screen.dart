import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.popOnSuccess = false});

  /// When true (e.g. opened from "Add to cart"), pop with `true` after sign-in
  /// instead of replacing with `/home`.
  final bool popOnSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isSignUp = true; // Toggle between signup and signin
  bool _obscurePassword = true;

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _completeAuthSuccess() {
    if (!mounted) return;
    if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Sign up with Firebase Auth (this will create user in Firestore)
      await authProvider.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _mobileController.text,
      );
      
      _completeAuthSuccess();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Sign up failed: $e';
        // Provide more user-friendly error messages
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already registered. Please sign in instead.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak. Please use a stronger password.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address. Please check your email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Sign in with Firebase Auth
      await authProvider.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      _completeAuthSuccess();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Sign in failed: $e';
        // Provide more user-friendly error messages
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email. Please sign up first.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address. Please check your email.';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled. Please contact support.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      _completeAuthSuccess();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Google sign in failed. Please try again.';
        final raw = e.toString();
        if (e is FirebaseAuthException && e.message != null) {
          errorMessage = e.message!;
        } else if (raw.contains('ApiException: 10') ||
            raw.contains('sign_in_failed')) {
          errorMessage =
              'Google Sign-In (code 10): add this Android app’s SHA-1 in Firebase, '
              'download google-services.json again, rebuild. Email sign-in works meanwhile.';
        } else if (raw.contains('id token') ||
            raw.contains('invalid-credential')) {
          errorMessage =
              'Google Sign-In could not complete. Update the app from the store build '
              'with latest iOS settings, or use email sign-in.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _handleGmailSignIn() async {
    // Gmail uses Google Sign-In
    await _handleGoogleSignIn();
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithApple();
      _completeAuthSuccess();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Apple sign in failed: $e';
        if (e.toString().contains('only available on iOS')) {
          errorMessage = 'Apple Sign-In is only available on iOS and macOS. Please use Google Sign-In or Email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first to reset password')),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send reset email: $e')),
        );
      }
    }
  }

  // Helper methods for responsive design
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenWidth < 360 || screenHeight < 600) {
      return baseSize * 0.85;
    } else if (screenWidth < 400) {
      return baseSize * 0.9;
    }
    return baseSize;
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) {
      return baseSpacing * 0.75;
    }
    return baseSpacing;
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = _getResponsiveSize(context, 180);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
        if (widget.popOnSuccess)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Close',
            ),
          ),
        Positioned.fill(
          child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final heroHeight = screenHeight.clamp(500, double.infinity) == screenHeight
                ? screenHeight * 0.4
                : screenHeight * 0.5;
            final clampedHeroHeight = heroHeight.clamp(220.0, 360.0);
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: clampedHeroHeight,
                    width: double.infinity,
                    child: _buildHeroSection(logoSize),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSpacing(context, AppSpacing.xl),
                        vertical: _getResponsiveSpacing(context, AppSpacing.lg),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle between Sign Up and Sign In styled like the design
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFF0B510E),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSignUp = false;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: _getResponsiveSpacing(
                                            context,
                                            AppSpacing.sm,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isSignUp
                                              ? const Color(0xFF0B510E)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'Sign in',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: _getResponsiveSize(context, 14),
                                            fontWeight: FontWeight.w600,
                                            color: !_isSignUp
                                                ? Colors.white
                                                : const Color(0xFF0B510E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSignUp = true;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: _getResponsiveSpacing(
                                            context,
                                            AppSpacing.sm,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isSignUp
                                              ? const Color(0xFF0B510E)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'Sign up',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: _getResponsiveSize(context, 14),
                                            fontWeight: FontWeight.w600,
                                            color: _isSignUp
                                                ? Colors.white
                                                : const Color(0xFF0B510E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                            // Heading based on mode
                            Text(
                              _isSignUp ? 'Create your account' : 'Welcome back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _getResponsiveSize(context, 20),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D5016),
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
                            // Form fields - centered with proper spacing
                            // Name field (only for sign up)
                            if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E), width: 2),
                            ),
                          ),
                          validator: (value) {
                              if (_isSignUp && (value == null || value.isEmpty)) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                          SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                        ],
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                        // Mobile number field (only for sign up)
                        if (_isSignUp) ...[
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E), width: 2),
                            ),
                          ),
                          validator: (value) {
                              if (_isSignUp) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid mobile number';
                                }
                            }
                            return null;
                          },
                        ),
                          SizedBox(height: _getResponsiveSpacing(context, AppSpacing.md)),
                        ],
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                              borderSide: const BorderSide(color: Color(0xFF0B510E), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.xl)),
                            if (!_isSignUp)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _handleForgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            // Sign Up / Sign In button
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isAuthenticated
                                        ? null
                                        : (_isSignUp ? _handleSignUp : _handleSignIn),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B510E), // Dark green
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: _getResponsiveSpacing(context, AppSpacing.md),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      _isSignUp ? 'Sign Up' : 'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _getResponsiveSize(context, 16),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.lg)),
                            // "or continue with" divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _getResponsiveSpacing(
                                      context,
                                      AppSpacing.md,
                                    ),
                                  ),
                                  child: Text(
                                    'or continue with',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textLight,
                                      fontSize: _getResponsiveSize(context, 12),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.lg)),
                            // Social sign-in options (G and A buttons)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialCircleButton(
                                  label: 'G',
                                  onTap: _handleGoogleSignIn,
                                ),
                                SizedBox(
                                  width: _getResponsiveSpacing(
                                    context,
                                    AppSpacing.lg,
                                  ),
                                ),
                                _buildSocialCircleButton(
                                  label: 'A',
                                  onTap: _handleAppleSignIn,
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, AppSpacing.lg)),
                            // Terms and policy text with links (GestureDetector for in-app nav on web)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveSpacing(context, AppSpacing.md),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'By continuing, you agree to our ',
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, 11),
                                      color: AppColors.textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _launchExternal(
                                      'https://girgo.in/policies/terms-of-service',
                                    ),
                                    child: Text(
                                      'Terms of services',
                                      style: TextStyle(
                                        fontSize: _getResponsiveSize(context, 11),
                                        color: const Color(0xFF0B510E),
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, 11),
                                      color: AppColors.textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _launchExternal(
                                      'https://girgo.in/policies/privacy-policy',
                                    ),
                                    child: Text(
                                      'Privacy policy',
                                      style: TextStyle(
                                        fontSize: _getResponsiveSize(context, 11),
                                        color: const Color(0xFF0B510E),
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' content policy',
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, 11),
                                      color: AppColors.textLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(double logoSize) {
    return Stack(
      children: [
        // Green background with gradient and softly curved bottom edge
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: Stack(
            children: [
              // Cow background image with grass - stretch to fill entire area
              Positioned.fill(
                child: Image.asset(
                  'singup/homebg.PNG',
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
        // Circular logo in center (logo already contains gold circles)Rclea
        Center(
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'singup/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialCircleButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0B510E),
            width: 1.5,
          ),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B510E),
          ),
        ),
      ),
    );
  }
}
