import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Classe utilitária com ícones oficiais de redes sociais
/// 
/// Fornece acesso centralizado aos ícones Font Awesome das principais
/// plataformas de redes sociais utilizadas no aplicativo.
class SocialMediaIcons {
  SocialMediaIcons._();

  // Principais redes sociais profissionais
  static const IconData linkedin = FontAwesomeIcons.linkedin;
  static const IconData linkedinIn = FontAwesomeIcons.linkedinIn;
  
  // Redes sociais visuais
  static const IconData instagram = FontAwesomeIcons.instagram;
  static const IconData youtube = FontAwesomeIcons.youtube;
  static const IconData pinterest = FontAwesomeIcons.pinterest;
  static const IconData tiktok = FontAwesomeIcons.tiktok;
  
  // Principais plataformas sociais
  static const IconData facebook = FontAwesomeIcons.facebook;
  static const IconData facebookF = FontAwesomeIcons.facebookF;
  static const IconData twitter = FontAwesomeIcons.twitter;
  static const IconData xTwitter = FontAwesomeIcons.xTwitter;
  
  // Mensageria e comunicação
  static const IconData whatsapp = FontAwesomeIcons.whatsapp;
  static const IconData telegram = FontAwesomeIcons.telegram;
  static const IconData signal = FontAwesomeIcons.signal;
  static const IconData viber = FontAwesomeIcons.viber;
  
  // Outras plataformas relevantes
  static const IconData snapchat = FontAwesomeIcons.snapchat;
  static const IconData discord = FontAwesomeIcons.discord;
  static const IconData reddit = FontAwesomeIcons.reddit;
  static const IconData tumblr = FontAwesomeIcons.tumblr;
  
  // Plataformas regionais
  static const IconData weibo = FontAwesomeIcons.weibo;
  static const IconData weixin = FontAwesomeIcons.weixin;
  
  /// Retorna o ícone apropriado baseado no nome da plataforma
  static IconData getIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return linkedin;
      case 'instagram':
        return instagram;
      case 'facebook':
        return facebook;
      case 'twitter':
      case 'x':
        return xTwitter;
      case 'whatsapp':
        return whatsapp;
      case 'youtube':
        return youtube;
      case 'telegram':
        return telegram;
      case 'tiktok':
        return tiktok;
      case 'snapchat':
        return snapchat;
      case 'discord':
        return discord;
      case 'pinterest':
        return pinterest;
      case 'reddit':
        return reddit;
      default:
        return Icons.public; // Ícone genérico para plataformas não mapeadas
    }
  }
  
  /// Retorna a cor oficial da marca baseada no nome da plataforma
  static Color getColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
      case 'x':
        return const Color(0xFF000000);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'discord':
        return const Color(0xFF5865F2);
      case 'pinterest':
        return const Color(0xFFBD081C);
      case 'reddit':
        return const Color(0xFFFF4500);
      default:
        return Colors.grey;
    }
  }
}

/// Widget exemplo de como usar os ícones de redes sociais
class SocialMediaIconExample extends StatelessWidget {
  final String platform;
  final double size;
  final bool showLabel;
  
  const SocialMediaIconExample({
    super.key,
    required this.platform,
    this.size = 24.0,
    this.showLabel = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(
          SocialMediaIcons.getIcon(platform),
          color: SocialMediaIcons.getColor(platform),
          size: size,
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            platform.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

/// Exemplo de como criar uma barra de ícones sociais
class SocialMediaBar extends StatelessWidget {
  final List<String> platforms;
  final double iconSize;
  final double spacing;
  final VoidCallback? onTap;
  
  const SocialMediaBar({
    super.key,
    required this.platforms,
    this.iconSize = 24.0,
    this.spacing = 16.0,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: platforms.map((platform) {
        return Padding(
          padding: EdgeInsets.only(
            right: platform == platforms.last ? 0 : spacing,
          ),
          child: GestureDetector(
            onTap: onTap,
            child: SocialMediaIconExample(
              platform: platform,
              size: iconSize,
            ),
          ),
        );
      }).toList(),
    );
  }
}