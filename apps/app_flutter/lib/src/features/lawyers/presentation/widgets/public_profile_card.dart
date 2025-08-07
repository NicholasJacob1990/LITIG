import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/contact_request_modal.dart';
import 'package:meu_app/src/shared/widgets/atoms/initials_avatar.dart';

class PublicProfileCard extends StatefulWidget {
  final MatchedLawyer lawyer;
  final VoidCallback? onRequestContact;
  final VoidCallback? onViewVerified;
  final String? caseId;

  const PublicProfileCard({
    super.key,
    required this.lawyer,
    this.onRequestContact,
    this.onViewVerified,
    this.caseId,
  });

  @override
  State<PublicProfileCard> createState() => _PublicProfileCardState();
}

class _PublicProfileCardState extends State<PublicProfileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borda cinza para indicar perfil não verificado
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Gradiente sutil cinza para diferenciar de perfis verificados
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100, // Corrigido: shade25 não existe
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 12),
              _buildLimitationsWarning(context, theme),
              const SizedBox(height: 16),
              _buildBasicInfo(context, theme),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                _buildExpandedInfo(context, theme),
              ],
              const SizedBox(height: 16),
              _buildActionButtons(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Avatar com indicador de perfil público
        Stack(
          children: [
            InitialsAvatar(
              text: widget.lawyer.nome, // Corrigido: parameter name
              radius: 28, // Corrigido: usar radius em vez de size
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  LucideIcons.globe,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome + selo de perfil público
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.lawyer.nome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800, // Cor menos vibrante
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.globe,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Perfil Público',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Área de especialização
              Text(
                widget.lawyer.primaryArea,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              // Score não disponível
              const SizedBox(height: 4),
              Text(
                'Score: Não disponível',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Botão de expandir
        IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitationsWarning(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            size: 16,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações Limitadas',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dados coletados da web. Não verificados pela LITIG.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Localização
        if (widget.lawyer.distanceKm > 0) ...[
          Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.lawyer.distanceKm.toStringAsFixed(1)} km de distância',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Especializações
        if (widget.lawyer.specializations.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.briefcase,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: widget.lawyer.specializations.take(3).map((spec) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        spec,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedInfo(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Profissional',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lawyer.professionalSummary ?? 
            'Informações detalhadas não disponíveis. Para dados completos e verificados, considere nossos Advogados Verificados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Informações que não temos
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados Não Disponíveis:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                _buildMissingDataItem('• Reviews e avaliações de clientes'),
                _buildMissingDataItem('• Taxa de sucesso em casos'),
                _buildMissingDataItem('• Tempo médio de resposta'),
                _buildMissingDataItem('• Histórico de casos na plataforma'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingDataItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Botão principal - Solicitar Contato (secundário)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showContactRequestModal(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.mail, size: 18),
            label: const Text(
              'Solicitar Contato',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Botão secundário - Ver Verificados (primário)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onViewVerified,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.shield, size: 18),
            label: const Text(
              'Ver Advogados Verificados',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showContactRequestModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactRequestModal(
        lawyer: widget.lawyer,
        caseId: widget.caseId ?? '',
        onResult: (result) {
          // Callback para tratar resultado do contato
          if (widget.onRequestContact != null) {
            widget.onRequestContact!();
          }
          
          // Mostrar feedback baseado no resultado
          String message = '';
          IconData icon = LucideIcons.check;
          Color color = Colors.green;
          
          switch (result) {
            case ContactRequestResult.success:
              message = 'E-mail enviado com sucesso!';
              break;
            case ContactRequestResult.linkedinFallback:
              message = 'Use o LinkedIn para melhor resultado';
              icon = LucideIcons.linkedin;
              color = Colors.blue;
              break;
            case ContactRequestResult.noContact:
              message = 'Recomendamos nossos Advogados Verificados';
              icon = LucideIcons.alertTriangle;
              color = Colors.orange;
              break;
            case ContactRequestResult.error:
              message = 'Erro ao enviar solicitação';
              icon = LucideIcons.alertCircle;
              color = Colors.red;
              break;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: color,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }
} 