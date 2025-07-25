import 'package:flutter/material.dart';
import '../base_info_section.dart';

class NextOpportunitiesSection extends BaseInfoSection {
  const NextOpportunitiesSection({
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Plataforma',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Próximas Oportunidades',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Opportunity Pipeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pipeline de Oportunidades',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPipelineCard(
                          'Esta Semana',
                          '3 casos',
                          'R\$ 12.500',
                          Colors.green,
                          Icons.today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPipelineCard(
                          'Próximas 2 Semanas',
                          '7 casos',
                          'R\$ 31.000',
                          Colors.blue,
                          Icons.date_range,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPipelineCard(
                          'Este Mês',
                          '15 casos',
                          'R\$ 78.500',
                          Colors.purple,
                          Icons.calendar_month,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPipelineCard(
                          'Score Médio',
                          '8.7/10',
                          '94% match',
                          Colors.orange,
                          Icons.star,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Hot Opportunities
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.whatshot, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Oportunidades Quentes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHotOpportunity(
                    'Ação Trabalhista Complexa',
                    'Multinacional - Tecnologia',
                    'R\$ 15.000',
                    '96%',
                    'Hoje - 18:00',
                    Colors.red,
                    isUrgent: true,
                  ),
                  _buildHotOpportunity(
                    'Disputa Contratual',
                    'Startup em crescimento',
                    'R\$ 8.500',
                    '92%',
                    'Amanhã - 10:00',
                    Colors.orange,
                  ),
                  _buildHotOpportunity(
                    'Consultoria Regulatória',
                    'Empresa consolidada',
                    'R\$ 12.000',
                    '89%',
                    'Amanhã - 15:00',
                    Colors.blue,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Growth Opportunities
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_graph, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Iniciativas de Crescimento',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGrowthInitiative(
                    'Certificação Especializada',
                    'Direito Digital - 40h',
                    '85%',
                    '+15% em matches',
                    Icons.school,
                    Colors.blue,
                    status: 'Em andamento',
                  ),
                  _buildGrowthInitiative(
                    'Parceria Estratégica',
                    'Escritório ABC para Co-advocacia',
                    '60%',
                    '+25% capacidade',
                    Icons.handshake,
                    Colors.purple,
                    status: 'Negociação',
                  ),
                  _buildGrowthInitiative(
                    'Expansão Geográfica',
                    'Região Metropolitana',
                    '30%',
                    '+50% mercado',
                    Icons.location_on,
                    Colors.orange,
                    status: 'Planejamento',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Platform Insights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: Colors.indigo[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Insights da Plataforma',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  buildInfoRow(context, Icons.trending_up, 'Demanda Crescente', 'Direito Trabalhista (+23%)'),
                  buildInfoRow(context, Icons.schedule, 'Melhor Horário', 'Terças e Quintas 14-17h'),
                  buildInfoRow(context, Icons.attach_money, 'Precificação Ideal', 'R\$ 165-180/hora'),
                  buildInfoRow(context, Icons.speed, 'Tempo Resposta Alvo', '< 1h para 95% match'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.indigo[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dica: Aumente em 12% sua taxa de conversão melhorando o tempo de primeira resposta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Strategic Positioning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.teal[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Posicionamento Estratégico',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPositionItem(
                    'Nicho de Mercado',
                    'Tecnologia + Trabalhista',
                    'Poucos especialistas nesta intersecção',
                    Icons.code,
                    Colors.teal,
                    opportunity: 'Alta',
                  ),
                  _buildPositionItem(
                    'Segment Premium',
                    'Empresas de grande porte',
                    'Casos de alta complexidade e valor',
                    Icons.business,
                    Colors.purple,
                    opportunity: 'Média',
                  ),
                  _buildPositionItem(
                    'Consultoria Preventiva',
                    'Compliance e auditoria',
                    'Mercado em expansão pós-pandemia',
                    Icons.security,
                    Colors.blue,
                    opportunity: 'Alta',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Performance Goals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Metas de Performance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGoalCard(
                          'Este Mês',
                          '12/15 casos',
                          '80%',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGoalCard(
                          'Trimestre',
                          '35/45 casos',
                          '78%',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGoalCard(
                          'Revenue',
                          'R\$ 85k/100k',
                          '85%',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGoalCard(
                          'NPS Score',
                          '8.7/9.0',
                          '97%',
                          Colors.purple,
                        ),
                      ),
                    ],
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
                      // View detailed opportunities
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explorar Oportunidades'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Set preferences
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Ajustar Preferências'),
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

  Widget _buildPipelineCard(String period, String cases, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            cases,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            period,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHotOpportunity(
    String title,
    String client,
    String value,
    String match,
    String deadline,
    Color color,
    {bool isUrgent = false}
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isUrgent ? 0.4 : 0.2),
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isUrgent ? Icons.priority_high : Icons.star,
              color: color,
              size: 16,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'URGENTE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  client,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Deadline: $deadline',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$match match',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthInitiative(
    String title,
    String description,
    String progress,
    String impact,
    IconData icon,
    Color color,
    {required String status}
  ) {
    Color statusColor = status == 'Em andamento' ? Colors.blue : 
                       (status == 'Negociação' ? Colors.orange : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Impacto esperado: $impact',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progress,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionItem(
    String title,
    String description,
    String insight,
    IconData icon,
    Color color,
    {required String opportunity}
  ) {
    Color opportunityColor = opportunity == 'Alta' ? Colors.green : 
                           (opportunity == 'Média' ? Colors.orange : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: opportunityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opportunity,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: opportunityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String period, String current, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            current,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            period,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 

