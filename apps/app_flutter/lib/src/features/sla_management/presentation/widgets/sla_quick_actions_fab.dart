import 'package:flutter/material.dart';

class SlaQuickActionsFab extends StatelessWidget {
  final int currentTab;
  final Function(String) onQuickAction;
  final bool isLoaded;

  const SlaQuickActionsFab({
    super.key,
    required this.currentTab,
    required this.onQuickAction,
    required this.isLoaded,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const SizedBox.shrink();
    }

    final actions = _getActionsForTab(currentTab);
    
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actions.length == 1) {
      return FloatingActionButton(
        onPressed: () => onQuickAction(actions.first.action),
        tooltip: actions.first.tooltip,
        child: Icon(actions.first.icon),
      );
    }

    return FloatingActionButton(
      onPressed: () => _showQuickActionsMenu(context, actions),
      tooltip: 'Ações Rápidas',
      child: const Icon(Icons.speed),
    );
  }

  List<QuickAction> _getActionsForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // Configurações
        return [
          const QuickAction(
            action: 'save',
            icon: Icons.save,
            label: 'Salvar',
            tooltip: 'Salvar configurações',
          ),
          const QuickAction(
            action: 'validate',
            icon: Icons.check_circle,
            label: 'Validar',
            tooltip: 'Validar configurações',
          ),
        ];
      case 1: // Presets
        return [
          const QuickAction(
            action: 'preset',
            icon: Icons.bookmark_add,
            label: 'Novo Preset',
            tooltip: 'Criar novo preset',
          ),
        ];
      case 2: // Regras de Negócio
        return [
          const QuickAction(
            action: 'test',
            icon: Icons.play_arrow,
            label: 'Testar',
            tooltip: 'Testar regras',
          ),
        ];
      case 3: // Notificações
        return [
          const QuickAction(
            action: 'test',
            icon: Icons.notifications_active,
            label: 'Testar',
            tooltip: 'Testar notificações',
          ),
        ];
      case 4: // Escalações
        return [
          const QuickAction(
            action: 'test',
            icon: Icons.trending_up,
            label: 'Testar',
            tooltip: 'Testar escalações',
          ),
        ];
      case 5: // Analytics
        return [
          const QuickAction(
            action: 'export',
            icon: Icons.download,
            label: 'Exportar',
            tooltip: 'Exportar relatório',
          ),
        ];
      case 6: // Auditoria
        return [
          const QuickAction(
            action: 'backup',
            icon: Icons.backup,
            label: 'Backup',
            tooltip: 'Criar backup',
          ),
        ];
      default:
        return [];
    }
  }

  void _showQuickActionsMenu(BuildContext context, List<QuickAction> actions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...actions.map((action) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      action.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(action.label),
                  subtitle: Text(action.tooltip),
                  onTap: () {
                    Navigator.of(context).pop();
                    onQuickAction(action.action);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  final String action;
  final IconData icon;
  final String label;
  final String tooltip;

  const QuickAction({
    required this.action,
    required this.icon,
    required this.label,
    required this.tooltip,
  });
} 