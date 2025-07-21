import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Contato com Cliente para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** LawyerResponsibleSection (experiência do cliente)
/// **Foco:** Informações do cliente, perfil, histórico e dados de contato
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir LawyerResponsibleSection para advogados contratantes
/// - Foco em oportunidade de negócio e relacionamento com cliente
class ClientContactSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const ClientContactSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      context,
      title: 'Informações do Cliente',
      children: [
        _buildClientProfile(context),
        const SizedBox(height: 16),
        _buildContactInfo(context),
        const SizedBox(height: 16),
        _buildClientHistory(context),
        const SizedBox(height: 20),
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildClientProfile(BuildContext context) {
    final clientName = contextualData?['client_name'] ?? 'Cliente Litgo';
    final clientType = contextualData?['client_type'] ?? 'Pessoa Física';
    final clientRating = contextualData?['client_rating'] ?? 8.5;
    final clientSince = contextualData?['client_since'] ?? 'Jan/2024';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil do Cliente',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Nome e tipo do cliente
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[50],
              child: Icon(
                clientType == 'Pessoa Jurídica' ? Icons.business : Icons.person,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    clientType,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Rating do cliente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(clientRating).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRatingColor(clientRating).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: _getRatingColor(clientRating),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    clientRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getRatingColor(clientRating),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Informações adicionais
        Row(
          children: [
            Expanded(
              child: buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                'Cliente desde',
                clientSince,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildInfoRow(
                context,
                Icons.cases_outlined,
                'Casos anteriores',
                '${contextualData?['previous_cases'] ?? 3}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final email = contextualData?['client_email'] ?? 'cliente@email.com';
    final phone = contextualData?['client_phone'] ?? '(11) 99999-9999';
    final preferredContact = contextualData?['preferred_contact'] ?? 'WhatsApp';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contato Preferencial',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            children: [
              buildInfoRow(context, Icons.email_outlined, 'E-mail', email),
              const SizedBox(height: 8),
              buildInfoRow(context, Icons.phone_outlined, 'Telefone', phone),
              const SizedBox(height: 8),
              buildInfoRow(context, Icons.chat_outlined, 'Preferência', preferredContact),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientHistory(BuildContext context) {
    final totalPaid = contextualData?['total_paid'] ?? 15750.0;
    final averageRating = contextualData?['average_rating'] ?? 9.2;
    final lastCaseDate = contextualData?['last_case_date'] ?? 'Mar/2024';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Relacionamento',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                'Total Pago',
                'R\$ ${totalPaid.toStringAsFixed(0)}',
                Icons.monetization_on_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                context,
                'Avaliação Média',
                averageRating.toStringAsFixed(1),
                Icons.star_outline,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                context,
                'Último Caso',
                lastCaseDate,
                Icons.schedule_outlined,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(context,
                label: 'Contatar Cliente',
                icon: Icons.phone,
                onPressed: () => _contactClient(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(context,
                label: 'Ver Histórico',
                icon: Icons.history,
                onPressed: () => _viewHistory(context),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(context,
            label: 'Atualizar Informações do Cliente',
            icon: Icons.edit_outlined,
            onPressed: () => _updateClientInfo(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _contactClient(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contatar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Ligar'),
              subtitle: Text(contextualData?['client_phone'] ?? '(11) 99999-9999'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('WhatsApp'),
              subtitle: const Text('Enviar mensagem'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.orange),
              title: const Text('E-mail'),
              subtitle: Text(contextualData?['client_email'] ?? 'cliente@email.com'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _viewHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Histórico do Cliente'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Casos Anteriores:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Revisão Contratual - Mar/2024'),
            Text('• Rescisão Trabalhista - Jan/2024'),
            Text('• Consultoria Societária - Nov/2023'),
            SizedBox(height: 16),
            Text('Pagamentos:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• R\$ 5.250,00 - Mar/2024'),
            Text('• R\$ 3.500,00 - Jan/2024'),
            Text('• R\$ 7.000,00 - Nov/2023'),
          ],
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

  void _updateClientInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo formulário de atualização do cliente...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 9.0) return Colors.green;
    if (rating >= 7.5) return Colors.orange;
    return Colors.red;
  }
}