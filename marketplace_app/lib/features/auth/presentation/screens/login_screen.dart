import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/core/utils/validators.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';

/// Écran de connexion
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Mettre à jour les providers pour forcer la relecture
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAuthToken);

        ref.read(authTokenProvider.notifier).state = token;
        ref.invalidate(userEmailProvider);
        ref.invalidate(userIdProvider);
        ref.invalidate(isAuthenticatedProvider);
        ref.invalidate(userAvatarUrlProvider);
        ref.invalidate(userProfileProvider);

        // Réinitialiser le client API pour prendre en compte le nouveau token
        ApiClient.reset();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message), 
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse email valide'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isLoading) return; // Empêche les clics multiples
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé !'),
            backgroundColor: AppColors.cloviGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message), 
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      Map<String, dynamic> result;
      
      if (provider == 'google') {
        result = await authService.signInWithGoogle();
      } else {
        result = await authService.signInWithApple();
      }

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAuthToken);

        ref.read(authTokenProvider.notifier).state = token;
        ref.invalidate(userEmailProvider);
        ref.invalidate(userIdProvider);
        ref.invalidate(isAuthenticatedProvider);
        ref.invalidate(userAvatarUrlProvider);
        ref.invalidate(userProfileProvider);

        ApiClient.reset();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message), 
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.cloviBeige, // Inherited from theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo du cintre avec "clovi"
                _buildLogo(),
                const SizedBox(height: 12),

                // Sous-titre
                Text(
                  'Your second-hand\nfashion companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.cloviGreen,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Carte de connexion
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre "Log In"
                        Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: AppColors.cloviGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppColors.cloviGreen,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: AppColors.cloviGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: AppColors.cloviGreen,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.cloviGreen,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.cloviGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cloviDarkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot password link
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Social Logins Title
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or continue with',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Social Login Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Button
                            _buildSocialButton(
                              icon: 'assets/images/google_logo.png', // Note: ensure this asset exists or use icon
                              label: 'Google',
                              onPressed: () => _handleSocialLogin('google'),
                              color: Colors.white,
                              textColor: Colors.black87,
                            ),
                            const SizedBox(width: 16),
                            // Apple Button
                            _buildSocialButton(
                              icon: 'assets/images/apple_logo.png', // Note: ensure this asset exists or use icon
                              label: 'Apple',
                              onPressed: () => _handleSocialLogin('apple'),
                              color: Colors.black,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        Container(
                          height: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                        const SizedBox(height: 16),

                        // Register link
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A),
                              ),
                              children: [
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cloviGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Cintre dessiné avec CustomPaint
        CustomPaint(
          size: const Size(100, 60),
          painter: HangerPainter(),
        ),
        const SizedBox(height: 8),
        // Texte "clovi"
        Text(
          'clovi',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.cloviGreen,
            fontFamily: 'Cursive', // Vous pouvez utiliser une police cursive personnalisée
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using icons placeholder since I don't know the exact asset paths
            Icon(
              label == 'Google' ? Icons.g_mobiledata_rounded : Icons.apple_rounded,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter pour dessiner le cintre
class HangerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cloviGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Crochet du cintre
    final hookCenter = Offset(size.width / 2, 10);
    canvas.drawCircle(hookCenter, 8, paint);

    // Ligne verticale du crochet
    path.moveTo(size.width / 2, 18);
    path.lineTo(size.width / 2, 30);

    // Partie gauche du cintre (courbe)
    path.moveTo(size.width / 2, 30);
    path.quadraticBezierTo(
      size.width * 0.3, 35,
      size.width * 0.15, 50,
    );

    // Partie droite du cintre (courbe)
    path.moveTo(size.width / 2, 30);
    path.quadraticBezierTo(
      size.width * 0.7, 35,
      size.width * 0.85, 50,
    );

    // Barre horizontale du bas
    path.moveTo(size.width * 0.15, 50);
    path.lineTo(size.width * 0.85, 50);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}