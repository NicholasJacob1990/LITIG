import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.bell),
            title: const Text('Notificações'),
            subtitle: const Text('Gerencie suas preferências de notificação'),
            onTap: () {
              // Navegar para a tela de configurações de notificação
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.shield),
            title: const Text('Privacidade e Segurança'),
            subtitle: const Text('Ajuste suas configurações de privacidade'),
            onTap: () {
              // Navegar para a tela de privacidade
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.helpCircle),
            title: const Text('Ajuda e Suporte'),
            subtitle: const Text('Encontre ajuda ou entre em contato conosco'),
            onTap: () {
              // Abrir link de suporte
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(LucideIcons.logOut, color: Colors.red.shade700),
            title: Text('Sair', style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              // Lógica de logout
            },
          ),
        ],
      ),
    );
  }
} 