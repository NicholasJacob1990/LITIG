import 'package:flutter/material.dart';

class ClientMessagesScreen extends StatelessWidget {
  const ClientMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Conversas')),
      body: const Center(
        child: Text('Aqui ficará a lista de conversas do cliente com os advogados.'),
      ),
    );
  }
} 