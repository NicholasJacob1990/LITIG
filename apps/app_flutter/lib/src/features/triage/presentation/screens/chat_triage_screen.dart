import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_bloc.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_event.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_state.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';

class ChatTriageScreen extends StatelessWidget {
  const ChatTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: ChatTriageScreen sendo carregada');
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Usuário';
        if (authState is Authenticated) {
          userName = authState.user.fullName ?? 'Usuário';
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Triagem Inteligente'),
                Text(
                  'Olá, $userName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.logOut),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/login');
                },
                tooltip: 'Sair',
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.bot, size: 64, color: Color(0xFF1E40AF)),
                const SizedBox(height: 24),
                Text(
                  'Seu Problema Jurídico, Resolvido com Inteligência',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Use nossa IA para uma pré-análise gratuita e seja conectado ao advogado certo para o seu caso.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.playCircle),
                  label: const Text('Iniciar Consulta com IA'),
                  onPressed: () => context.go('/triage'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

class ChatTriageView extends StatefulWidget {
  const ChatTriageView({super.key});

  @override
  State<ChatTriageView> createState() => _ChatTriageViewState();
}

class _ChatTriageViewState extends State<ChatTriageView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<ChatTriageBloc>().add(SendMessage(_controller.text.trim()));
      _controller.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTriageCompletedNotification(BuildContext context, String caseId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Triagem concluída! Encontramos advogados para seu caso.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        action: SnackBarAction(
          label: 'Ver Recomendações',
          textColor: Colors.white,
          onPressed: () => context.go('/advogados?tab=recomendacoes&case_id=$caseId'),
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Usuário';
        if (authState is Authenticated) {
          userName = authState.user.fullName ?? 'Usuário';
        }
        
    return Scaffold(
      appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Triagem Inteligente'),
                Text(
                  'Olá, $userName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.logOut),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/login');
                },
                tooltip: 'Sair',
              ),
            ],
      ),
      body: BlocConsumer<ChatTriageBloc, ChatTriageState>(
        listener: (context, state) {
          if (state is ChatTriageActive) {
            _scrollToBottom();
          } else if (state is ChatTriageFinished) {
            _showTriageCompletedNotification(context, state.caseId);
            context.go('/advogados?case_highlight=${state.caseId}');
          } else if (state is ChatTriageError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatTriageInitial || state is ChatTriageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatTriageActive) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                          final isUser = message.isUser;
                          
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
      ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Descreva seu problema jurídico...',
                                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
                    ),
                  ],
    );
  }

              return const Center(
                child: Text('Erro ao carregar triagem'),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 