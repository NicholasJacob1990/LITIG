import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/law_firm.dart';
import 'firm_kpi_model.dart';

part 'law_firm_model.g.dart';

/// Modelo de dados para serialização JSON da entidade LawFirm
/// 
/// Este modelo é responsável por converter os dados da API REST
/// para a entidade de domínio e vice-versa.
@JsonSerializable()
class LawFirmModel {
  const LawFirmModel({
    required this.id,
    required this.name,
    this.teamSize,
    this.createdAt,
    this.updatedAt,
    this.mainLat,
    this.mainLon,
    this.kpis,
    this.lawyersCount,
    this.specializations = const [],
    this.rating = 0.0,
    this.isBoutique = false,
  });

  /// Identificador único do escritório
  final String id;

  /// Nome do escritório de advocacia
  final String name;

  /// Número de advogados no escritório
  final int? teamSize;

  /// Latitude da sede principal (opcional)
  final double? mainLat;

  /// Longitude da sede principal (opcional)
  final double? mainLon;

  /// Data de criação do escritório
  final DateTime? createdAt;

  /// Data da última atualização
  final DateTime? updatedAt;

  /// KPIs do escritório (opcional, carregado sob demanda)
  final FirmKPIModel? kpis;

  /// Contagem de advogados associados (opcional, calculado dinamicamente)
  final int? lawyersCount;

  /// Lista de especializações do escritório
  final List<String> specializations;

  /// Avaliação média do escritório (0.0 a 5.0)
  final double rating;

  /// Indica se é um escritório boutique (especializado)
  final bool isBoutique;

  /// Cria uma instância a partir de um Map JSON
  factory LawFirmModel.fromJson(Map<String, dynamic> json) => _$LawFirmModelFromJson(json);

  /// Converte a instância para um Map JSON
  Map<String, dynamic> toJson() => _$LawFirmModelToJson(this);

  /// Converte o modelo para a entidade de domínio
  LawFirm toEntity() {
    return LawFirm(
      id: id,
      name: name,
      teamSize: teamSize ?? 0,
      mainLat: mainLat,
      mainLon: mainLon,
      createdAt: createdAt,
      updatedAt: updatedAt,
      kpis: kpis?.toEntity(),
      lawyersCount: lawyersCount,
      specializations: specializations,
      rating: rating,
      isBoutique: isBoutique,
    );
  }

  /// Cria um modelo a partir da entidade de domínio
  factory LawFirmModel.fromEntity(LawFirm entity) {
    return LawFirmModel(
      id: entity.id,
      name: entity.name,
      teamSize: entity.teamSize,
      mainLat: entity.mainLat,
      mainLon: entity.mainLon,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      kpis: entity.kpis != null ? FirmKPIModel.fromEntity(entity.kpis!) : null,
      lawyersCount: entity.lawyersCount,
      specializations: entity.specializations,
      rating: entity.rating,
      isBoutique: entity.isBoutique,
    );
  }

  /// Cria um modelo com campos atualizados
  LawFirmModel copyWith({
    String? id,
    String? name,
    int? teamSize,
    double? mainLat,
    double? mainLon,
    DateTime? createdAt,
    DateTime? updatedAt,
    FirmKPIModel? kpis,
    int? lawyersCount,
    List<String>? specializations,
    double? rating,
    bool? isBoutique,
  }) {
    return LawFirmModel(
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

  /// Verifica se o escritório possui localização definida
  bool get hasLocation => mainLat != null && mainLon != null;

  /// Verifica se possui KPIs carregados
  bool get hasKpis => kpis != null;

  @override
  String toString() {
    return 'LawFirmModel(id: $id, name: $name, teamSize: $teamSize, hasLocation: $hasLocation, hasKpis: $hasKpis)';
  }
} 