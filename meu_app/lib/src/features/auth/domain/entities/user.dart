import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? role;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.role,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, role];
} 