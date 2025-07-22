import 'package:flutter/material.dart';

/// Widget personalizado para ícones oficiais de redes sociais
/// Baseado nas diretrizes oficiais de marca de 2025
class OfficialSocialIcon extends StatelessWidget {
  final SocialPlatform platform;
  final double size;
  final bool isButton;
  final VoidCallback? onTap;

  const OfficialSocialIcon({
    super.key,
    required this.platform,
    this.size = 24,
    this.isButton = false,
    this.onTap,
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
    switch (platform) {
      case SocialPlatform.facebook:
        return _FacebookIcon(size: size);
      case SocialPlatform.instagram:
        return _InstagramIcon(size: size);
      case SocialPlatform.linkedin:
        return _LinkedInIcon(size: size);
      case SocialPlatform.x:
        return _XIcon(size: size);
      case SocialPlatform.whatsapp:
        return _WhatsAppIcon(size: size);
      case SocialPlatform.google:
        return _GoogleIcon(size: size);
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
}

/// Ícone oficial do Facebook
/// Baseado nas diretrizes: https://en.facebookbrand.com/
class _FacebookIcon extends StatelessWidget {
  final double size;
  
  const _FacebookIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2), // Facebook Blue oficial
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }
}

/// Ícone oficial do Instagram
/// Baseado nas diretrizes: https://about.meta.com/brand/resources/instagram/
class _InstagramIcon extends StatelessWidget {
  final double size;
  
  const _InstagramIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF58529), // Instagram Orange
            Color(0xFFDD2A7B), // Instagram Pink
            Color(0xFF8134AF), // Instagram Purple
            Color(0xFF515BD4), // Instagram Blue
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: size * 0.06,
                ),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.18,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícone oficial do LinkedIn
/// Baseado nas diretrizes: https://brand.linkedin.com/
class _LinkedInIcon extends StatelessWidget {
  final double size;
  
  const _LinkedInIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A66C2), // LinkedIn Blue oficial 2025
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }
}

/// Ícone oficial do X (ex-Twitter)
/// Baseado nas diretrizes: https://about.x.com/en/who-we-are/brand-toolkit
class _XIcon extends StatelessWidget {
  final double size;
  
  const _XIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black, // X usa preto ou branco
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Ícone oficial do WhatsApp
/// Baseado nas diretrizes oficiais do WhatsApp
class _WhatsAppIcon extends StatelessWidget {
  final double size;
  
  const _WhatsAppIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366), // WhatsApp Green oficial
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Icon(
          Icons.phone,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}

/// Ícone oficial do Google
/// Baseado nas diretrizes do Google Brand
class _GoogleIcon extends StatelessWidget {
  final double size;
  
  const _GoogleIcon({required this.size});

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

/// Classe utilitária para cores oficiais das redes sociais
class SocialMediaColors {
  static const Color facebook = Color(0xFF1877F2);
  static const Color instagram = Color(0xFFE4405F);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color x = Colors.black;
  static const Color whatsapp = Color(0xFF25D366);
  static const Color google = Color(0xFF4285F4);
  
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
    }
  }
}