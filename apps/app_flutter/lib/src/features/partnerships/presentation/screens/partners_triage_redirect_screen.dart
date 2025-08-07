import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tela de redirecionamento que leva o usuário diretamente para o chat de triagem
/// quando ele acessa a aba "Parceiros" para buscar parcerias
class PartnersTriageRedirectScreen extends StatefulWidget {
  const PartnersTriageRedirectScreen({super.key});

  @override
  State<PartnersTriageRedirectScreen> createState() => _PartnersTriageRedirectScreenState();
}

class _PartnersTriageRedirectScreenState extends State<PartnersTriageRedirectScreen> {
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    // Redirecionar automaticamente após um breve delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToTriage();
    });
  }

  void _redirectToTriage() {
    setState(() {
      _isRedirecting = true;
    });

    // Pequeno delay para mostrar a tela de loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.go('/triage');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Advogado';
        if (authState is Authenticated) {
          userName = authState.user.fullName ?? 'Advogado';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Buscar Parcerias'),
            centerTitle: true,
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de IA
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.bot,
                    size: 64,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título
                Text(
                  'Encontre Parcerias com IA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Descrição
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Olá $userName! Use nossa inteligência artificial para encontrar os melhores parceiros para seus casos.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Indicador de carregamento
                if (_isRedirecting) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iniciando chat de triagem...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  // Botão manual (fallback)
                  ElevatedButton.icon(
                    onPressed: _redirectToTriage,
                    icon: const Icon(LucideIcons.messageCircle),
                    label: const Text('Iniciar Busca com IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Informações adicionais
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.zap, size: 16, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Análise Rápida',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.target, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Matches Precisos',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.shield, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Parceiros Verificados',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


