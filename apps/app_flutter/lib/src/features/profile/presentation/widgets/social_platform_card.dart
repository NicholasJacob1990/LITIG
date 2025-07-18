import 'package:flutter/material.dart';

import '../../../../core/services/social_auth_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

/// Widget de card para exibir informações de uma plataforma social
/// 
/// Mostra se a conta está conectada e permite conectar/desconectar
class SocialPlatformCard extends StatelessWidget {
  final String provider;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isConnected;
  final SocialAccount? account;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const SocialPlatformCard({
    super.key,
    required this.provider,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isConnected,
    this.account,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected 
              ? color.withOpacity(0.3)
              : AppColors.border,
          width: isConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildContent(),
          const SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
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
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Conectado',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (!isConnected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Conecte sua conta para aumentar sua visibilidade',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (account?.email != null) ...[
            _buildInfoRow(
              icon: Icons.email,
              label: 'E-mail',
              value: account!.email!,
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            icon: Icons.schedule,
            label: 'Última sincronização',
            value: _getLastSyncText(),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.verified,
            label: 'Status',
            value: account?.isActive == true ? 'Ativo' : 'Inativo',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (isConnected) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Sincronizar',
              onPressed: () {
                // TODO: Implementar sincronização
              },
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Desconectar',
              onPressed: onDisconnect,
              variant: AppButtonVariant.danger,
              size: AppButtonSize.small,
            ),
          ),
        ],
      );
    }

    return AppButton(
      text: 'Conectar ${title}',
      onPressed: onConnect,
      variant: AppButtonVariant.primary,
      size: AppButtonSize.medium,
      fullWidth: true,
    );
  }

  String _getLastSyncText() {
    if (account?.lastSync == null) {
      return 'Nunca';
    }

    final now = DateTime.now();
    final diff = now.difference(account!.lastSync!);

    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}min atrás';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h atrás';
    } else {
      return '${diff.inDays}d atrás';
    }
  }
} 