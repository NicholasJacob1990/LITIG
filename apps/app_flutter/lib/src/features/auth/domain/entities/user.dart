import 'package:equatable/equatable.dart';

/// Entidade que representa um usuário no sistema
/// Atualizada para incluir permissões baseadas em perfil
class User extends Equatable {
  final String id;
  final String? email;
  final String? fullName;
  final String? role;
  final String? userRole; // Novo campo para tipo específico de usuário
  final List<String> permissions; // Novo campo para permissões
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.email,
    this.fullName,
    this.role,
    this.userRole,
    this.permissions = const [],
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  /// Cria uma cópia do usuário com campos atualizados
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? userRole,
    List<String>? permissions,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      userRole: userRole ?? this.userRole,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o usuário tem uma permissão específica
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Verifica se o usuário tem alguma das permissões fornecidas
  bool hasAnyPermission(List<String> permissionList) {
    return permissionList.any((permission) => permissions.contains(permission));
  }

  /// Verifica se o usuário tem todas as permissões fornecidas
  bool hasAllPermissions(List<String> permissionList) {
    return permissionList.every((permission) => permissions.contains(permission));
  }

  /// Retorna o tipo de usuário específico (userRole) ou role como fallback
  String get effectiveUserRole => userRole ?? role ?? 'client';

  /// Verifica se o usuário é cliente
  bool get isClient => effectiveUserRole == 'client';

  /// Verifica se o usuário é advogado associado
  bool get isAssociatedLawyer => effectiveUserRole == 'lawyer_associated';

  /// Verifica se o usuário é advogado individual
  bool get isIndividualLawyer => effectiveUserRole == 'lawyer_individual';

  /// Verifica se o usuário é escritório
  bool get isLawOffice => effectiveUserRole == 'lawyer_office';

  /// Verifica se o usuário é super associado
  bool get isPlatformAssociate => effectiveUserRole == 'lawyer_platform_associate';

  /// Verifica se o usuário é qualquer tipo de advogado
  bool get isLawyer => 
    isAssociatedLawyer || 
    isIndividualLawyer || 
    isLawOffice || 
    isPlatformAssociate;

  /// Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'userRole': userRole,
      'permissions': permissions,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Cria User a partir de Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'],
      fullName: map['fullName'] ?? map['full_name'],
      role: map['role'],
      userRole: map['userRole'] ?? map['user_role'],
      permissions: List<String>.from(map['permissions'] ?? []),
      metadata: map['metadata'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  /// Cria User vazio para loading/error states
  factory User.empty() {
    return const User(
      id: '',
      permissions: [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    userRole,
    permissions,
    metadata,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role, userRole: $userRole, permissions: $permissions)';
  }
} 