import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_event.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_state.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Tela de Configurações Administrativas
/// 
/// Permite configurar parâmetros do sistema e configurações administrativas
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = true;
  bool _auditLoggingEnabled = true;
  bool _maintenanceMode = false;
  
  String _backupFrequency = 'Diário';
  String _logRetention = '30 dias';
  String _sessionTimeout = '8 horas';
  
  final List<String> _backupFrequencies = ['Diário', 'Semanal', 'Mensal'];
  final List<String> _logRetentions = ['7 dias', '30 dias', '90 dias', '1 ano'];
  final List<String> _sessionTimeouts = ['4 horas', '8 horas', '12 horas', '24 horas'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save),
            onPressed: () => _saveSettings(context),
            tooltip: 'Salvar configurações',
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminError) {
            return _buildErrorState(context, state.message);
          }

          if (state is AdminSettingsUpdated) {
            return _buildSuccessState(context);
          }

          return _buildSettingsContent(context);
        },
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          
          const SizedBox(height: 24),
          
          // Configurações de Notificações
          _buildNotificationsSection(context),
          
          const SizedBox(height: 24),
          
          // Configurações de Backup
          _buildBackupSection(context),
          
          const SizedBox(height: 24),
          
          // Configurações de Segurança
          _buildSecuritySection(context),
          
          const SizedBox(height: 24),
          
          // Configurações de Sistema
          _buildSystemSection(context),
          
          const SizedBox(height: 24),
          
          // Ações de Manutenção
          _buildMaintenanceSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.settings,
            size: 32,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações do Sistema',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure parâmetros administrativos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      'Notificações',
      LucideIcons.bell,
      Colors.blue,
      [
        SwitchListTile(
          title: const Text('Notificações Administrativas'),
          subtitle: const Text('Receber alertas sobre eventos críticos'),
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
          secondary: const Icon(LucideIcons.bell),
        ),
        ListTile(
          title: const Text('Configurar Alertas'),
          subtitle: const Text('Definir tipos de notificação'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showNotificationSettings(context),
        ),
      ],
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      'Backup e Recuperação',
      LucideIcons.database,
      Colors.green,
      [
        SwitchListTile(
          title: const Text('Backup Automático'),
          subtitle: const Text('Realizar backup automático dos dados'),
          value: _autoBackupEnabled,
          onChanged: (value) => setState(() => _autoBackupEnabled = value),
          secondary: const Icon(LucideIcons.database),
        ),
        ListTile(
          title: const Text('Frequência de Backup'),
          subtitle: Text(_backupFrequency),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showBackupSettings(context),
        ),
        ListTile(
          title: const Text('Retenção de Logs'),
          subtitle: Text(_logRetention),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showLogRetentionSettings(context),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return _buildSettingsSection(
      context,
      'Segurança',
      LucideIcons.shield,
      Colors.red,
      [
        SwitchListTile(
          title: const Text('Logs de Auditoria'),
          subtitle: const Text('Registrar todas as atividades administrativas'),
          value: _auditLoggingEnabled,
          onChanged: (value) => setState(() => _auditLoggingEnabled = value),
          secondary: const Icon(LucideIcons.shield),
        ),
        ListTile(
          title: const Text('Timeout de Sessão'),
          subtitle: Text(_sessionTimeout),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showSessionTimeoutSettings(context),
        ),
        ListTile(
          title: const Text('Políticas de Senha'),
          subtitle: const Text('Configurar requisitos de senha'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showPasswordPolicySettings(context),
        ),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      'Sistema',
      LucideIcons.server,
      Colors.orange,
      [
        ListTile(
          title: const Text('Informações do Sistema'),
          subtitle: const Text('Versão, recursos e status'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showSystemInfo(context),
        ),
        ListTile(
          title: const Text('Configurações de API'),
          subtitle: const Text('Endpoints e autenticação'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showApiSettings(context),
        ),
        ListTile(
          title: const Text('Configurações de Banco'),
          subtitle: const Text('Conexões e performance'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _showDatabaseSettings(context),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      'Manutenção',
      LucideIcons.wrench,
      Colors.purple,
      [
        SwitchListTile(
          title: const Text('Modo Manutenção'),
          subtitle: const Text('Ativar modo de manutenção do sistema'),
          value: _maintenanceMode,
          onChanged: (value) => setState(() => _maintenanceMode = value),
          secondary: const Icon(LucideIcons.wrench),
        ),
        ListTile(
          title: const Text('Limpeza de Cache'),
          subtitle: const Text('Limpar cache do sistema'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _clearCache(context),
        ),
        ListTile(
          title: const Text('Otimização de Banco'),
          subtitle: const Text('Otimizar tabelas e índices'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _optimizeDatabase(context),
        ),
        ListTile(
          title: const Text('Backup Manual'),
          subtitle: const Text('Executar backup manual agora'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => _manualBackup(context),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações de Notificação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Alertas de Segurança'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Relatórios Diários'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Alertas de Performance'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showBackupSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequência de Backup'),
        content: DropdownButtonFormField<String>(
          value: _backupFrequency,
          decoration: const InputDecoration(
            labelText: 'Frequência',
            border: OutlineInputBorder(),
          ),
          items: _backupFrequencies.map((frequency) => DropdownMenuItem(
            value: frequency,
            child: Text(frequency),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _backupFrequency = value!;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showLogRetentionSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retenção de Logs'),
        content: DropdownButtonFormField<String>(
          value: _logRetention,
          decoration: const InputDecoration(
            labelText: 'Período de Retenção',
            border: OutlineInputBorder(),
          ),
          items: _logRetentions.map((retention) => DropdownMenuItem(
            value: retention,
            child: Text(retention),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _logRetention = value!;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showSessionTimeoutSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timeout de Sessão'),
        content: DropdownButtonFormField<String>(
          value: _sessionTimeout,
          decoration: const InputDecoration(
            labelText: 'Tempo de Sessão',
            border: OutlineInputBorder(),
          ),
          items: _sessionTimeouts.map((timeout) => DropdownMenuItem(
            value: timeout,
            child: Text(timeout),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _sessionTimeout = value!;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showPasswordPolicySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Políticas de Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Mínimo 8 caracteres'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Incluir números'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Incluir caracteres especiais'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Não reutilizar senhas'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Sistema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Versão', '1.0.0'),
            _buildInfoRow('Build', '2025.01.19'),
            _buildInfoRow('Plataforma', 'Flutter Web'),
            _buildInfoRow('Banco de Dados', 'PostgreSQL 14'),
            _buildInfoRow('API', 'FastAPI 0.104.1'),
            _buildInfoRow('Status', 'Online'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showApiSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de API em desenvolvimento'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showDatabaseSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações de banco em desenvolvimento'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _clearCache(BuildContext context) {
    context.read<AdminBloc>().add(UpdateAdminSettings());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache limpo com sucesso'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _optimizeDatabase(BuildContext context) {
    context.read<AdminBloc>().add(UpdateAdminSettings());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Otimização de banco iniciada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _manualBackup(BuildContext context) {
    context.read<AdminBloc>().add(UpdateAdminSettings());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup manual iniciado'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    context.read<AdminBloc>().add(UpdateAdminSettings());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 64,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Configurações Atualizadas!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'As alterações foram aplicadas com sucesso',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar configurações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<AdminBloc>().add(LoadAdminDashboard()),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
} 