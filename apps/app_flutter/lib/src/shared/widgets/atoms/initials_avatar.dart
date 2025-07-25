import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InitialsAvatar extends StatelessWidget {
  final String text;
  final double radius;
  final String? avatarUrl;

  const InitialsAvatar({
    super.key,
    required this.text,
    this.radius = 24,
    this.avatarUrl,
  });

  String get _initials {
    if (text.isEmpty) return '?';
    final names = text.split(' ');
    if (names.length > 1) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return text.substring(0, 1).toUpperCase();
  }

  Color get _backgroundColor {
    // Gera uma cor consistente com base no hash do nome
    final hash = text.hashCode;
    final index = hash % Colors.primaries.length;
    return Colors.primaries[index].shade300;
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _backgroundColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: radius * 2,
              height: radius * 2,
              color: _backgroundColor,
              child: Center(
                child: SizedBox(
                  width: radius * 0.5,
                  height: radius * 0.5,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          ),
        ),
      );
    }
    
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
} 