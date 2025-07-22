import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nossos Serviços'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ServiceCard(
            icon: LucideIcons.messageCircle,
            title: 'Mensagens',
            description: 'Comunique-se diretamente com advogados e acompanhe conversas.',
            route: '/client-messages',
          ),
          ServiceCard(
            icon: LucideIcons.search,
            title: 'Buscar Advogados',
            description: 'Encontre advogados especialistas por área e localização.',
            route: '/find-lawyers',
          ),
           ServiceCard(
            icon: LucideIcons.clipboardList,
            title: 'Meus Casos',
            description: 'Acompanhe o andamento de todos os seus casos em um só lugar.',
            route: '/client-cases',
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(description),
        onTap: () {
          if (route.isNotEmpty) {
            context.go(route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Em breve: $title')),
            );
          }
        },
      ),
    );
  }
} 