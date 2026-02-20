
import 'package:flutter/material.dart';
import 'app_shell.dart';

class SafetyDisclaimerScreen extends StatelessWidget {
  const SafetyDisclaimerScreen({super.key});

  static const Color _darkBlue = Color(0xFF1E3A5F);
  static const Color _mediumBlue = Color(0xFF2563EB);
  static const Color _warningOrange = Color(0xFFEA580C);

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                
                // Warning Icon with animated appearance
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _warningOrange.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _warningOrange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _warningOrange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Aviso Importante',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Disclaimer text in a card
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildDisclaimerParagraph(
                            'Este aplicativo tem finalidade exclusivamente informativa, '
                            'para registro e acompanhamento de medições de glicose.',
                          ),
                          const SizedBox(height: 16),
                          _buildDisclaimerParagraph(
                            'Ele não substitui avaliação médica, diagnóstico, '
                            'tratamento ou acompanhamento profissional.',
                          ),
                          const SizedBox(height: 16),
                          _buildDisclaimerParagraph(
                            'As informações apresentadas não devem ser usadas para '
                            'tomar decisões médicas, ajustar medicamentos, doses de '
                            'insulina ou alterar tratamentos sem orientação de um '
                            'profissional de saúde.',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _warningOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _warningOrange.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.emergency_outlined,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Em caso de sintomas, dúvidas ou valores fora do esperado, '
                                    'procure seu médico ou um serviço de saúde imediatamente.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
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
                
                const Spacer(flex: 1),
                
                // CTA Button - Prominent orange styling
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warningOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: _warningOrange.withOpacity(0.5),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AppShell(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'ENTENDI E DESEJO CONTINUAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
