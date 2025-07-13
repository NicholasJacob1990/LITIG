import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
    super.role,
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
      email: supabaseUser.email ?? '',
      name: supabaseUser.userMetadata?['full_name'],
      avatarUrl: supabaseUser.userMetadata?['avatar_url'],
      role: userRole,
    );
  }
} 