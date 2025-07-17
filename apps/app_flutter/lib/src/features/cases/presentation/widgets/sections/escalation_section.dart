import 'package:flutter/material.dart';
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

class EscalationSection extends BaseInfoSection {
  const EscalationSection({
    required super.caseDetail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Escritório',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Escalação e Suporte',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Current Escalation Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Status Atual',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nenhuma escalação necessária',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildInfoRow(Icons.person, 'Supervisor Direto', 'Dr. Carlos Silva'),
                  buildInfoRow(Icons.schedule, 'Último Check-in', 'Hoje - 14:30'),
                  buildInfoRow(Icons.assignment, 'Próxima Revisão', 'Amanhã - 10:00'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Escalation Hierarchy
            Container(
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
                      Icon(Icons.account_tree, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hierarquia de Escalação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHierarchyLevel(
                    'Nível 1 - Supervisor',
                    'Dr. Carlos Silva',
                    'Questões técnicas e prazos',
                    Icons.person,
                    Colors.blue,
                    isAvailable: true,
                  ),
                  _buildHierarchyLevel(
                    'Nível 2 - Sócio Sênior',
                    'Dra. Ana Oliveira',
                    'Decisões estratégicas',
                    Icons.star,
                    Colors.purple,
                    isAvailable: true,
                  ),
                  _buildHierarchyLevel(
                    'Nível 3 - Managing Partner',
                    'Dr. Roberto Santos',
                    'Questões críticas do cliente',
                    Icons.diamond,
                    Colors.orange,
                    isAvailable: false,
                    nextAvailable: 'Disponível às 16:00',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick Escalation Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escalação Rápida',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Dúvida Técnica',
                          'Questões jurídicas específicas',
                          Icons.help_outline,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Prazo Crítico',
                          'Extensão de deadlines',
                          Icons.access_time,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Recursos Extras',
                          'Suporte adicional',
                          Icons.group_add,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Cliente Difícil',
                          'Situações delicadas',
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recent Escalations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escalações Recentes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentEscalation(
                    'Dúvida sobre jurisprudência',
                    'Dr. Carlos Silva',
                    '15/01/2025',
                    'Resolvida',
                    Colors.green,
                  ),
                  _buildRecentEscalation(
                    'Extensão de prazo - Cliente X',
                    'Dra. Ana Oliveira',
                    '12/01/2025',
                    'Aprovada',
                    Colors.blue,
                  ),
                  _buildRecentEscalation(
                    'Revisão de estratégia',
                    'Dr. Carlos Silva',
                    '10/01/2025',
                    'Implementada',
                    Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Communication Guidelines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat, color: Colors.indigo[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Diretrizes de Comunicação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuidelineItem(
                    'Urgência Baixa',
                    'Email ou Slack - Resposta em 4h',
                    Icons.mail,
                    Colors.green,
                  ),
                  _buildGuidelineItem(
                    'Urgência Média',
                    'WhatsApp ou chamada - Resposta em 1h',
                    Icons.phone,
                    Colors.orange,
                  ),
                  _buildGuidelineItem(
                    'Urgência Alta',
                    'Chamada direta + email - Resposta imediata',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Initiate escalation
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Solicitar Suporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View escalation history
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyLevel(
    String level,
    String name,
    String responsibility,
    IconData icon,
    Color color,
    {bool isAvailable = true, String? nextAvailable}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  responsibility,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAvailable ? 'Disponível' : 'Ocupado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              if (!isAvailable && nextAvailable != null) ...[
                const SizedBox(height: 4),
                Text(
                  nextAvailable,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEscalationCard(String title, String description, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Handle escalation
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEscalation(String issue, String escalatedTo, String date, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Para: $escalatedTo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String urgency, String method, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgency,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 11,
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
} 
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

class EscalationSection extends BaseInfoSection {
  const EscalationSection({
    required super.caseDetail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Escritório',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Escalação e Suporte',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Current Escalation Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Status Atual',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nenhuma escalação necessária',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildInfoRow(Icons.person, 'Supervisor Direto', 'Dr. Carlos Silva'),
                  buildInfoRow(Icons.schedule, 'Último Check-in', 'Hoje - 14:30'),
                  buildInfoRow(Icons.assignment, 'Próxima Revisão', 'Amanhã - 10:00'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Escalation Hierarchy
            Container(
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
                      Icon(Icons.account_tree, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Hierarquia de Escalação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHierarchyLevel(
                    'Nível 1 - Supervisor',
                    'Dr. Carlos Silva',
                    'Questões técnicas e prazos',
                    Icons.person,
                    Colors.blue,
                    isAvailable: true,
                  ),
                  _buildHierarchyLevel(
                    'Nível 2 - Sócio Sênior',
                    'Dra. Ana Oliveira',
                    'Decisões estratégicas',
                    Icons.star,
                    Colors.purple,
                    isAvailable: true,
                  ),
                  _buildHierarchyLevel(
                    'Nível 3 - Managing Partner',
                    'Dr. Roberto Santos',
                    'Questões críticas do cliente',
                    Icons.diamond,
                    Colors.orange,
                    isAvailable: false,
                    nextAvailable: 'Disponível às 16:00',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick Escalation Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escalação Rápida',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Dúvida Técnica',
                          'Questões jurídicas específicas',
                          Icons.help_outline,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Prazo Crítico',
                          'Extensão de deadlines',
                          Icons.access_time,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Recursos Extras',
                          'Suporte adicional',
                          Icons.group_add,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickEscalationCard(
                          'Cliente Difícil',
                          'Situações delicadas',
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recent Escalations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escalações Recentes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentEscalation(
                    'Dúvida sobre jurisprudência',
                    'Dr. Carlos Silva',
                    '15/01/2025',
                    'Resolvida',
                    Colors.green,
                  ),
                  _buildRecentEscalation(
                    'Extensão de prazo - Cliente X',
                    'Dra. Ana Oliveira',
                    '12/01/2025',
                    'Aprovada',
                    Colors.blue,
                  ),
                  _buildRecentEscalation(
                    'Revisão de estratégia',
                    'Dr. Carlos Silva',
                    '10/01/2025',
                    'Implementada',
                    Colors.purple,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Communication Guidelines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat, color: Colors.indigo[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Diretrizes de Comunicação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuidelineItem(
                    'Urgência Baixa',
                    'Email ou Slack - Resposta em 4h',
                    Icons.mail,
                    Colors.green,
                  ),
                  _buildGuidelineItem(
                    'Urgência Média',
                    'WhatsApp ou chamada - Resposta em 1h',
                    Icons.phone,
                    Colors.orange,
                  ),
                  _buildGuidelineItem(
                    'Urgência Alta',
                    'Chamada direta + email - Resposta imediata',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Initiate escalation
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Solicitar Suporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // View escalation history
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyLevel(
    String level,
    String name,
    String responsibility,
    IconData icon,
    Color color,
    {bool isAvailable = true, String? nextAvailable}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  responsibility,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAvailable ? 'Disponível' : 'Ocupado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAvailable ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              if (!isAvailable && nextAvailable != null) ...[
                const SizedBox(height: 4),
                Text(
                  nextAvailable,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEscalationCard(String title, String description, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Handle escalation
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEscalation(String issue, String escalatedTo, String date, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Para: $escalatedTo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String urgency, String method, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgency,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 11,
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
} 