import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_room_card.dart';
import 'package:meu_app/injection_container.dart';

class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()..add(LoadChatRooms()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conversas'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              onPressed: () {
                context.read<ChatBloc>().add(LoadChatRooms());
              },
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
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
                      'Erro ao carregar conversas',
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
                        context.read<ChatBloc>().add(LoadChatRooms());
                      },
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is ChatRoomsLoaded) {
              if (state.rooms.isEmpty) {
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
                        'Nenhuma conversa encontrada',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suas conversas aparecerão aqui quando você\ncontratar ou for contratado por alguém',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ChatBloc>().add(LoadChatRooms());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    return ChatRoomCard(
                      room: room,
                      onTap: () {
                        context.push('/chat/${room.id}');
                      },
                    );
                  },
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}