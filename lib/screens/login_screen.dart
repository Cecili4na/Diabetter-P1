// lib/screens/login_screen.dart
// Modern login screen with blue color scheme, Portuguese translations and password reset (RF-01)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../repositories/auth_repository.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Blue color scheme
  static const Color _darkBlue = Color(0xFF1E3A5F);
  static const Color _mediumBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _paleBlue = Color(0xFFDBEAFE);
  static const Color _veryLightBlue = Color(0xFFEFF6FF);

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Digite seu email');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showError('Digite sua senha');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // In mock mode, navigate manually
      if (AppConfig.isMockMode && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on AuthException catch (e) {
      final errorMessage = _translateAuthError(e.message);
      _showError(errorMessage);

      // If invalid credentials, suggest registration
      if (e.message.contains('Invalid login credentials')) {
        _showSuggestionDialog(
          message: 'Não encontramos uma conta com este email. Deseja criar uma conta?',
          onConfirm: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegisterScreen(initialEmail: _emailController.text.trim()),
              ),
            );
          },
        );
      }
    } catch (e) {
      _showError('Erro ao fazer login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu email antes de fazer login';
    }
    return message;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  Future<void> _showSuggestionDialog({
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: _mediumBlue),
            const SizedBox(width: 8),
            const Text('Atenção'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NÃO', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _mediumBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIM'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu email para receber um link de recuperação de senha.'),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: AppButtonStyles.primary,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ENVIAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && resetEmailController.text.isNotEmpty) {
      await _sendPasswordResetEmail(resetEmailController.text.trim());
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      if (!AppConfig.isMockMode) {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email de recuperação enviado para $email'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao enviar email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBlue, _mediumBlue],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and branding
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _lightBlue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Diabetter',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Controle do diabetes, melhor com diabetter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Login form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _paleBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _darkBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: _mediumBlue),
                            prefixIcon: Icon(Icons.email_outlined, color: _mediumBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _lightBlue.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _mediumBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: _veryLightBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            labelStyle: TextStyle(color: _mediumBlue),
                            prefixIcon: Icon(Icons.lock_outline, color: _mediumBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: _mediumBlue,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _lightBlue),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _lightBlue.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _mediumBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: _veryLightBlue,
                          ),
                        ),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              'Esqueci minha senha',
                              style: TextStyle(color: _mediumBlue, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Login button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _mediumBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem conta? ',
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                initialEmail: _emailController.text.trim().isNotEmpty
                                    ? _emailController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Mock mode indicator
                  if (AppConfig.isMockMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _lightBlue.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Modo de Teste',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
