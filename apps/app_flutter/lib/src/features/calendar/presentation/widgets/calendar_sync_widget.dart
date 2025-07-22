import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import '../screens/client_agenda_screen.dart';

/// Widget para sincronização com calendários externos
class CalendarSyncWidget extends StatelessWidget {
  final CalendarProvider provider;
  final bool isConnected;
  final bool isLoading;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const CalendarSyncWidget({
    super.key,
    required this.provider,
    required this.isConnected,
    required this.isLoading,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getProviderConfig(provider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected 
            ? config.color.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected 
              ? config.color.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              config.icon,
              color: config.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected
                      ? 'Conectado e sincronizando'
                      : 'Não conectado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isConnected 
                        ? config.color
                        : theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Última sincronização: agora',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isConnected)
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.refreshCw,
                    color: config.color,
                    size: 20,
                  ),
                  onPressed: onConnect,
                  tooltip: 'Sincronizar agora',
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.unlink,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: () => _showDisconnectDialog(context),
                  tooltip: 'Desconectar',
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: isLoading ? null : onConnect,
              icon: Icon(config.icon, size: 16),
              label: const Text('Conectar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    final config = _getProviderConfig(provider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desconectar ${config.name}'),
        content: Text(
          'Tem certeza que deseja desconectar do ${config.name}? '
          'Os eventos não serão mais sincronizados automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDisconnect();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  ProviderConfig _getProviderConfig(CalendarProvider provider) {
    switch (provider) {
      case CalendarProvider.google:
        return const ProviderConfig(
          name: 'Google Calendar',
          icon: LucideIcons.calendar,
          color: Color(0xFF4285F4), // Google Blue
        );
      case CalendarProvider.outlook:
        return const ProviderConfig(
          name: 'Microsoft Outlook',
          icon: LucideIcons.mail,
          color: Color(0xFF0078D4), // Microsoft Blue
        );
    }
  }
}

class ProviderConfig {
  final String name;
  final IconData icon;
  final Color color;

  const ProviderConfig({
    required this.name,
    required this.icon,
    required this.color,
  });
}