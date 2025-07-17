import 'package:flutter/material.dart';
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Explicação do Match para advogados/escritórios
/// 
/// **Contexto:** Todos os perfis EXCETO Advogados Associados
/// **Perfis que veem:** lawyer_individual, lawyer_office, lawyer_platform_associate
/// **Foco:** Transparência sobre por que foram selecionados pelo algoritmo
/// 
/// Conforme solicitação: todos os advogados/escritórios devem ver a explicação
/// do match, exceto os associados (que recebem por delegação interna)
class MatchExplanationSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const MatchExplanationSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Explicação do Match',
      children: [
        _buildMatchScore(context),
        const SizedBox(height: 16),
        _buildAlgorithmBreakdown(context),
        const SizedBox(height: 16),
        _buildCompatibilityFactors(context),
        const SizedBox(height: 16),
        _buildAIInsights(context),
        const SizedBox(height: 20),
        _buildMatchActions(context),
      ],
    );
  }

  Widget _buildMatchScore(BuildContext context) {
    final matchScore = contextualData?['match_score'] ?? 94.0;
    final aiReason = contextualData?['ai_reason'] ?? 
        'Alta compatibilidade entre sua especialização e o caso do cliente';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score de Compatibilidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Score visual principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getScoreColor(matchScore).withOpacity(0.1),
                _getScoreColor(matchScore).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getScoreColor(matchScore).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Ícone do score
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getScoreColor(matchScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getScoreIcon(matchScore),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Score numérico
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${matchScore.toStringAsFixed(0)}% de Compatibilidade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(matchScore),
                          ),
                        ),
                        Text(
                          _getScoreLabel(matchScore),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de qualidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(matchScore),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getScoreBadge(matchScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barra de progresso visual
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: matchScore / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(matchScore)),
                  minHeight: 12,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Explicação da IA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.purple[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiReason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmBreakdown(BuildContext context) {
    final factors = [
      {
        'name': 'Especialização',
        'weight': contextualData?['specialization_weight'] ?? 35.0,
        'score': contextualData?['specialization_score'] ?? 95.0,
        'icon': Icons.psychology_outlined,
        'color': Colors.blue,
      },
      {
        'name': 'Experiência',
        'weight': contextualData?['experience_weight'] ?? 25.0,
        'score': contextualData?['experience_score'] ?? 88.0,
        'icon': Icons.military_tech_outlined,
        'color': Colors.green,
      },
      {
        'name': 'Localização',
        'weight': contextualData?['location_weight'] ?? 20.0,
        'score': contextualData?['location_score'] ?? 92.0,
        'icon': Icons.location_on_outlined,
        'color': Colors.orange,
      },
      {
        'name': 'Disponibilidade',
        'weight': contextualData?['availability_weight'] ?? 15.0,
        'score': contextualData?['availability_score'] ?? 100.0,
        'icon': Icons.schedule_outlined,
        'color': Colors.purple,
      },
      {
        'name': 'Avaliações',
        'weight': contextualData?['rating_weight'] ?? 5.0,
        'score': contextualData?['rating_score'] ?? 96.0,
        'icon': Icons.star_outline,
        'color': Colors.amber,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como Calculamos Seu Match',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: factors.map((factor) {
              final weight = factor['weight'] as double;
              final score = factor['score'] as double;
              final name = factor['name'] as String;
              final icon = factor['icon'] as IconData;
              final color = factor['color'] as Color;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Peso: ${weight.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityFactors(BuildContext context) {
    final strengths = contextualData?['strengths'] ?? [
      'Especialista em Direito Trabalhista',
      'Experiência com casos similares',
      'Localização estratégica',
      'Alta taxa de sucesso'
    ];
    
    final improvements = contextualData?['improvements'] ?? [
      'Tempo de resposta pode ser otimizado'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fatores de Compatibilidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Pontos fortes
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pontos Fortes do Match',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...strengths.map<Widget>((strength) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        strength,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Pontos de melhoria (se houver)
        if (improvements.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[25],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Oportunidades de Melhoria',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...improvements.map<Widget>((improvement) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, color: Colors.orange[600], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          improvement,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAIInsights(BuildContext context) {
    final clientProfile = contextualData?['client_profile'] ?? 'Empresarial';
    final caseComplexity = contextualData?['case_complexity'] ?? 'Média';
    final successProbability = contextualData?['success_probability'] ?? 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights da IA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Análise Preditiva do Caso',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      'Perfil do Cliente',
                      clientProfile,
                      Icons.person_outline,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      'Complexidade',
                      caseComplexity,
                      Icons.trending_up_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.purple[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Probabilidade de Sucesso: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(successProbability * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getSuccessProbabilityColor(successProbability),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildMatchActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback do Match',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Match Perfeito',
                icon: Icons.thumb_up_outlined,
                onPressed: () => _provideFeedback(context, 'excellent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Pode Melhorar',
                icon: Icons.thumb_down_outlined,
                onPressed: () => _provideFeedback(context, 'poor'),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Sugerir Melhoria no Algoritmo',
            icon: Icons.science_outlined,
            onPressed: () => _suggestImprovement(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _provideFeedback(BuildContext context, String feedbackType) {
    final message = feedbackType == 'excellent' 
        ? 'Obrigado! Seu feedback ajuda a melhorar nosso algoritmo.'
        : 'Obrigado pelo feedback. Vamos analisar e melhorar o match.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: feedbackType == 'excellent' ? Colors.green : Colors.orange,
      ),
    );
  }

  void _suggestImprovement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sugerir Melhoria'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Como podemos melhorar o algoritmo de match para você?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Digite sua sugestão...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sugestão enviada! Obrigado pelo feedback.'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // Métodos de apoio para cores e ícones
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 90) return Icons.emoji_events;
    if (score >= 75) return Icons.star;
    if (score >= 60) return Icons.thumb_up;
    return Icons.trending_down;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Match Excepcional';
    if (score >= 75) return 'Match Muito Bom';
    if (score >= 60) return 'Match Adequado';
    return 'Match Baixo';
  }

  String _getScoreBadge(double score) {
    if (score >= 90) return 'PERFEITO';
    if (score >= 75) return 'ÓTIMO';
    if (score >= 60) return 'BOM';
    return 'REGULAR';
  }

  Color _getSuccessProbabilityColor(double probability) {
    if (probability >= 0.8) return Colors.green;
    if (probability >= 0.6) return Colors.orange;
    return Colors.red;
  }
} 
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Explicação do Match para advogados/escritórios
/// 
/// **Contexto:** Todos os perfis EXCETO Advogados Associados
/// **Perfis que veem:** lawyer_individual, lawyer_office, lawyer_platform_associate
/// **Foco:** Transparência sobre por que foram selecionados pelo algoritmo
/// 
/// Conforme solicitação: todos os advogados/escritórios devem ver a explicação
/// do match, exceto os associados (que recebem por delegação interna)
class MatchExplanationSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const MatchExplanationSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Explicação do Match',
      children: [
        _buildMatchScore(context),
        const SizedBox(height: 16),
        _buildAlgorithmBreakdown(context),
        const SizedBox(height: 16),
        _buildCompatibilityFactors(context),
        const SizedBox(height: 16),
        _buildAIInsights(context),
        const SizedBox(height: 20),
        _buildMatchActions(context),
      ],
    );
  }

  Widget _buildMatchScore(BuildContext context) {
    final matchScore = contextualData?['match_score'] ?? 94.0;
    final aiReason = contextualData?['ai_reason'] ?? 
        'Alta compatibilidade entre sua especialização e o caso do cliente';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score de Compatibilidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Score visual principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getScoreColor(matchScore).withOpacity(0.1),
                _getScoreColor(matchScore).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getScoreColor(matchScore).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Ícone do score
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getScoreColor(matchScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getScoreIcon(matchScore),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Score numérico
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${matchScore.toStringAsFixed(0)}% de Compatibilidade',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(matchScore),
                          ),
                        ),
                        Text(
                          _getScoreLabel(matchScore),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de qualidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(matchScore),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getScoreBadge(matchScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barra de progresso visual
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: matchScore / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(matchScore)),
                  minHeight: 12,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Explicação da IA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.purple[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiReason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmBreakdown(BuildContext context) {
    final factors = [
      {
        'name': 'Especialização',
        'weight': contextualData?['specialization_weight'] ?? 35.0,
        'score': contextualData?['specialization_score'] ?? 95.0,
        'icon': Icons.psychology_outlined,
        'color': Colors.blue,
      },
      {
        'name': 'Experiência',
        'weight': contextualData?['experience_weight'] ?? 25.0,
        'score': contextualData?['experience_score'] ?? 88.0,
        'icon': Icons.military_tech_outlined,
        'color': Colors.green,
      },
      {
        'name': 'Localização',
        'weight': contextualData?['location_weight'] ?? 20.0,
        'score': contextualData?['location_score'] ?? 92.0,
        'icon': Icons.location_on_outlined,
        'color': Colors.orange,
      },
      {
        'name': 'Disponibilidade',
        'weight': contextualData?['availability_weight'] ?? 15.0,
        'score': contextualData?['availability_score'] ?? 100.0,
        'icon': Icons.schedule_outlined,
        'color': Colors.purple,
      },
      {
        'name': 'Avaliações',
        'weight': contextualData?['rating_weight'] ?? 5.0,
        'score': contextualData?['rating_score'] ?? 96.0,
        'icon': Icons.star_outline,
        'color': Colors.amber,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como Calculamos Seu Match',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: factors.map((factor) {
              final weight = factor['weight'] as double;
              final score = factor['score'] as double;
              final name = factor['name'] as String;
              final icon = factor['icon'] as IconData;
              final color = factor['color'] as Color;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Peso: ${weight.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityFactors(BuildContext context) {
    final strengths = contextualData?['strengths'] ?? [
      'Especialista em Direito Trabalhista',
      'Experiência com casos similares',
      'Localização estratégica',
      'Alta taxa de sucesso'
    ];
    
    final improvements = contextualData?['improvements'] ?? [
      'Tempo de resposta pode ser otimizado'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fatores de Compatibilidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Pontos fortes
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pontos Fortes do Match',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...strengths.map<Widget>((strength) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        strength,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Pontos de melhoria (se houver)
        if (improvements.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[25],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Oportunidades de Melhoria',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...improvements.map<Widget>((improvement) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_right, color: Colors.orange[600], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          improvement,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAIInsights(BuildContext context) {
    final clientProfile = contextualData?['client_profile'] ?? 'Empresarial';
    final caseComplexity = contextualData?['case_complexity'] ?? 'Média';
    final successProbability = contextualData?['success_probability'] ?? 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights da IA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Análise Preditiva do Caso',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      'Perfil do Cliente',
                      clientProfile,
                      Icons.person_outline,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      'Complexidade',
                      caseComplexity,
                      Icons.trending_up_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.purple[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Probabilidade de Sucesso: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(successProbability * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getSuccessProbabilityColor(successProbability),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildMatchActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback do Match',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Match Perfeito',
                icon: Icons.thumb_up_outlined,
                onPressed: () => _provideFeedback(context, 'excellent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Pode Melhorar',
                icon: Icons.thumb_down_outlined,
                onPressed: () => _provideFeedback(context, 'poor'),
                isOutlined: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: buildActionButton(
            label: 'Sugerir Melhoria no Algoritmo',
            icon: Icons.science_outlined,
            onPressed: () => _suggestImprovement(context),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _provideFeedback(BuildContext context, String feedbackType) {
    final message = feedbackType == 'excellent' 
        ? 'Obrigado! Seu feedback ajuda a melhorar nosso algoritmo.'
        : 'Obrigado pelo feedback. Vamos analisar e melhorar o match.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: feedbackType == 'excellent' ? Colors.green : Colors.orange,
      ),
    );
  }

  void _suggestImprovement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sugerir Melhoria'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Como podemos melhorar o algoritmo de match para você?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Digite sua sugestão...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sugestão enviada! Obrigado pelo feedback.'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // Métodos de apoio para cores e ícones
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 90) return Icons.emoji_events;
    if (score >= 75) return Icons.star;
    if (score >= 60) return Icons.thumb_up;
    return Icons.trending_down;
  }

  String _getScoreLabel(double score) {
    if (score >= 90) return 'Match Excepcional';
    if (score >= 75) return 'Match Muito Bom';
    if (score >= 60) return 'Match Adequado';
    return 'Match Baixo';
  }

  String _getScoreBadge(double score) {
    if (score >= 90) return 'PERFEITO';
    if (score >= 75) return 'ÓTIMO';
    if (score >= 60) return 'BOM';
    return 'REGULAR';
  }

  Color _getSuccessProbabilityColor(double probability) {
    if (probability >= 0.8) return Colors.green;
    if (probability >= 0.6) return Colors.orange;
    return Colors.red;
  }
} 