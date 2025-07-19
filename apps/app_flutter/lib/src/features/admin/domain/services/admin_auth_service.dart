import 'package:equatable/equatable.dart';

/// Serviço de Autenticação Administrativa
/// 
/// Gerencia permissões e acesso às funcionalidades administrativas
class AdminAuthService {
  static const List<String> _adminRoles = [
    'admin',
    'super_admin',
    'system_admin',
  ];

  static const List<String> _adminPermissions = [
    'admin.dashboard.view',
    'admin.metrics.view',
    'admin.audit.view',
    'admin.reports.generate',
    'admin.settings.edit',
    'admin.users.manage',
    'admin.system.configure',
    'admin.backup.manage',
    'admin.security.configure',
  ];

  /// Verifica se o usuário tem acesso administrativo
  static bool hasAdminAccess(String userRole) {
    return _adminRoles.contains(userRole);
  }

  /// Verifica se o usuário tem uma permissão específica
  static bool hasPermission(String userRole, String permission) {
    if (!hasAdminAccess(userRole)) return false;
    
    // Super admin tem todas as permissões
    if (userRole == 'super_admin') return true;
    
    // Mapeamento de permissões por role
    final rolePermissions = <String, List<String>>{
      'admin': [
        'admin.dashboard.view',
        'admin.metrics.view',
        'admin.audit.view',
        'admin.reports.generate',
      ],
      'system_admin': [
        'admin.dashboard.view',
        'admin.metrics.view',
        'admin.audit.view',
        'admin.reports.generate',
        'admin.settings.edit',
        'admin.system.configure',
        'admin.backup.manage',
        'admin.security.configure',
      ],
    };
    
    return rolePermissions[userRole]?.contains(permission) ?? false;
  }

  /// Retorna todas as permissões do usuário
  static List<String> getUserPermissions(String userRole) {
    if (!hasAdminAccess(userRole)) return [];
    
    if (userRole == 'super_admin') return _adminPermissions;
    
    final rolePermissions = <String, List<String>>{
      'admin': [
        'admin.dashboard.view',
        'admin.metrics.view',
        'admin.audit.view',
        'admin.reports.generate',
      ],
      'system_admin': [
        'admin.dashboard.view',
        'admin.metrics.view',
        'admin.audit.view',
        'admin.reports.generate',
        'admin.settings.edit',
        'admin.system.configure',
        'admin.backup.manage',
        'admin.security.configure',
      ],
    };
    
    return rolePermissions[userRole] ?? [];
  }

  /// Verifica se o usuário pode acessar uma rota administrativa
  static bool canAccessRoute(String userRole, String route) {
    final routePermissions = <String, String>{
      '/admin': 'admin.dashboard.view',
      '/admin/metrics': 'admin.metrics.view',
      '/admin/audit': 'admin.audit.view',
      '/admin/reports': 'admin.reports.generate',
      '/admin/settings': 'admin.settings.edit',
    };
    
    final requiredPermission = routePermissions[route];
    if (requiredPermission == null) return false;
    
    return hasPermission(userRole, requiredPermission);
  }

  /// Retorna as rotas que o usuário pode acessar
  static List<String> getAccessibleRoutes(String userRole) {
    final allRoutes = [
      '/admin',
      '/admin/metrics',
      '/admin/audit',
      '/admin/reports',
      '/admin/settings',
    ];
    
    return allRoutes.where((route) => canAccessRoute(userRole, route)).toList();
  }

  /// Valida se uma ação administrativa é permitida
  static bool canPerformAction(String userRole, String action) {
    final actionPermissions = <String, String>{
      'generate_report': 'admin.reports.generate',
      'view_metrics': 'admin.metrics.view',
      'view_audit_logs': 'admin.audit.view',
      'edit_settings': 'admin.settings.edit',
      'manage_backup': 'admin.backup.manage',
      'configure_security': 'admin.security.configure',
      'configure_system': 'admin.system.configure',
    };
    
    final requiredPermission = actionPermissions[action];
    if (requiredPermission == null) return false;
    
    return hasPermission(userRole, requiredPermission);
  }
}

/// Entidade de Permissão Administrativa
class AdminPermission extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isEnabled;

  const AdminPermission({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isEnabled = true,
  });

  @override
  List<Object?> get props => [id, name, description, category, isEnabled];
}

/// Entidade de Role Administrativa
class AdminRole extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool isActive;

  const AdminRole({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, description, permissions, isActive];
} 