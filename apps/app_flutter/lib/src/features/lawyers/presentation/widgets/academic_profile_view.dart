import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/academic_profile.dart';

class AcademicProfileView extends StatelessWidget {
  final AcademicProfile profile;

  const AcademicProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAcademicHeader(context),
          const SizedBox(height: 24),
          if (profile.degrees.isNotEmpty) ...[
            _buildDegreesSection(context),
            const SizedBox(height: 24),
          ],
          if (profile.publications.isNotEmpty) ...[
            _buildPublicationsSection(context),
            const SizedBox(height: 24),
          ],
          if (profile.researchAreas.isNotEmpty) ...[
            _buildResearchAreasSection(context),
            const SizedBox(height: 24),
          ],
          _buildAcademicInsights(context),
        ],
      ),
    );
  }

  Widget _buildAcademicHeader(BuildContext context) {
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
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.graduationCap,
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
                        'Perfil Acadêmico',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Formação e produção científica',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQualityChip(context),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildAcademicSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityChip(BuildContext context) {
    final percentage = (profile.dataQualityScore * 100).toInt();
    final color = _getQualityColor(profile.dataQualityScore);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Diplomas',
            profile.degrees.length.toString(),
            LucideIcons.award,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Publicações',
            profile.publications.length.toString(),
            LucideIcons.bookOpen,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Áreas de Pesquisa',
            profile.researchAreas.length.toString(),
            LucideIcons.microscope,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDegreesSection(BuildContext context) {
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
                  LucideIcons.graduationCap,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Formação Acadêmica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profile.degrees.length} ${profile.degrees.length == 1 ? 'diploma' : 'diplomas'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...profile.degrees.asMap().entries.map((entry) {
              final index = entry.key;
              final degree = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < profile.degrees.length - 1 ? 16 : 0),
                child: _buildDegreeItem(context, degree),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeItem(BuildContext context, AcademicDegree degree) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: degree.isFromTopInstitution 
                ? Colors.amber.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            degree.isFromTopInstitution ? LucideIcons.crown : LucideIcons.school,
            color: degree.isFromTopInstitution 
                ? Colors.amber[700]
                : Theme.of(context).colorScheme.onPrimaryContainer,
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
                  Expanded(
                    child: Text(
                      degree.degree,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (degree.isFromTopInstitution)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'TOP',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                degree.institution,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                degree.fieldOfStudy,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (degree.conclusionYear != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Concluído em ${degree.conclusionYear}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicationsSection(BuildContext context) {
    final totalCitations = profile.publications
        .where((pub) => pub.citationCount != null)
        .fold<int>(0, (sum, pub) => sum + pub.citationCount!);

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
                  LucideIcons.bookOpen,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Produção Científica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (totalCitations > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCitations citações',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...profile.publications.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final publication = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                child: _buildPublicationItem(context, publication),
              );
            }),
            if (profile.publications.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _showAllPublications(context),
                  child: Text('Ver todas as ${profile.publications.length} publicações'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationItem(BuildContext context, AcademicPublication publication) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publication.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            publication.journalOrConference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (publication.year != null) ...[
                Icon(LucideIcons.calendar, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  publication.year.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (publication.year != null && publication.citationCount != null)
                const SizedBox(width: 16),
              if (publication.citationCount != null) ...[
                Icon(LucideIcons.quote, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${publication.citationCount} citações',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const Spacer(),
              if (publication.publicationUrl != null)
                Icon(LucideIcons.externalLink, size: 12, color: Colors.grey[500]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResearchAreasSection(BuildContext context) {
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
                  LucideIcons.microscope,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Áreas de Pesquisa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.researchAreas.map((area) => _buildResearchAreaChip(context, area)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchAreaChip(BuildContext context, String area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        area,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAcademicInsights(BuildContext context) {
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
                  LucideIcons.lightbulb,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights Acadêmicos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              context,
              'Instituições de Prestígio',
              '${profile.degrees.where((d) => d.isFromTopInstitution).length} de ${profile.degrees.length} diplomas',
              LucideIcons.crown,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Impacto Acadêmico',
              profile.publications.isNotEmpty 
                  ? 'Média de ${_calculateAverageCitations().toStringAsFixed(1)} citações por publicação'
                  : 'Sem dados de publicações',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Diversidade de Pesquisa',
              '${profile.researchAreas.length} ${profile.researchAreas.length == 1 ? 'área' : 'áreas'} de especialização',
              LucideIcons.target,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
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

  void _showAllPublications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Todas as Publicações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: profile.publications.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPublicationItem(context, profile.publications[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  double _calculateAverageCitations() {
    final publicationsWithCitations = profile.publications
        .where((pub) => pub.citationCount != null && pub.citationCount! > 0);
    
    if (publicationsWithCitations.isEmpty) return 0;
    
    final totalCitations = publicationsWithCitations
        .fold<int>(0, (sum, pub) => sum + pub.citationCount!);
    
    return totalCitations / publicationsWithCitations.length;
  }
} 
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/academic_profile.dart';

class AcademicProfileView extends StatelessWidget {
  final AcademicProfile profile;

  const AcademicProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAcademicHeader(context),
          const SizedBox(height: 24),
          if (profile.degrees.isNotEmpty) ...[
            _buildDegreesSection(context),
            const SizedBox(height: 24),
          ],
          if (profile.publications.isNotEmpty) ...[
            _buildPublicationsSection(context),
            const SizedBox(height: 24),
          ],
          if (profile.researchAreas.isNotEmpty) ...[
            _buildResearchAreasSection(context),
            const SizedBox(height: 24),
          ],
          _buildAcademicInsights(context),
        ],
      ),
    );
  }

  Widget _buildAcademicHeader(BuildContext context) {
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
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.graduationCap,
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
                        'Perfil Acadêmico',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Formação e produção científica',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQualityChip(context),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildAcademicSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityChip(BuildContext context) {
    final percentage = (profile.dataQualityScore * 100).toInt();
    final color = _getQualityColor(profile.dataQualityScore);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Diplomas',
            profile.degrees.length.toString(),
            LucideIcons.award,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Publicações',
            profile.publications.length.toString(),
            LucideIcons.bookOpen,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            context,
            'Áreas de Pesquisa',
            profile.researchAreas.length.toString(),
            LucideIcons.microscope,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDegreesSection(BuildContext context) {
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
                  LucideIcons.graduationCap,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Formação Acadêmica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profile.degrees.length} ${profile.degrees.length == 1 ? 'diploma' : 'diplomas'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...profile.degrees.asMap().entries.map((entry) {
              final index = entry.key;
              final degree = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < profile.degrees.length - 1 ? 16 : 0),
                child: _buildDegreeItem(context, degree),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeItem(BuildContext context, AcademicDegree degree) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: degree.isFromTopInstitution 
                ? Colors.amber.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            degree.isFromTopInstitution ? LucideIcons.crown : LucideIcons.school,
            color: degree.isFromTopInstitution 
                ? Colors.amber[700]
                : Theme.of(context).colorScheme.onPrimaryContainer,
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
                  Expanded(
                    child: Text(
                      degree.degree,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (degree.isFromTopInstitution)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'TOP',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                degree.institution,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                degree.fieldOfStudy,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (degree.conclusionYear != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Concluído em ${degree.conclusionYear}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicationsSection(BuildContext context) {
    final totalCitations = profile.publications
        .where((pub) => pub.citationCount != null)
        .fold<int>(0, (sum, pub) => sum + pub.citationCount!);

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
                  LucideIcons.bookOpen,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Produção Científica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (totalCitations > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCitations citações',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...profile.publications.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final publication = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                child: _buildPublicationItem(context, publication),
              );
            }),
            if (profile.publications.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _showAllPublications(context),
                  child: Text('Ver todas as ${profile.publications.length} publicações'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationItem(BuildContext context, AcademicPublication publication) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publication.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            publication.journalOrConference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (publication.year != null) ...[
                Icon(LucideIcons.calendar, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  publication.year.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (publication.year != null && publication.citationCount != null)
                const SizedBox(width: 16),
              if (publication.citationCount != null) ...[
                Icon(LucideIcons.quote, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${publication.citationCount} citações',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const Spacer(),
              if (publication.publicationUrl != null)
                Icon(LucideIcons.externalLink, size: 12, color: Colors.grey[500]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResearchAreasSection(BuildContext context) {
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
                  LucideIcons.microscope,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Áreas de Pesquisa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.researchAreas.map((area) => _buildResearchAreaChip(context, area)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchAreaChip(BuildContext context, String area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        area,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAcademicInsights(BuildContext context) {
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
                  LucideIcons.lightbulb,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights Acadêmicos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              context,
              'Instituições de Prestígio',
              '${profile.degrees.where((d) => d.isFromTopInstitution).length} de ${profile.degrees.length} diplomas',
              LucideIcons.crown,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Impacto Acadêmico',
              profile.publications.isNotEmpty 
                  ? 'Média de ${_calculateAverageCitations().toStringAsFixed(1)} citações por publicação'
                  : 'Sem dados de publicações',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              context,
              'Diversidade de Pesquisa',
              '${profile.researchAreas.length} ${profile.researchAreas.length == 1 ? 'área' : 'áreas'} de especialização',
              LucideIcons.target,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
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

  void _showAllPublications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Todas as Publicações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: profile.publications.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPublicationItem(context, profile.publications[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  double _calculateAverageCitations() {
    final publicationsWithCitations = profile.publications
        .where((pub) => pub.citationCount != null && pub.citationCount! > 0);
    
    if (publicationsWithCitations.isEmpty) return 0;
    
    final totalCitations = publicationsWithCitations
        .fold<int>(0, (sum, pub) => sum + pub.citationCount!);
    
    return totalCitations / publicationsWithCitations.length;
  }
} 