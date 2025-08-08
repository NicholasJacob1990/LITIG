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
  final bool autoStart;

  const ChatTriageScreen({super.key, this.autoStart = false});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: ChatTriageScreen sendo carregada');
    return BlocProvider(
      create: (context) => ChatTriageBloc(),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String userName = 'Usuário';
          if (authState is Authenticated) {
            userName = authState.user.fullName ?? 'Usuário';
          }

          // Auto start para clientes ou quando explicitamente solicitado via rota (?auto=1)
          final isClient = authState is Authenticated && (authState.user.role == 'client' || authState.user.role == 'client_pf');
          if (autoStart || isClient) {
            // Dispara start após o primeiro frame para evitar setState durante build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final bloc = context.read<ChatTriageBloc>();
              if (bloc.state is ChatTriageInitial) {
                bloc.add(StartConversation());
              }
            });
          }
          
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Busca de Parcerias'),
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
                if (state is ChatTriageFinished) {
                  _showTriageCompletedNotification(context, state.caseId);
                  context.go('/advogados?case_highlight=${state.caseId}');
                } else if (state is ChatTriageError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                // Tela inicial de apresentação
                if (state is ChatTriageInitial && !(autoStart || isClient)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bot, size: 64, color: Color(0xFF1E40AF)),
                        const SizedBox(height: 24),
                        Text(
                          'Encontre Parcerias com Inteligência Artificial',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Descreva o tipo de parceria que você busca e nossa IA encontrará os melhores parceiros para seus casos.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.messageCircle),
                          label: const Text('Iniciar Busca de Parcerias'),
                          onPressed: () {
                            print('DEBUG: Botão Iniciar Consulta pressionado');
                            // Iniciar o chat de triagem no BLoC existente
                            final bloc = context.read<ChatTriageBloc>();
                            print('DEBUG: BLoC obtido: $bloc');
                            bloc.add(StartConversation());
                            print('DEBUG: Evento StartConversation adicionado');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Loading da inicialização
                if (state is ChatTriageLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Iniciando conversa com IA...'),
                      ],
                    ),
                  );
                }
                
                // Chat ativo
                if (state is ChatTriageActive) {
                  return _buildChatView(state);
                }
                
                // Estado de erro
                if (state is ChatTriageError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erro: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ChatTriageBloc>().add(StartConversation()),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }
                
                // Triagem finalizada
                if (state is ChatTriageFinished) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.checkCircle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text('Triagem concluída com sucesso!'),
                      ],
                    ),
                  );
                }
                
                // Fallback
                return const Center(
                  child: Text('Estado desconhecido'),
                );
              },
            ),
          );
        },
      ),
    );
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

  Widget _buildChatView(ChatTriageActive state) {
    return ChatTriageView(
      messages: state.messages,
      isTyping: state.isTyping,
    );
  }
}

class ChatTriageView extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  
  const ChatTriageView({
    super.key,
    required this.messages,
    this.isTyping = false,
  });

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

  @override
  void initState() {
    super.initState();
    // Auto-scroll quando há mensagens iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(ChatTriageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll quando recebe novas mensagens
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
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
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
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
                if (widget.isTyping)
                  Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        SizedBox(width: 16),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('IA está digitando...', style: TextStyle(color: Colors.grey)),
                      ],
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
                          enabled: !widget.isTyping,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.send),
                        onPressed: widget.isTyping ? null : _sendMessage,
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