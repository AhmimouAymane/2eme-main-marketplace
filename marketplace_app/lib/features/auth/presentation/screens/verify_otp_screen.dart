import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String type; // 'REGISTRATION' ou 'PASSWORD_RESET'

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.verifyOtp(
        email: widget.email,
        code: _codeController.text.trim(),
        type: widget.type,
      );

      if (mounted) {
        if (widget.type == 'REGISTRATION') {
          // Success registration -> Go to home (provider will handle navigation usually)
          // or show success and pop to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compte vérifié avec succès !')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Password reset -> Go to New Password screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: widget.email,
                code: _codeController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Un code de vérification a été envoyé à ${widget.email}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                  hintText: '123456',
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Entrez le code';
                  if (value.length != 6) return 'Le code doit avoir 6 chiffres';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cloviGreen,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Vérifier', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
