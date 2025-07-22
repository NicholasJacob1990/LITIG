import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMessageCard(
            context,
            'Dr. João Silva',
            'Advogado Civil',
            'Olá! Analisei seu caso e tenho algumas perguntas...',
            '2 min atrás',
            true,
          ),
          _buildMessageCard(
            context,
            'Dra. Maria Santos',
            'Advogada Trabalhista',
            'Seu processo foi protocolado com sucesso.',
            '1 hora atrás',
            false,
          ),
          _buildMessageCard(
            context,
            'Dr. Carlos Oliveira',
            'Advogado Criminal',
            'Preciso de mais informações sobre o incidente.',
            'Ontem',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context,
    String name,
    String specialty,
    String message,
    String time,
    bool isUnread,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
          child: Text(
            name.substring(0, 2).toUpperCase(),
            style: TextStyle(
              color: isUnread ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              specialty,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          time,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        onTap: () {
          // TODO: Navegar para chat individual
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat com $name em desenvolvimento')),
          );
        },
      ),
    );
  }
} 