import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  final String text;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.text,
    this.radius = 24,
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