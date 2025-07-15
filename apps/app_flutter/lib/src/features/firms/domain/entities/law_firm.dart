import 'package:equatable/equatable.dart';
import 'firm_kpi.dart';

/// Entidade de domínio para Escritório de Advocacia
class LawFirm extends Equatable {
  /// Identificador único do escritório
  final String id;

  /// Nome do escritório de advocacia
  final String name;

  /// Número de advogados no escritório
  final int teamSize;

  /// Latitude da sede principal (opcional)
  final double? mainLat;

  /// Longitude da sede principal (opcional)
  final double? mainLon;

  /// Data de criação do escritório
  final DateTime? createdAt;

  /// Data da última atualização
  final DateTime? updatedAt;

  /// KPIs do escritório (opcional, carregado sob demanda)
  final FirmKPI? kpis;

  /// Contagem de advogados associados (opcional, calculado dinamicamente)
  final int? lawyersCount;

  /// Lista de especializações do escritório
  final List<String> specializations;

  /// Avaliação média do escritório (0.0 a 5.0)
  final double rating;

  /// Indica se é um escritório boutique (especializado)
  final bool isBoutique;

  const LawFirm({
    required this.id,
    required this.name,
    required this.teamSize,
    this.mainLat,
    this.mainLon,
    this.createdAt,
    this.updatedAt,
    this.kpis,
    this.lawyersCount,
    this.specializations = const [],
    this.rating = 0.0,
    this.isBoutique = false,
  });

  /// Verifica se o escritório possui localização definida
  bool get hasLocation => mainLat != null && mainLon != null;

  /// Verifica se o escritório é de grande porte (50+ advogados)
  bool get isLargeFirm => teamSize >= 50;

  /// Verifica se possui KPIs carregados
  bool get hasKpis => kpis != null;

  /// Ano de fundação baseado na data de criação (retorna null se não informado)
  int? get foundedYear => createdAt?.year;

  @override
  List<Object?> get props => [
        id,
        name,
        teamSize,
        mainLat,
        mainLon,
        createdAt,
        updatedAt,
        kpis,
        lawyersCount,
        specializations,
        rating,
        isBoutique,
      ];

  @override
  String toString() {
    return 'LawFirm(id: $id, name: $name, teamSize: $teamSize, hasLocation: $hasLocation, hasKpis: $hasKpis)';
  }

  /// Cria uma cópia da entidade com campos atualizados
  LawFirm copyWith({
    String? id,
    String? name,
    int? teamSize,
    double? mainLat,
    double? mainLon,
    DateTime? createdAt,
    DateTime? updatedAt,
    FirmKPI? kpis,
    int? lawyersCount,
    List<String>? specializations,
    double? rating,
    bool? isBoutique,
  }) {
    return LawFirm(
      id: id ?? this.id,
      name: name ?? this.name,
      teamSize: teamSize ?? this.teamSize,
      mainLat: mainLat ?? this.mainLat,
      mainLon: mainLon ?? this.mainLon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kpis: kpis ?? this.kpis,
      lawyersCount: lawyersCount ?? this.lawyersCount,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      isBoutique: isBoutique ?? this.isBoutique,
    );
  }
} 