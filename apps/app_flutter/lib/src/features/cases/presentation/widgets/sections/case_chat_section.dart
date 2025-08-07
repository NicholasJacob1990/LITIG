import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../../chat/presentation/widgets/chat_input.dart';
import '../../../../chat/presentation/widgets/chat_message_bubble.dart';
import '../../../../../../injection_container.dart';

class CaseChatSection extends StatefulWidget {
  final String caseId;
  final String caseName;
  final String? lawyerName;
  final String? clientName;
  
  const CaseChatSection({
    super.key,
    required this.caseId,
    required this.caseName,
    this.lawyerName,
    this.clientName,
  });

  @override
  State<CaseChatSection> createState() => _CaseChatSectionState();
}

class _CaseChatSectionState extends State<CaseChatSection> {
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    // Use case ID as room ID for case-specific chat
    final roomId = 'case_${widget.caseId}';
    _chatBloc.add(ConnectToRoom(roomId));
    _chatBloc.add(LoadChatMessages(roomId: roomId));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 
          _scrollController.position.maxScrollExtent) {
        final currentState = _chatBloc.state;
        if (currentState is ChatMessagesLoaded && currentState.hasMore) {
          _chatBloc.add(LoadChatMessages(
            roomId: roomId,
            offset: currentState.messages.length,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            if (_isExpanded) _buildChatContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              LucideIcons.messageSquare,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat do Caso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Converse com ${_getOtherPartyName()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is ChatMessagesLoaded) {
                  // Since we don't have isMine property, we'll use a different approach
                  // In a real implementation, you'd compare senderId with current user ID
                  unreadCount = state.messages.where((m) => !m.isRead).length;
                }
                
                return Row(
                  children: [
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      color: Colors.grey[600],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is ChatError) {
                  return _buildErrorState(context, state.message);
                }
                
                if (state is ChatMessagesLoaded) {
                  return _buildMessagesList(context, state);
                }
                
                return _buildEmptyState(context);
              },
            ),
          ),
          _buildChatInput(context),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatMessagesLoaded state) {
    if (state.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: state.messages.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final message = state.messages[index];
        return ChatMessageBubble(
          message: message,
          onTap: () {
            // Handle message tap (e.g., show options, reply, etc.)
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicie uma conversa sobre este caso',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final roomId = 'case_${widget.caseId}';
              _chatBloc.add(LoadChatMessages(roomId: roomId));
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ChatInput(
        onSendMessage: (message) {
          final roomId = 'case_${widget.caseId}';
          _chatBloc.add(SendChatMessage(
            roomId: roomId,
            content: message,
          ));
        },
      ),
    );
  }

  String _getOtherPartyName() {
    // Logic to determine who is the other party in the conversation
    // This would typically be determined by the current user's role
    if (widget.lawyerName != null && widget.clientName != null) {
      // Return the appropriate name based on current user role
      // This is a simplified logic - in reality, you'd check current user
      return 'advogado e cliente';
    } else if (widget.lawyerName != null) {
      return widget.lawyerName!;
    } else if (widget.clientName != null) {
      return widget.clientName!;
    } else {
      return 'participantes do caso';
    }
  }
}

class CaseChatQuickActionButton extends StatelessWidget {
  final String caseId;
  final VoidCallback onPressed;

  const CaseChatQuickActionButton({
    super.key,
    required this.caseId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      onPressed: onPressed,
      heroTag: 'case_chat_$caseId',
      child: const Icon(LucideIcons.messageSquare),
    );
  }
}