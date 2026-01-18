// lib/screens/register_screen.dart
// Modern registration screen with blue color scheme, matching login design (RF-01)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/app_config.dart';
import '../repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;

  const RegisterScreen({super.key, this.initialEmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  final _authRepo = AuthRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Blue color scheme (matching login screen)
  static const Color _darkBlue = Color(0xFF1E3A5F);
  static const Color _mediumBlue = Color(0xFF2563EB);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _paleBlue = Color(0xFFDBEAFE);
  static const Color _veryLightBlue = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return 'Digite seu nome';
    }
    if (name.length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  String? _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Digite seu email';
    }
    final emailRegex = RegExp(r'^.+@.+\..+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Digite um email válido';
    }
    return null;
  }

  String? _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return 'Digite sua senha';
    }
    if (password.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      return 'Confirme sua senha';
    }
    if (confirmPassword != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  Future<void> _register() async {
    // Validate all fields
    final nameError = _validateName();
    if (nameError != null) {
      _showError(nameError);
      return;
    }

    final emailError = _validateEmail();
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final passwordError = _validatePassword();
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    final confirmPasswordError = _validateConfirmPassword();
    if (confirmPasswordError != null) {
      _showError(confirmPasswordError);
      return;
    }

    if (!_acceptedTerms) {
      _showError('Aceite os termos para continuar');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nome: _nameController.text.trim(),
        termosAceitos: _acceptedTerms,
      );
      if (mounted) {
        await _showEmailConfirmationDialog(_emailController.text.trim());
      }
    } on AuthException catch (e) {
      if (mounted) {
        final errorMessage = _translateAuthError(e.message);

        // Check if user already exists
        if (e.message.contains('User already registered') ||
            e.message.contains('already been registered')) {
          _showSuggestionDialog(
            message: 'Este email já está cadastrado. Deseja fazer login?',
            onConfirm: () => Navigator.of(context).pop(),
          );
        } else {
          _showError(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao criar conta: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('User already registered') ||
        message.contains('already been registered')) {
      return 'Este email já está cadastrado';
    }
    if (message.contains('Invalid email')) {
      return 'Email inválido';
    }
    if (message.contains('Password')) {
      return 'Senha muito fraca';
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

  Future<void> _showEmailConfirmationDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightBlue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: _mediumBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifique seu email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enviamos um link de confirmação para:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Clique no link do email para ativar sua conta.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _mediumBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to login
              },
              child: const Text('ENTENDI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: _mediumBlue),
      prefixIcon: Icon(prefixIcon, color: _mediumBlue),
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: _veryLightBlue,
    );
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
                  const SizedBox(height: 30),

                  // Logo and branding
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _lightBlue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    'Crie sua conta para começar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Registration form card
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
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _darkBlue,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name field
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _buildInputDecoration(
                            labelText: 'Nome Completo',
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _buildInputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: _mediumBlue,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _buildInputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: _mediumBlue,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Terms checkbox
                        Theme(
                          data: Theme.of(context).copyWith(
                            checkboxTheme: CheckboxThemeData(
                              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return _mediumBlue;
                                }
                                return Colors.transparent;
                              }),
                              side: BorderSide(color: _mediumBlue, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                            title: Text(
                              'Aceito os Termos de Uso e Política de Privacidade',
                              style: TextStyle(
                                fontSize: 13,
                                color: _darkBlue,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Register button
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
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('CRIAR CONTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem conta? ',
                        style: TextStyle(color: Colors.white.withOpacity(0.85)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Entrar',
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

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
