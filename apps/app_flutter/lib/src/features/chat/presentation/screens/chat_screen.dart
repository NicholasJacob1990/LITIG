import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';
import '../../../../injection_container.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String? otherPartyName;

  const ChatScreen({
    super.key,
    required this.roomId,
    this.otherPartyName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    _chatBloc.add(ConnectToRoom(widget.roomId));
    _chatBloc.add(LoadChatMessages(roomId: widget.roomId));

    // Listen for scroll to load more messages
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 
          _scrollController.position.maxScrollExtent) {
        final currentState = _chatBloc.state;
        if (currentState is ChatMessagesLoaded && currentState.hasMore) {
          _chatBloc.add(LoadChatMessages(
            roomId: widget.roomId,
            offset: currentState.messages.length,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _chatBloc.add(DisconnectFromRoom(widget.roomId));
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String content) {
    _chatBloc.add(SendChatMessage(
      roomId: widget.roomId,
      content: content,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.otherPartyName ?? 'Chat'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              onPressed: () {
                // TODO: Implement chat settings/info
              },
              icon: const Icon(LucideIcons.info),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (state is ChatError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar mensagens',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _chatBloc.add(LoadChatMessages(roomId: widget.roomId));
                            },
                            icon: const Icon(LucideIcons.refreshCw),
                            label: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is ChatMessagesLoaded && state.roomId == widget.roomId) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Envie uma mensagem para começar a conversa',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          // Loading indicator for more messages
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final message = state.messages[index];
                        return ChatMessageBubble(
                          message: message,
                          onTap: () {
                            // Mark message as read if it's from the other party
                            if (!message.isRead && !message.isFromCurrentUser) {
                              _chatBloc.add(MarkMessageAsRead(
                                roomId: widget.roomId,
                                messageId: message.id,
                              ));
                            }
                          },
                        );
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
            ChatInput(
              onSendMessage: _sendMessage,
              enabled: true, // TODO: Check if chat is active
            ),
          ],
        ),
      ),
    );
  }
}