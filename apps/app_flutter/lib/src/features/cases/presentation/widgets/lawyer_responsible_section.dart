import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/widgets/atoms/initials_avatar.dart';
import '../../../lawyers/presentation/widgets/lawyer_social_links.dart';

class LawyerResponsibleSection extends StatelessWidget {
  final LawyerInfo? lawyer;
  
  const LawyerResponsibleSection({
    super.key,
    this.lawyer,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final chipBg = Theme.of(context).chipTheme.backgroundColor;
    
    if (lawyer == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aguardando designação',
                        style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Advogado será designado em breve', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: lawyer!.avatarUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 28,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => const CircleAvatar(
                radius: 28,
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => InitialsAvatar(
                text: lawyer!.name,
                radius: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lawyer!.name,
                      style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(lawyer!.specialty, style: t.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${lawyer!.rating}  •  ${lawyer!.experienceYears} anos'),
                      const Spacer(),
                      // Ícones das redes sociais
                      LawyerSocialLinks(
                        linkedinUrl: 'https://linkedin.com/in/${lawyer!.name.toLowerCase().replaceAll(' ', '-')}',
                        instagramUrl: 'https://instagram.com/${lawyer!.name.toLowerCase().replaceAll(' ', '')}',
                        facebookUrl: 'https://facebook.com/${lawyer!.name.toLowerCase().replaceAll(' ', '.')}',
                      ),
                    ],
                  ),
                  if (!lawyer!.isAvailable) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Indisponível',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                _ActionChip(
                  icon: Icons.chat_bubble_outline, 
                  label: 'Chat', 
                  bg: chipBg!,
                  onTap: lawyer!.isAvailable ? () => _openChat(context) : null,
                ),
                const SizedBox(height: 8),
                _ActionChip(
                  icon: Icons.videocam, 
                  label: 'Vídeo', 
                  bg: chipBg,
                  onTap: lawyer!.isAvailable ? () => _openVideo(context) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _openChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrindo chat com o advogado...')),
    );
  }
  
  void _openVideo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando videochamada...')),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon, 
    required this.label, 
    required this.bg,
    this.onTap,
  });
  
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: bg,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onPressed: onTap,
      disabledColor: bg.withValues(alpha: 0.5),
    );
  }
} 