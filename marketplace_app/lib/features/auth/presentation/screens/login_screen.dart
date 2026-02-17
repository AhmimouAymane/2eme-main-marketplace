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

        // Réinitialiser le client API pour prendre en compte le nouveau token
        ApiClient.reset();
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
      backgroundColor: const Color(0xFFF5F5F0), // Couleur de fond beige clair
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
                    color: const Color(0xFF2D5F4F),
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
                              color: const Color(0xFF2D5F4F),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: const Color(0xFF2D5F4F),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF2D5F4F),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF2D5F4F),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF2D5F4F),
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
                              color: const Color(0xFF2D5F4F),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: const Color(0xFF2D5F4F),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF2D5F4F),
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
                                color: const Color(0xFF2D5F4F),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF2D5F4F),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF2D5F4F),
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
                            backgroundColor: const Color(0xFF1B4332),
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
                          onPressed: () {
                            // TODO: Ajouter la navigation vers mot de passe oublié
                          },
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
                                    color: const Color(0xFF2D5F4F),
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
            color: const Color(0xFF2D5F4F),
            fontFamily: 'Cursive', // Vous pouvez utiliser une police cursive personnalisée
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// Painter pour dessiner le cintre
class HangerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D5F4F)
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