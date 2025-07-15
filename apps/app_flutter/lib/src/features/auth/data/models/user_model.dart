import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    super.fullName,
    super.role,
    super.userRole,
    super.permissions = const [],
    super.metadata,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromSupabase(supabase.User supabaseUser) {
    // Extrair role corretamente baseado no user_type
    String? userRole;
    final userType = supabaseUser.userMetadata?['user_type'];
    
    if (userType == 'LAWYER') {
      // Para advogados, usar o campo 'role' específico
      userRole = supabaseUser.userMetadata?['role'];
    } else {
      // Para clientes, usar o user_type diretamente
      userRole = userType;
    }
    
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email,
      fullName: supabaseUser.userMetadata?['full_name'],
      role: userRole,
    );
  }
} 