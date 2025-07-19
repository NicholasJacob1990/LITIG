import 'package:equatable/equatable.dart';

class AdminDashboardData extends Equatable {
  final Map<String, dynamic> sistema;
  final Map<String, dynamic> qualidadeDados;
  final Map<String, dynamic> usuarios;
  final Map<String, dynamic> casos;
  final Map<String, dynamic> pagamentos;
  final Map<String, dynamic> auditoria;
  final Map<String, dynamic> sistemaSaude;
  final DateTime lastUpdated;

  const AdminDashboardData({
    required this.sistema,
    required this.qualidadeDados,
    required this.usuarios,
    required this.casos,
    required this.pagamentos,
    required this.auditoria,
    required this.sistemaSaude,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        sistema,
        qualidadeDados,
        usuarios,
        casos,
        pagamentos,
        auditoria,
        sistemaSaude,
        lastUpdated,
      ];

  AdminDashboardData copyWith({
    Map<String, dynamic>? sistema,
    Map<String, dynamic>? qualidadeDados,
    Map<String, dynamic>? usuarios,
    Map<String, dynamic>? casos,
    Map<String, dynamic>? pagamentos,
    Map<String, dynamic>? auditoria,
    Map<String, dynamic>? sistemaSaude,
    DateTime? lastUpdated,
  }) {
    return AdminDashboardData(
      sistema: sistema ?? this.sistema,
      qualidadeDados: qualidadeDados ?? this.qualidadeDados,
      usuarios: usuarios ?? this.usuarios,
      casos: casos ?? this.casos,
      pagamentos: pagamentos ?? this.pagamentos,
      auditoria: auditoria ?? this.auditoria,
      sistemaSaude: sistemaSaude ?? this.sistemaSaude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Getters para facilitar acesso aos dados
  int get totalAdvogados => sistema['total_advogados'] as int? ?? 0;
  int get totalClientes => sistema['total_clientes'] as int? ?? 0;
  int get totalCasos => sistema['total_casos'] as int? ?? 0;
  int get usuariosNovos30d => sistema['usuarios_novos_30d'] as int? ?? 0;
  int get casosNovos30d => sistema['casos_novos_30d'] as int? ?? 0;
  double get syncCoverage => (qualidadeDados['sync_coverage'] as double? ?? 0.0) * 100;
  double get dataQuality => (qualidadeDados['data_quality'] as double? ?? 0.0) * 100;
} 