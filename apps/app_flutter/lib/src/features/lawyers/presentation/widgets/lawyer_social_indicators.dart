import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';


/// Classe para dados sociais do advogado
class LawyerSocialData {
  final Map<String, bool> connectedNetworks;
  final double socialScore;
  final int followersCount;
  final int connectionsCount;
  
  const LawyerSocialData({
    required this.connectedNetworks,
    required this.socialScore,
    required this.followersCount,
    required this.connectionsCount,
  });
}

/// Widget que mostra indicadores de redes sociais nos cards de advogados
/// 
/// Exibe ícones das redes sociais conectadas e score social
class LawyerSocialIndicators extends StatelessWidget {
  final String lawyerId;
  final LawyerSocialData? socialData;
  final bool showScore;
  final bool isCompact;

  const LawyerSocialIndicators({
    super.key,
    required this.lawyerId,
    this.socialData,
    this.showScore = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (socialData == null) {
      return const SizedBox.shrink();
    }

    return isCompact ? _buildCompactView() : _buildFullView();
  }

  Widget _buildCompactView() {
    final platforms = _getConnectedPlatforms();
    
    if (platforms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...platforms.take(3).map((platform) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getPlatformColor(platform),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getPlatformIcon(platform),
              color: Colors.white,
              size: 12,
            ),
          ),
        )),
        if (platforms.length > 3)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '+${platforms.length - 3}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformIcons(),
          if (showScore && socialData!.overallScore > 0) ...[
            const SizedBox(height: 8),
            _buildSocialScore(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformIcons() {
    final platforms = _getConnectedPlatforms();
    
    if (platforms.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.share,
            color: Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Sem redes conectadas',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        ...platforms.map((platform) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getPlatformColor(platform).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getPlatformColor(platform).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _getPlatformIcon(platform),
              color: _getPlatformColor(platform),
              size: 14,
            ),
          ),
        )),
        const Spacer(),
        Text(
          '${platforms.length} rede${platforms.length > 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialScore() {
    final score = socialData!.overallScore;
    final rating = socialData!.scoreRating;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getScoreColor(score).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getScoreColor(score).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getScoreIcon(score),
                color: _getScoreColor(score),
                size: 10,
              ),
              const SizedBox(width: 2),
              Text(
                rating,
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<String> _getConnectedPlatforms() {
    final platforms = <String>[];
    
    if (socialData!.hasLinkedIn) platforms.add('linkedin');
    if (socialData!.hasInstagram) platforms.add('instagram');
    if (socialData!.hasFacebook) platforms.add('facebook');
    
    return platforms;
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'instagram':
        return LucideIcons.instagram;
      case 'facebook':
        return LucideIcons.facebook;
      default:
        return Icons.share;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.yellow[700]!;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 0.8) return Icons.star;
    if (score >= 0.6) return Icons.trending_up;
    if (score >= 0.4) return Icons.trending_flat;
    return Icons.trending_down;
  }
}

/// Widget para mostrar um preview detalhado dos dados sociais
class LawyerSocialPreview extends StatelessWidget {
  final LawyerSocialData socialData;

  const LawyerSocialPreview({
    super.key,
    required this.socialData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildPlatformDetails(),
          if (socialData.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRecommendations(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.share,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presença Social',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                'Score: ${socialData.scoreRating} (${(socialData.overallScore * 100).toInt()}%)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformDetails() {
    return Column(
      children: [
        if (socialData.hasLinkedIn)
          _buildPlatformRow('LinkedIn', Icons.business, const Color(0xFF0A66C2)),
        if (socialData.hasInstagram)
          _buildPlatformRow('Instagram', Icons.photo_camera, const Color(0xFFE4405F)),
        if (socialData.hasFacebook)
          _buildPlatformRow('Facebook', Icons.facebook, const Color(0xFF1877F2)),
      ],
    );
  }

  Widget _buildPlatformRow(String name, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Conectado',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendações',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...socialData.recommendations.take(2).map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 