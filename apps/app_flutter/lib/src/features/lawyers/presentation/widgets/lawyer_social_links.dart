import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget simples que exibe apenas ícones das redes sociais com links
class LawyerSocialLinks extends StatelessWidget {
  final String? linkedinUrl;
  final String? instagramUrl;
  final String? facebookUrl;

  const LawyerSocialLinks({
    super.key,
    this.linkedinUrl,
    this.instagramUrl,
    this.facebookUrl,
  });

  @override
  Widget build(BuildContext context) {
    final links = <Widget>[];
    
    if (linkedinUrl != null && linkedinUrl!.isNotEmpty) {
      links.add(_buildIcon(LucideIcons.linkedin, const Color(0xFF0A66C2), linkedinUrl!));
    }
    
    if (instagramUrl != null && instagramUrl!.isNotEmpty) {
      links.add(_buildIcon(LucideIcons.instagram, const Color(0xFFE4405F), instagramUrl!));
    }
    
    if (facebookUrl != null && facebookUrl!.isNotEmpty) {
      links.add(_buildIcon(LucideIcons.facebook, const Color(0xFF1877F2), facebookUrl!));
    }
    
    if (links.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: links,
    );
  }

  Widget _buildIcon(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _openUrl(url),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }
} 