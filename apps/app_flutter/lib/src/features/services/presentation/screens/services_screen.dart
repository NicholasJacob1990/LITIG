import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/instrumented_widgets.dart';

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
  // Novos parâmetros para instrumentação
  final String? sourceContext;
  final double? listRank;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    this.sourceContext,
    this.listRank,
  });

  @override
  Widget build(BuildContext context) {
    return InstrumentedContentCard(
      contentId: route.isNotEmpty ? route : title.toLowerCase().replaceAll(' ', '_'),
      contentType: 'service',
      sourceContext: sourceContext ?? 'services_screen',
      listRank: listRank,
      onTap: () {
        if (route.isNotEmpty) {
          context.go(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Em breve: $title')),
          );
        }
      },
      additionalData: {
        'service_title': title,
        'service_description': description,
        'target_route': route,
        'is_available': route.isNotEmpty,
        'action_type': route.isNotEmpty ? 'navigate' : 'show_coming_soon',
      },
      child: Card(
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
      ),
    );
  }
} 