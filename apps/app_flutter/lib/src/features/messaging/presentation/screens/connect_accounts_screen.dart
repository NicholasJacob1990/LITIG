import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app/src/core/services/social_auth_service.dart';
import 'package:meu_app/src/core/utils/app_logger.dart';

class ConnectAccountsScreen extends StatefulWidget {
  const ConnectAccountsScreen({super.key});

  @override
  State<ConnectAccountsScreen> createState() => _ConnectAccountsScreenState();
}

class _ConnectAccountsScreenState extends State<ConnectAccountsScreen> {
  final SocialAuthService _socialAuthService = SocialAuthService();
  final Map<String, bool> _connectedAccounts = {
    'linkedin': false,
    'instagram': false,
    'whatsapp': false,
    'gmail': false,
    'outlook': false,
    'teams': false,
    'telegram': false,
    'twitter': false,
  };

  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  Future<void> _loadConnectedAccounts() async {
    try {
      final accounts = await _socialAuthService.getConnectedAccounts();
      setState(() {
        for (final account in accounts) {
          final platform = account['provider'] as String?;
          if (platform != null && _connectedAccounts.containsKey(platform)) {
            _connectedAccounts[platform] = true;
          }
        }
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar contas conectadas', {'error': e.toString()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar Contas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(),
            const SizedBox(height: 24),
            _buildAccountsGrid(),
            const SizedBox(height: 32),
            _buildConnectedAccountsSection(),
            const SizedBox(height: 32),
            _buildPrivacySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              LucideIcons.link,
              size: 48,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Text(
              'Conecte suas Contas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Centralize todas as suas conversas em um só lugar. Conecte suas redes sociais e e-mails para uma experiência unificada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plataformas Disponíveis',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildAccountCard('linkedin', 'LinkedIn', 'assets/icons/linkedin.svg', const Color(0xFF0077B5)),
            _buildAccountCard('instagram', 'Instagram', 'assets/icons/instagram.svg', const Color(0xFFE4405F)),
            _buildAccountCard('whatsapp', 'WhatsApp', 'assets/icons/whatsapp.svg', const Color(0xFF25D366)),
            _buildAccountCard('gmail', 'Gmail', 'assets/icons/gmail.svg', const Color(0xFFEA4335)),
            _buildAccountCard('outlook', 'Outlook', 'assets/icons/outlook.svg', const Color(0xFF0078D4)),
            _buildAccountCard('teams', 'Teams', 'assets/icons/teams.svg', Colors.indigo.shade600),
            _buildAccountCard('telegram', 'Telegram', 'assets/icons/telegram.svg', Colors.blue.shade500),
            _buildAccountCard('twitter', 'Twitter', 'assets/icons/twitter.svg', Colors.blue.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard(String provider, String name, String svgAsset, Color color) {
    final isConnected = _connectedAccounts[provider] ?? false;
    final isLoading = _loadingStates[provider] ?? false;

    return Card(
      elevation: isConnected ? 4 : 2,
      child: InkWell(
        onTap: isLoading ? null : () => _toggleAccount(provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isConnected 
              ? Border.all(color: color, width: 2)
              : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isConnected ? color : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        svgAsset,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  if (isConnected)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isConnected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isConnected ? 'Conectado' : 'Conectar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isConnected ? Colors.green : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedAccountsSection() {
    final connectedCount = _connectedAccounts.values.where((connected) => connected).length;
    
    if (connectedCount == 0) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contas Conectadas ($connectedCount)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._connectedAccounts.entries
            .where((entry) => entry.value)
            .map((entry) => _buildConnectedAccountTile(entry.key)),
      ],
    );
  }

  Widget _buildConnectedAccountTile(String provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProviderColor(provider),
          child: Icon(
            _getProviderIcon(provider),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(_getProviderName(provider)),
        subtitle: const Text('Conta conectada com sucesso'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'disconnect') {
              _disconnectAccount(provider);
            } else if (value == 'sync') {
              _syncAccount(provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sync',
              child: Row(
                children: [
                  Icon(LucideIcons.refreshCw, size: 16),
                  SizedBox(width: 8),
                  Text('Sincronizar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'disconnect',
              child: Row(
                children: [
                  Icon(LucideIcons.unlink, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Desconectar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.shield, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Segurança e Privacidade',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrivacyItem('Criptografia ponta a ponta para todas as mensagens'),
            _buildPrivacyItem('Dados armazenados de forma segura e em conformidade com LGPD'),
            _buildPrivacyItem('Você pode desconectar qualquer conta a qualquer momento'),
            _buildPrivacyItem('Não compartilhamos suas informações com terceiros'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showPrivacyPolicy,
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Ver Política de Privacidade'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.check,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAccount(String provider) {
    final isConnected = _connectedAccounts[provider] ?? false;
    
    if (isConnected) {
      _disconnectAccount(provider);
    } else {
      _connectAccount(provider);
    }
  }

  void _connectAccount(String provider) async {
    setState(() {
      _loadingStates[provider] = true;
    });

    try {
      // Simular processo OAuth
      await Future.delayed(const Duration(seconds: 2));
      
      // Mostrar dialog OAuth simulado
      final success = await _showOAuthDialog(provider);
      
      if (success) {
        setState(() {
          _connectedAccounts[provider] = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getProviderName(provider)} conectado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar ${_getProviderName(provider)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingStates[provider] = false;
      });
    }
  }

  void _disconnectAccount(String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desconectar ${_getProviderName(provider)}'),
        content: const Text('Tem certeza que deseja desconectar esta conta? Você não receberá mais mensagens desta plataforma.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _connectedAccounts[provider] = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_getProviderName(provider)} desconectado'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desconectar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _syncAccount(String provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sincronizando ${_getProviderName(provider)}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getProviderName(provider)} sincronizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<bool> _showOAuthDialog(String provider) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Conectar ${_getProviderName(provider)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getProviderIcon(provider),
              size: 64,
              color: _getProviderColor(provider),
            ),
            const SizedBox(height: 16),
            const Text('Você será redirecionado para fazer login em sua conta.'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidade'),
        content: const SingleChildScrollView(
          child: Text(
            'Política de Privacidade - LITIG-1\n\n'
            '1. Coleta de Dados\n'
            'Coletamos apenas os dados necessários para fornecer nossos serviços.\n\n'
            '2. Uso dos Dados\n'
            'Seus dados são usados exclusivamente para melhorar sua experiência.\n\n'
            '3. Compartilhamento\n'
            'Não compartilhamos suas informações com terceiros.\n\n'
            '4. Segurança\n'
            'Utilizamos as melhores práticas de segurança para proteger seus dados.\n\n'
            '5. Seus Direitos\n'
            'Você pode solicitar acesso, correção ou exclusão de seus dados a qualquer momento.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return Colors.blue.shade700;
      case 'instagram':
        return Colors.pink.shade500;
      case 'whatsapp':
        return Colors.green.shade600;
      case 'gmail':
        return Colors.red.shade500;
      case 'outlook':
        return Colors.blue.shade600;
      case 'teams':
        return Colors.indigo.shade600;
      case 'telegram':
        return Colors.blue.shade500;
      case 'twitter':
        return Colors.blue.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return Icons.business;
      case 'instagram':
        return Icons.camera_alt;
      case 'whatsapp':
        return Icons.message;
      case 'gmail':
        return Icons.email;
      case 'outlook':
        return Icons.mail_outline;
      case 'teams':
        return Icons.groups;
      case 'telegram':
        return Icons.send;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return LucideIcons.messageCircle;
    }
  }

  String _getProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'linkedin':
        return 'LinkedIn';
      case 'instagram':
        return 'Instagram';
      case 'whatsapp':
        return 'WhatsApp';
      case 'gmail':
        return 'Gmail';
      case 'outlook':
        return 'Outlook';
      case 'teams':
        return 'Microsoft Teams';
      case 'telegram':
        return 'Telegram';
      case 'twitter':
        return 'Twitter';
      default:
        return 'Mensagem';
    }
  }
}