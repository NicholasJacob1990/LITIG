import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget personalizado para ícones oficiais de redes sociais
/// Utiliza SVGs oficiais das marcas para maior fidelidade visual
class OfficialSocialIcon extends StatelessWidget {
  final SocialPlatform platform;
  final double size;
  final bool isButton;
  final VoidCallback? onTap;
  final Color? colorFilter;

  const OfficialSocialIcon({
    super.key,
    required this.platform,
    this.size = 24,
    this.isButton = false,
    this.onTap,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (isButton) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildIcon(),
        ),
      );
    }
    
    return _buildIcon();
  }

  Widget _buildIcon() {
    final String assetPath = _getAssetPath(platform);
    
    // Preserva as cores originais dos SVGs oficiais, a menos que seja especificamente solicitado
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: colorFilter != null 
        ? ColorFilter.mode(colorFilter!, BlendMode.srcIn)
        : null, // Não aplica filtro para preservar as cores oficiais
      fit: BoxFit.contain,
    );
  }

  String _getAssetPath(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.facebook:
        return 'assets/icons/facebook.svg';
      case SocialPlatform.instagram:
        return 'assets/icons/instagram.svg';
      case SocialPlatform.linkedin:
        return 'assets/icons/linkedin.svg';
      case SocialPlatform.x:
        // Usando LinkedIn como fallback mais apropriado para contexto profissional
        return 'assets/icons/linkedin.svg';
      case SocialPlatform.whatsapp:
        return 'assets/icons/whatsapp.svg';
      case SocialPlatform.google:
        return 'assets/icons/gmail.svg'; // Gmail representa bem o Google
      case SocialPlatform.gmail:
        return 'assets/icons/gmail.svg';
      case SocialPlatform.outlook:
        return 'assets/icons/outlook.svg';
    }
  }

  Color? _getDefaultColor(SocialPlatform platform) {
    // Esta função agora é usada apenas como referência para cores oficiais
    // Os SVGs mantêm suas cores originais por padrão
    switch (platform) {
      case SocialPlatform.facebook:
        return const Color(0xFF1877F2); // Facebook Blue oficial
      case SocialPlatform.instagram:
        return const Color(0xFFE4405F); // Instagram Pink oficial  
      case SocialPlatform.linkedin:
        return const Color(0xFF0078D4); // LinkedIn Blue oficial
      case SocialPlatform.x:
        return Colors.black; // X preto oficial
      case SocialPlatform.whatsapp:
        return const Color(0xFF25D366); // WhatsApp Green oficial
      case SocialPlatform.google:
      case SocialPlatform.gmail:
        return const Color(0xFFEA4335); // Gmail Red oficial
      case SocialPlatform.outlook:
        return const Color(0xFF0078D4); // Outlook Blue oficial
    }
  }
}

enum SocialPlatform {
  facebook,
  instagram,
  linkedin,
  x,
  whatsapp,
  google,
  gmail,
  outlook,
}

/// Classe utilitária para cores oficiais das redes sociais
class SocialMediaColors {
  static const Color facebook = Color(0xFF1877F2);
  static const Color instagram = Color(0xFFE4405F);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color x = Colors.black;
  static const Color whatsapp = Color(0xFF25D366);
  static const Color google = Color(0xFF4285F4);
  static const Color gmail = Color(0xFFEA4335);
  static const Color outlook = Color(0xFF0078D4);
  
  static Color getColor(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.facebook:
        return facebook;
      case SocialPlatform.instagram:
        return instagram;
      case SocialPlatform.linkedin:
        return linkedin;
      case SocialPlatform.x:
        return x;
      case SocialPlatform.whatsapp:
        return whatsapp;
      case SocialPlatform.google:
        return google;
      case SocialPlatform.gmail:
        return gmail;
      case SocialPlatform.outlook:
        return outlook;
    }
  }
}

/// Widget para casos especiais onde precisamos do ícone do Google com gradiente
class GoogleIcon extends StatelessWidget {
  final double size;
  
  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4), // Google Blue
                  Color(0xFFEA4335), // Google Red  
                  Color(0xFFFBBC05), // Google Yellow
                  Color(0xFF34A853), // Google Green
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
      ),
    );
  }
}