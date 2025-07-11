import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_bloc.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_event.dart';
import 'package:meu_app/src/features/triage/presentation/bloc/chat_triage_state.dart';

class ChatTriageScreen extends StatelessWidget {
  const ChatTriageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatTriageBloc()..add(StartConversation()),
      child: const ChatTriageView(),
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
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triagem Inteligente'),
        centerTitle: true,
      ),
      body: BlocConsumer<ChatTriageBloc, ChatTriageState>(
        listener: (context, state) {
          if (state is ChatTriageActive) {
            _scrollToBottom();
          } else if (state is ChatTriageFinished) {
            context.go('/matches/${state.caseId}');
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
                    padding: const EdgeInsets.all(8.0),
                    itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isTyping && index == state.messages.length) {
                        return const MessageBubble(message: ChatMessage(text: '...', isUser: false), isTyping: true);
                      }
                      final message = state.messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            );
          }
          
          return const Center(child: Text('Inicie a conversa.'));
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isTyping;

  const MessageBubble({super.key, required this.message, this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser ? Theme.of(context).primaryColor : Colors.grey[300];
    final textColor = message.isUser ? Colors.white : Colors.black;

    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isTyping 
          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black),))
          : Text(
          message.text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
} 