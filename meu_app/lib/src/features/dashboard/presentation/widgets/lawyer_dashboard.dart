import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/dashboard/presentation/widgets/stat_card.dart';

class LawyerDashboard extends StatelessWidget {
  final String userName;

  const LawyerDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, $userName'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              // TODO: Implementar logout
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(child: StatCard(title: 'Casos Ativos', value: '12', icon: LucideIcons.briefcase, color: Colors.blue)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Novos Leads', value: '3', icon: LucideIcons.userPlus, color: Colors.green)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Alertas', value: '1', icon: LucideIcons.bell, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Ações Rápidas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(context, 'Meus Casos', LucideIcons.briefcase, '/cases'),
                _buildActionCard(context, 'Mensagens', LucideIcons.messageCircle, '/messages'),
                _buildActionCard(context, 'Agenda', LucideIcons.calendar, '/schedule'),
                _buildActionCard(context, 'Notificações', LucideIcons.bell, '/notifications'), // Rota a ser criada
              ],
            ),
             const SizedBox(height: 24),
            Text('Acesso Rápido', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.edit),
              title: const Text('Editar Perfil Público'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profile/edit'), // Rota a ser criada
            ),
            ListTile(
              leading: const Icon(LucideIcons.barChart),
              title: const Text('Análise de Performance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profile/performance'), // Rota a ser criada
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
} 