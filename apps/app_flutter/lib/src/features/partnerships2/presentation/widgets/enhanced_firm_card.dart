import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../firms/domain/entities/law_firm.dart';

/// Widget aprimorado para FirmCard com funcionalidades B2B básicas
/// 
/// Este widget demonstra a integração:
/// - Navegação contextual (interna vs modal)
/// - Sistema de contratação básico
/// - Menu de ações contextuais
class EnhancedFirmCard extends StatelessWidget {
  final LawFirm firm;
  final bool showHireButton;
  final Function(String, String, String)? onFirmHire; // firmId, caseId, clientId
  final String? currentCaseId;
  final String? currentClientId;
  final bool compact;
  final VoidCallback? onTap;

  const EnhancedFirmCard({
    super.key,
    required this.firm,
    this.showHireButton = false,
    this.onFirmHire,
    this.currentCaseId,
    this.currentClientId,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => _showNavigationOptions(context),
        onLongPress: () => _showNavigationOptions(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildInfo(context),
              if (showHireButton && _canHireFirm()) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Text(
            firm.name.isNotEmpty ? firm.name.substring(0, 1).toUpperCase() : 'E',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firm.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.group, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${firm.teamSize} profissionais',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showNavigationOptions(context),
          icon: const Icon(Icons.more_vert),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Row(
      children: [
        if (firm.hasLocation) ...[
          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Localização disponível',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (firm.kpis != null) ...[
          Icon(Icons.star, size: 14, color: Colors.amber[600]),
          const SizedBox(width: 4),
          Text(
            'Com avaliações',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToFirmDetail(context),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Ver Detalhes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSimpleHiringDialog(context),
            icon: const Icon(Icons.handshake, size: 16),
            label: const Text('Contratar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  bool _canHireFirm() {
    return onFirmHire != null && 
           currentCaseId != null && 
           currentClientId != null;
  }

  void _showSimpleHiringDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contratar ${firm.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deseja contratar este escritório para o caso atual?'),
            const SizedBox(height: 16),
            const Text(
              'Detalhes:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('• ${firm.teamSize} profissionais'),
            if (firm.hasLocation) const Text('• Localização disponível'),
            if (firm.kpis != null) const Text('• Com avaliações'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processHiring(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _processHiring(BuildContext context) {
    if (_canHireFirm()) {
      onFirmHire!(firm.id, currentCaseId!, currentClientId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Solicitação de contratação enviada para ${firm.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showNavigationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              firm.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            _buildNavigationOption(
              context,
              icon: Icons.visibility,
              title: 'Ver Detalhes',
              subtitle: 'Abrir na aba atual',
              onTap: () {
                Navigator.pop(context);
                _navigateToFirmDetail(context);
              },
            ),
            _buildNavigationOption(
              context,
              icon: Icons.fullscreen,
              title: 'Tela Cheia',
              subtitle: 'Abrir sobreposição',
              onTap: () {
                Navigator.pop(context);
                _navigateToFirmDetailModal(context);
              },
            ),
            _buildNavigationOption(
              context,
              icon: Icons.group,
              title: 'Ver Advogados',
              subtitle: 'Lista de profissionais',
              onTap: () {
                Navigator.pop(context);
                _navigateToFirmLawyers(context);
              },
            ),
            if (_canHireFirm()) ...[
              const Divider(),
              _buildNavigationOption(
                context,
                icon: Icons.handshake,
                title: 'Contratar Escritório',
                subtitle: 'Iniciar processo de contratação',
                onTap: () {
                  Navigator.pop(context);
                  _showSimpleHiringDialog(context);
                },
                isHighlighted: true,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isHighlighted 
              ? Theme.of(context).primaryColor 
              : Colors.grey[700],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          color: isHighlighted ? Theme.of(context).primaryColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  void _navigateToFirmDetail(BuildContext context) {
    context.push('/firm/${firm.id}');
  }

  void _navigateToFirmDetailModal(BuildContext context) {
    context.push('/firm-modal/${firm.id}');
  }

  void _navigateToFirmLawyers(BuildContext context) {
    context.push('/firm/${firm.id}/lawyers');
  }
}

/// Helper para usar em listas
class FirmListTile extends StatelessWidget {
  final LawFirm firm;
  final bool showHireButton;
  final Function(String, String, String)? onFirmHire;
  final String? currentCaseId;
  final String? currentClientId;

  const FirmListTile({
    super.key,
    required this.firm,
    this.showHireButton = false,
    this.onFirmHire,
    this.currentCaseId,
    this.currentClientId,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedFirmCard(
      firm: firm,
      showHireButton: showHireButton,
      onFirmHire: onFirmHire,
      currentCaseId: currentCaseId,
      currentClientId: currentClientId,
      compact: true,
    );
  }
} 