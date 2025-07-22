import 'package:flutter/material.dart';
import '../../../../shared/widgets/official_social_icons.dart';
import 'package:dio/dio.dart';

import '../../../../core/services/social_auth_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../widgets/social_platform_card.dart';
import '../widgets/connect_social_modal.dart';

/// Tela para gerenciar conexões de redes sociais
/// 
/// Permite aos usuários (clientes e advogados) conectar e gerenciar
/// suas contas do LinkedIn, Instagram e Facebook via Unipile SDK.
class SocialConnectionsScreen extends StatefulWidget {
  const SocialConnectionsScreen({super.key});

  @override
  State<SocialConnectionsScreen> createState() => _SocialConnectionsScreenState();
}

class _SocialConnectionsScreenState extends State<SocialConnectionsScreen> {
  final SocialAuthService _socialService = SocialAuthService(Dio());
  List<SocialAccount> _connectedAccounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  Future<void> _loadConnectedAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _socialService.getConnectedAccounts();
      setState(() {
        _connectedAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar contas conectadas';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectSocialAccount(String provider) async {
    final result = await showModalBottomSheet<SocialConnectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConnectSocialModal(provider: provider),
    );

    if (result != null && result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadConnectedAccounts(); // Recarregar lista
    } else if (result != null && !result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isProviderConnected(String provider) {
    return _connectedAccounts.any((account) => 
        account.provider == provider && account.isActive);
  }

  SocialAccount? _getConnectedAccount(String provider) {
    try {
      return _connectedAccounts.firstWhere((account) => 
          account.provider == provider && account.isActive);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Redes Sociais',
          style: AppTextStyles.h5,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.lightText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConnectedAccounts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildSocialPlatformsSection(),
              const SizedBox(height: 32),
              _buildBenefitsSection(),
              const SizedBox(height: 32),
              _buildPrivacySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conecte suas Redes Sociais',
                      style: AppTextStyles.h5,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aumente sua credibilidade e visibilidade profissional',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_connectedAccounts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_connectedAccounts.length} conta(s) conectada(s)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialPlatformsSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Tentar Novamente',
              onPressed: _loadConnectedAccounts,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plataformas Disponíveis',
          style: AppTextStyles.h5,
        ),
        const SizedBox(height: 16),
        
        // LinkedIn
        SocialPlatformCard(
          provider: 'linkedin',
          title: 'LinkedIn',
          description: 'Conecte sua rede profissional',
          icon: SocialPlatform.linkedin,
          color: const Color(0xFF0A66C2),
          isConnected: _isProviderConnected('linkedin'),
          account: _getConnectedAccount('linkedin'),
          onConnect: () => _connectSocialAccount('linkedin'),
          onDisconnect: () => _disconnectAccount('linkedin'),
        ),
        
        const SizedBox(height: 12),
        
        // Instagram
        SocialPlatformCard(
          provider: 'instagram',
          title: 'Instagram',
          description: 'Mostre sua presença visual',
          icon: SocialPlatform.instagram,
          color: const Color(0xFFE4405F),
          isConnected: _isProviderConnected('instagram'),
          account: _getConnectedAccount('instagram'),
          onConnect: () => _connectSocialAccount('instagram'),
          onDisconnect: () => _disconnectAccount('instagram'),
        ),
        
        const SizedBox(height: 12),
        
        // Facebook
        SocialPlatformCard(
          provider: 'facebook',
          title: 'Facebook',
          description: 'Amplie seu alcance social',
          icon: SocialPlatform.facebook,
          color: const Color(0xFF1877F2),
          isConnected: _isProviderConnected('facebook'),
          account: _getConnectedAccount('facebook'),
          onConnect: () => _connectSocialAccount('facebook'),
          onDisconnect: () => _disconnectAccount('facebook'),
        ),
        
        const SizedBox(height: 12),
        
        // WhatsApp
        SocialPlatformCard(
          provider: 'whatsapp',
          title: 'WhatsApp',
          description: 'Facilite comunicação direta',
          icon: SocialPlatform.whatsapp,
          color: const Color(0xFF25D366),
          isConnected: _isProviderConnected('whatsapp'),
          account: _getConnectedAccount('whatsapp'),
          onConnect: () => _connectSocialAccount('whatsapp'),
          onDisconnect: () => _disconnectAccount('whatsapp'),
        ),
        
        const SizedBox(height: 12),
        
        // Twitter/X
        SocialPlatformCard(
          provider: 'twitter',
          title: 'Twitter/X',
          description: 'Compartilhe pensamentos e updates',
          icon: SocialPlatform.x,
          color: const Color(0xFF000000),
          isConnected: _isProviderConnected('twitter'),
          account: _getConnectedAccount('twitter'),
          onConnect: () => _connectSocialAccount('twitter'),
          onDisconnect: () => _disconnectAccount('twitter'),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefícios das Conexões Sociais',
            style: AppTextStyles.h5,
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.trending_up,
            title: 'Maior Visibilidade',
            description: 'Apareça melhor nos resultados de busca',
          ),
          _buildBenefitItem(
            icon: Icons.verified,
            title: 'Credibilidade Aumentada',
            description: 'Valide sua presença profissional',
          ),
          _buildBenefitItem(
            icon: Icons.people,
            title: 'Rede de Contatos',
            description: 'Mostre sua rede profissional',
          ),
          _buildBenefitItem(
            icon: Icons.analytics,
            title: 'Métricas Sociais',
            description: 'Demonstre engajamento e popularidade',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security,
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Privacidade e Segurança',
                style: AppTextStyles.h5,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• Seus dados são protegidos com criptografia de ponta\n'
            '• Você controla quais informações são compartilhadas\n'
            '• As credenciais são armazenadas de forma segura\n'
            '• Você pode desconectar a qualquer momento',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectAccount(String provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desconectar ${provider.toUpperCase()}'),
        content: const Text(
          'Tem certeza que deseja desconectar esta conta? '
          'Isso pode afetar sua visibilidade na plataforma.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implementar desconexão via API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.toUpperCase()} desconectado com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadConnectedAccounts();
    }
  }
} 