import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/core/utils/validators.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:flutter/gestures.dart';
import '../../../profile/presentation/screens/legal_screen.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';

/// Écran d'inscription
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedCgu = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getUserFriendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur. Vérifiez que le backend est démarré '
              'et que l\'appareil est sur le même réseau (${AppConstants.apiBaseUrl.replaceFirst('/api/v1', '')}).';
        case DioExceptionType.badResponse:
          final msg = e.response?.data is Map ? (e.response!.data as Map)['message'] : null;
          return msg?.toString() ?? 'Erreur serveur (${e.response?.statusCode})';
        default:
          break;
      }
    }
    return e.toString();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        // Mettre à jour les providers pour forcer la relecture car register synchronise déjà
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAuthToken);

        if (token != null) {
          ref.read(authTokenProvider.notifier).state = token;
          ref.invalidate(userEmailProvider);
          ref.invalidate(userIdProvider);
          ref.invalidate(isAuthenticatedProvider);
          ref.invalidate(userAvatarUrlProvider);
          ref.invalidate(userProfileProvider);

          ApiClient.reset();
          context.go(AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès ! Connectez-vous.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Bouton retour personnalisé
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.cloviGreen,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              
              const SizedBox(height: 20),

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
              const SizedBox(height: 32),

              // Carte d'inscription
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
                      // Titre "Sign Up"
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // First name
                      TextFormField(
                        controller: _firstNameController,
                        validator: (v) => Validators.required(v, fieldName: 'Le prénom'),
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(
                            color: AppColors.cloviGreen,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outlined,
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

                      // Last name
                      TextFormField(
                        controller: _lastNameController,
                        validator: (v) => Validators.required(v, fieldName: 'Le nom'),
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(
                            color: AppColors.cloviGreen,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outlined,
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

                      // Email
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

                      // Password
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
                      const SizedBox(height: 16),

                      // Confirm password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
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
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.cloviGreen,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword);
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

                      // CGU Acceptance
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: AppColors.cloviGreen,
                        ),
                        child: CheckboxListTile(
                          value: _acceptedCgu,
                          onChanged: (val) =>
                              setState(() => _acceptedCgu = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.cloviGreen,
                          title: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                              children: [
                                const TextSpan(
                                  text: "J'accepte les ",
                                ),
                                TextSpan(
                                  text: "Conditions Générales d'Utilisation",
                                  style: const TextStyle(
                                    color: AppColors.cloviGreen,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CguScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(
                                  text: " de Clovi.",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Register button
                      ElevatedButton(
                        onPressed: (_isLoading || !_acceptedCgu) ? null : _handleRegister,
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Divider
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
                            icon: 'assets/images/google_logo.png',
                            label: 'Google',
                            onPressed: !_acceptedCgu ? null : () => _handleSocialLogin('google'),
                            color: Colors.white,
                            textColor: Colors.black87,
                          ),
                          const SizedBox(width: 16),
                          // Apple Button
                          _buildSocialButton(
                            icon: 'assets/images/apple_logo.png',
                            label: 'Apple',
                            onPressed: !_acceptedCgu ? null : () => _handleSocialLogin('apple'),
                            color: Colors.black,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login link
                      TextButton(
                        onPressed: () => context.pop(),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1A1A1A),
                            ),
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text: 'Log In',
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
              const SizedBox(height: 24),
            ],
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
            fontFamily: 'Cursive',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    VoidCallback? onPressed,
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