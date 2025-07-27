import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/data_source_info.dart';

class DataTransparencyView extends StatelessWidget {
  final Map<String, DataSourceInfo> dataSources;
  final double qualityScore;
  final DateTime lastUpdated;

  const DataTransparencyView({
    super.key,
    required this.dataSources,
    required this.qualityScore,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransparencyHeader(context),
          const SizedBox(height: 24),
          _buildOverallQuality(context),
          const SizedBox(height: 24),
          _buildDataSources(context),
          const SizedBox(height: 24),
          _buildDataPolicy(context),
          const SizedBox(height: 24),
          _buildLastUpdated(context),
        ],
      ),
    );
  }

  Widget _buildTransparencyHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transparência dos Dados',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Origem e qualidade das informações',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Comprometemo-nos com a transparência total sobre como coletamos e processamos os dados dos profissionais. Todas as informações são verificadas e atualizadas regularmente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallQuality(BuildContext context) {
    final percentage = (qualityScore * 100).toInt();
    final color = _getQualityColor(qualityScore);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Qualidade Geral dos Dados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score de Qualidade',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: qualityScore,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
            const SizedBox(height: 16),
            Text(
              _getQualityDescription(qualityScore),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSources(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.database,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fontes de Dados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dataSources.length} ${dataSources.length == 1 ? 'fonte' : 'fontes'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dataSources.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDataSourceItem(context, entry.key, entry.value),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceItem(BuildContext context, String sourceName, DataSourceInfo sourceInfo) {
    final sourceColor = sourceInfo.hasError ? Colors.red : _getQualityColor(sourceInfo.qualityScore);
    final sourceIcon = _getSourceIcon(sourceName);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sourceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sourceIcon,
              color: sourceColor,
              size: 20,
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
                      _getSourceDisplayName(sourceName),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!sourceInfo.hasError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sourceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(sourceInfo.qualityScore * 100).toInt()}%',
                          style: TextStyle(
                            color: sourceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (sourceInfo.hasError) ...[
                  Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sourceInfo.errorMessage ?? 'Erro ao carregar dados',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Atualizado ${_formatRelativeTime(sourceInfo.lastUpdated)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPolicy(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Política de Dados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPolicyItem(
              context,
              'Coleta de Dados',
              'Coletamos apenas informações públicas e profissionais disponibilizadas pelos próprios advogados.',
              LucideIcons.userCheck,
            ),
            const SizedBox(height: 12),
            _buildPolicyItem(
              context,
              'Verificação',
              'Todos os dados passam por processo de verificação automática e manual antes da publicação.',
              LucideIcons.shieldCheck,
            ),
            const SizedBox(height: 12),
            _buildPolicyItem(
              context,
              'Atualização',
              'Os dados são atualizados regularmente para garantir precisão e relevância.',
              LucideIcons.refreshCw,
            ),
            const SizedBox(height: 12),
            _buildPolicyItem(
              context,
              'Privacidade',
              'Respeitamos totalmente a LGPD e políticas de privacidade das plataformas de origem.',
              LucideIcons.lock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Última Atualização',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(lastUpdated),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _requestDataUpdate(context),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Solicitar Atualização'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getQualityDescription(double score) {
    if (score >= 0.9) return 'Excelente: Dados completos e verificados de múltiplas fontes confiáveis.';
    if (score >= 0.8) return 'Muito Bom: Dados majoritariamente completos com algumas informações em falta.';
    if (score >= 0.6) return 'Bom: Dados básicos disponíveis, algumas informações podem estar desatualizadas.';
    if (score >= 0.4) return 'Regular: Dados limitados, recomendamos verificação adicional.';
    return 'Baixo: Poucos dados disponíveis, use com cautela.';
  }

  IconData _getSourceIcon(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'perplexity':
      case 'academic':
        return LucideIcons.graduationCap;
      case 'escavador':
      case 'jusbrasil':
        return LucideIcons.gavel;
      case 'internal':
        return LucideIcons.database;
      default:
        return LucideIcons.globe;
    }
  }

  String _getSourceDisplayName(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'linkedin':
        return 'LinkedIn';
      case 'perplexity':
        return 'Perplexity Academic';
      case 'academic':
        return 'Dados Acadêmicos';
      case 'escavador':
        return 'Escavador';
      case 'jusbrasil':
        return 'JusBrasil';
      case 'internal':
        return 'Base Interna';
      default:
        return sourceName;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Hoje às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dias';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays} dias';
    } else {
      return 'há ${(difference.inDays / 7).floor()} semanas';
    }
  }

  void _requestDataUpdate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitação de atualização enviada. Os dados serão atualizados em breve.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
} 