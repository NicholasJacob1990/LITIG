import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/partnership_recommendation.dart';

/// Modal para gerenciar convites de parceria (Notificação Assistida via LinkedIn)
class InvitationModal extends StatefulWidget {
  final PartnershipRecommendation recommendation;
  final Function(String message) onSendInvite;

  const InvitationModal({
    super.key,
    required this.recommendation,
    required this.onSendInvite,
  });

  @override
  State<InvitationModal> createState() => _InvitationModalState();
}

class _InvitationModalState extends State<InvitationModal> {
  late TextEditingController _messageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: _generateLinkedInMessage());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle para arrastar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Header
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // Perfil do convidado
                _buildProfilePreview(context),
                const SizedBox(height: 24),
                
                // Estratégia explicada
                _buildStrategyExplanation(context),
                const SizedBox(height: 24),
                
                // Mensagem editável
                _buildMessageEditor(context),
                const SizedBox(height: 24),
                
                // Passos do processo
                _buildProcessSteps(context),
                const SizedBox(height: 32),
                
                // Ações
                _buildActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.mail_outline, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Convite de Parceria',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Notificação Assistida via LinkedIn',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProfilePreview(BuildContext context) {
    final theme = Theme.of(context);
    final rec = widget.recommendation;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: rec.avatarUrl.isNotEmpty ? NetworkImage(rec.avatarUrl) : null,
            child: rec.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.lawyerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.displayHeadline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(rec.compatibilityScore * 100).toInt()}% compatível',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyExplanation(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Por que Notificação Assistida?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para proteger a marca LITIG e maximizar a eficácia, você enviará a mensagem pessoalmente. '
            'Convites pessoais têm maior credibilidade e taxa de aceitação.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageEditor(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mensagem Sugerida',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _copyMessage,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Edite a mensagem conforme necessário...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Você pode editar esta mensagem antes de copiar e enviar no LinkedIn.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessSteps(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como Funciona',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Step 1
        _buildStep(
          context,
          1,
          'Copie a Mensagem',
          'Use o botão "Copiar" para copiar a mensagem personalizada',
          Icons.copy,
          Colors.blue,
        ),
        
        // Step 2
        _buildStep(
          context,
          2,
          'Abra o LinkedIn',
          'Vá para o perfil do advogado no LinkedIn',
          Icons.open_in_new,
          Colors.orange,
        ),
        
        // Step 3
        _buildStep(
          context,
          3,
          'Envie a Mensagem',
          'Cole e envie a mensagem pelo chat do LinkedIn',
          Icons.send,
          Colors.green,
        ),
        
        // Step 4
        _buildStep(
          context,
          4,
          'Confirme o Envio',
          'Retorne aqui e confirme que enviou a mensagem',
          Icons.check_circle,
          Colors.purple,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, 
    int number, 
    String title, 
    String description, 
    IconData icon, 
    Color color,
    {bool isLast = false}
  ) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: 24,
                color: color.withOpacity(0.2),
              ),
            ],
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Botão principal: Abrir LinkedIn
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _openLinkedInProfile,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir LinkedIn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botão secundário: Confirmar envio
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _confirmSent,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Processando...' : 'Confirmar que Enviei'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Texto de instrução
        Text(
          'Clique em "Confirmar" apenas após enviar a mensagem no LinkedIn',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _generateLinkedInMessage() {
    final rec = widget.recommendation;
    final compatibilityPercent = (rec.compatibilityScore * 100).toInt();
    
    return '''Olá ${rec.lawyerName.split(' ').first}!

Encontrei seu perfil através de uma análise de sinergia profissional e identifiquei uma compatibilidade de $compatibilityPercent% entre nossas práticas jurídicas.

**Por que este contato:**
${rec.partnershipReason}

**Áreas de potencial colaboração:**
${rec.potentialSynergies.take(3).map((s) => '• $s').join('\n')}

Gostaria de convida-lo(a) para conhecer a plataforma LITIG, onde advogados e escritórios podem colaborar de forma estratégica e expandir suas redes profissionais.

Ao se cadastrar através deste link personalizado, você terá acesso à análise completa de sinergia entre nossos perfis: [LINK_ÚNICO]

Fico à disposição para uma conversa!

Att,
[SEU_NOME]''';
  }

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: _messageController.text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensagem copiada para a área de transferência!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openLinkedInProfile() async {
    final profileUrl = widget.recommendation.profileData?.profileUrl;
    
    if (profileUrl != null) {
      final uri = Uri.parse(profileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o LinkedIn'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Abrir LinkedIn genérico se não tiver URL específica
      final query = widget.recommendation.lawyerName.replaceAll(' ', '%20');
      final searchUrl = 'https://www.linkedin.com/search/results/people/?keywords=$query';
      final uri = Uri.parse(searchUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _confirmSent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Chamar callback para processar o convite
      widget.onSendInvite(_messageController.text);
      
      // Fechar modal
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar convite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 