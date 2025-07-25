import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/core/services/social_auth_service.dart';

/// Widget para gestão de redes sociais no perfil
/// Suporta todos os tipos de usuário: client, lawyer_*, admin
class SocialMediaManagementWidget extends StatefulWidget {
  final String? userRole;
  
  const SocialMediaManagementWidget({
    super.key,
    this.userRole,
  });

  @override
  State<SocialMediaManagementWidget> createState() => _SocialMediaManagementWidgetState();
}

class _SocialMediaManagementWidgetState extends State<SocialMediaManagementWidget> {
  final SocialAuthService _socialAuthService = SocialAuthService();
  List<Map<String, dynamic>> _connectedAccounts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  Future<void> _loadConnectedAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accounts = await _socialAuthService.getConnectedAccounts();
      setState(() {
        _connectedAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.share2,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redes Sociais & Comunicação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getRoleSpecificSubtitle(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadConnectedAccounts,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }

  String _getRoleSpecificSubtitle() {
    final role = widget.userRole ?? '';
    
    if (role.contains('lawyer') || role == 'PJ') {
      return 'Comunicação profissional completa: LinkedIn + Email + Messaging';
    } else if (role == 'client' || role == 'PF') {
      return 'Conecte suas contas para comunicação unificada';
    } else if (role.contains('admin')) {
      return 'Configurações avançadas de comunicação';
    }
    
    return 'Integre suas contas de comunicação';
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    return Column(
      children: [
        _buildConnectedAccounts(context),
        const Divider(height: 1),
        _buildAvailableConnections(context),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Carregando contas...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar contas',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadConnectedAccounts,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedAccounts(BuildContext context) {
    if (_connectedAccounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
                      Icon(
            LucideIcons.link,
            color: AppColors.textSecondary,
            size: 48,
          ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma conta conectada',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Conecte suas contas para unificar comunicações',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Contas Conectadas (${_connectedAccounts.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ..._connectedAccounts.map((account) => _buildAccountItem(context, account)),
      ],
    );
  }

  Widget _buildAccountItem(BuildContext context, Map<String, dynamic> account) {
    final platform = account['provider'] as String? ?? 'unknown';
    final accountEmail = account['email'] as String? ?? account['username'] as String? ?? 'Sem identificação';
    final isActive = account['is_active'] as bool? ?? true;
    final connectedAt = account['connected_at'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPlatformColor(platform).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPlatformIcon(platform),
              color: _getPlatformColor(platform),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getPlatformName(platform),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'Ativa' : 'Inativa',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  accountEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (connectedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Conectada em ${_formatDate(connectedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.moreVertical,
              size: 16,
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
            onSelected: (value) => _handleAccountAction(context, account, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: ListTile(
                  leading: Icon(LucideIcons.refreshCw, size: 16),
                  title: Text('Sincronizar'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'disconnect',
                child: ListTile(
                  leading: Icon(LucideIcons.unlink, size: 16, color: Colors.red),
                  title: Text('Desconectar', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableConnections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Conectar Nova Conta',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildConnectionOption(
          context,
          platform: 'gmail',
          title: 'Gmail',
          subtitle: 'Sincronizar emails e calendário',
          icon: LucideIcons.mail,
          color: Colors.red,
          onTap: () => _connectEmail(context, 'gmail'),
        ),
        _buildConnectionOption(
          context,
          platform: 'outlook',
          title: 'Outlook',
          subtitle: 'Emails e calendário corporativo',
          icon: LucideIcons.mail,
          color: Colors.blue,
          onTap: () => _connectEmail(context, 'outlook'),
        ),
        if (_shouldShowLinkedIn()) ...[
          _buildConnectionOption(
            context,
            platform: 'linkedin',
            title: 'LinkedIn',
            subtitle: 'Networking profissional',
            icon: LucideIcons.linkedin,
            color: const Color(0xFF0077B5),
            onTap: () => _connectLinkedIn(context),
          ),
        ],
        if (_shouldShowSocialPlatforms()) ...[
          _buildConnectionOption(
            context,
            platform: 'whatsapp',
            title: 'WhatsApp',
            subtitle: 'Mensagens instantâneas',
            icon: LucideIcons.messageCircle,
            color: Colors.green,
            onTap: () => _connectWhatsApp(context),
          ),
          _buildConnectionOption(
            context,
            platform: 'instagram',
            title: 'Instagram',
            subtitle: 'Mensagens diretas',
            icon: LucideIcons.instagram,
            color: const Color(0xFFE4405F),
            onTap: () => _connectInstagram(context),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConnectionOption(
    BuildContext context, {
    required String platform,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isConnected = _connectedAccounts.any((account) => account['provider'] == platform);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isConnected
          ? Icon(
              LucideIcons.check,
              color: Colors.green,
              size: 16,
            )
          : Icon(
              LucideIcons.plus,
              color: AppColors.primary,
              size: 16,
            ),
      onTap: isConnected ? null : onTap,
      enabled: !isConnected,
    );
  }

  bool _shouldShowLinkedIn() {
    final role = widget.userRole ?? '';
    // Cliente PJ e todos advogados/escritórios têm acesso ao LinkedIn
    return role.contains('lawyer') || role == 'PJ';
  }

  bool _shouldShowSocialPlatforms() {
    final role = widget.userRole ?? '';
    // Todos os usuários têm acesso a WhatsApp/Instagram
    return true;
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'gmail':
      case 'outlook':
        return LucideIcons.mail;
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'whatsapp':
        return LucideIcons.messageCircle;
      case 'instagram':
        return LucideIcons.instagram;
      case 'facebook':
        return LucideIcons.facebook;
      case 'telegram':
        return LucideIcons.send;
      default:
        return LucideIcons.link;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'gmail':
        return Colors.red;
      case 'outlook':
        return Colors.blue;
      case 'linkedin':
        return const Color(0xFF0077B5);
      case 'whatsapp':
        return Colors.green;
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'telegram':
        return const Color(0xFF0088CC);
      default:
        return AppColors.primary;
    }
  }

  String _getPlatformName(String platform) {
    switch (platform.toLowerCase()) {
      case 'gmail':
        return 'Gmail';
      case 'outlook':
        return 'Outlook';
      case 'linkedin':
        return 'LinkedIn';
      case 'whatsapp':
        return 'WhatsApp';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'telegram':
        return 'Telegram';
      default:
        return platform.toUpperCase();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  void _handleAccountAction(BuildContext context, Map<String, dynamic> account, String action) {
    switch (action) {
      case 'sync':
        _syncAccount(context, account);
        break;
      case 'disconnect':
        _disconnectAccount(context, account);
        break;
    }
  }

  Future<void> _syncAccount(BuildContext context, Map<String, dynamic> account) async {
    // TODO: Implementar sincronização específica da conta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sincronizando ${account['provider']}...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _disconnectAccount(BuildContext context, Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Conta'),
        content: Text('Tem certeza que deseja desconectar ${account['provider']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _socialAuthService.disconnectAccount(account['account_id']);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta desconectada com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
          _loadConnectedAccounts();
        } else {
          throw Exception('Falha ao desconectar');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desconectar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectEmail(BuildContext context, String provider) async {
    final emailController = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conectar $provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Digite seu email $provider:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                suffixText: provider == 'gmail' ? '@gmail.com' : '@outlook.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, emailController.text),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty) {
      try {
        final result = await _socialAuthService.connectEmail(
          email: email,
          provider: provider,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$provider conectado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadConnectedAccounts();
        } else {
          throw Exception(result['error'] ?? 'Falha na conexão');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar $provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectLinkedIn(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar LinkedIn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'email': emailController.text,
              'password': passwordController.text,
            }),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (credentials != null) {
      try {
        final result = await _socialAuthService.connectLinkedIn(
          email: credentials['email']!,
          password: credentials['password']!,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LinkedIn conectado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadConnectedAccounts();
        } else {
          throw Exception(result['error'] ?? 'Falha na conexão');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar LinkedIn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectWhatsApp(BuildContext context) async {
    try {
      final result = await _socialAuthService.connectWhatsApp();

      if (result['success'] == true) {
        final qrCode = result['qr_code'] as String?;
        
        if (qrCode != null) {
          // TODO: Mostrar QR code para escaneamento
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escaneie o QR code no WhatsApp para conectar'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
        
        _loadConnectedAccounts();
      } else {
        throw Exception(result['error'] ?? 'Falha na conexão');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao conectar WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectInstagram(BuildContext context) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conectar Instagram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'username': usernameController.text,
              'password': passwordController.text,
            }),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (credentials != null) {
      try {
        final result = await _socialAuthService.connectInstagram(
          username: credentials['username']!,
          password: credentials['password']!,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Instagram conectado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadConnectedAccounts();
        } else {
          throw Exception(result['error'] ?? 'Falha na conexão');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar Instagram: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 