import 'package:equatable/equatable.dart';

/// Tipo de parte processual
enum PartyType {
  plaintiff('plaintiff', 'Autor', 'Parte que move a ação'),
  defendant('defendant', 'Réu', 'Parte contra quem a ação é movida'),
  thirdParty('third_party', 'Terceiro', 'Terceiro interessado'),
  intervenient('intervenient', 'Interveniente', 'Parte que intervém no processo');

  const PartyType(this.id, this.displayName, this.description);

  final String id;
  final String displayName;
  final String description;
}

/// Representa uma parte processual em casos contenciosos
class LitigationParty extends Equatable {
  const LitigationParty({
    required this.id,
    required this.name,
    required this.type,
    this.documentNumber,
    this.address,
    this.lawyer,
    this.isRepresentedBySelf = false,
    this.notes,
  });

  final String id;
  final String name;
  final PartyType type;
  final String? documentNumber; // CPF/CNPJ
  final String? address;
  final String? lawyer; // Nome do advogado da parte
  final bool isRepresentedBySelf; // Se representa a si mesmo
  final String? notes;

  /// Factory para criar autor
  factory LitigationParty.plaintiff({
    required String id,
    required String name,
    String? documentNumber,
    String? address,
    String? lawyer,
    bool isRepresentedBySelf = false,
    String? notes,
  }) {
    return LitigationParty(
      id: id,
      name: name,
      type: PartyType.plaintiff,
      documentNumber: documentNumber,
      address: address,
      lawyer: lawyer,
      isRepresentedBySelf: isRepresentedBySelf,
      notes: notes,
    );
  }

  /// Factory para criar réu
  factory LitigationParty.defendant({
    required String id,
    required String name,
    String? documentNumber,
    String? address,
    String? lawyer,
    bool isRepresentedBySelf = false,
    String? notes,
  }) {
    return LitigationParty(
      id: id,
      name: name,
      type: PartyType.defendant,
      documentNumber: documentNumber,
      address: address,
      lawyer: lawyer,
      isRepresentedBySelf: isRepresentedBySelf,
      notes: notes,
    );
  }

  /// Factory para criar a partir de JSON
  factory LitigationParty.fromJson(Map<String, dynamic> json) {
    return LitigationParty(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PartyType.values.firstWhere(
        (type) => type.id == json['type'],
        orElse: () => PartyType.plaintiff,
      ),
      documentNumber: json['document_number'] as String?,
      address: json['address'] as String?,
      lawyer: json['lawyer'] as String?,
      isRepresentedBySelf: json['is_represented_by_self'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.id,
      'document_number': documentNumber,
      'address': address,
      'lawyer': lawyer,
      'is_represented_by_self': isRepresentedBySelf,
      'notes': notes,
    };
  }

  /// Cria uma cópia com modificações
  LitigationParty copyWith({
    String? id,
    String? name,
    PartyType? type,
    String? documentNumber,
    String? address,
    String? lawyer,
    bool? isRepresentedBySelf,
    String? notes,
  }) {
    return LitigationParty(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      documentNumber: documentNumber ?? this.documentNumber,
      address: address ?? this.address,
      lawyer: lawyer ?? this.lawyer,
      isRepresentedBySelf: isRepresentedBySelf ?? this.isRepresentedBySelf,
      notes: notes ?? this.notes,
    );
  }

  /// Verifica se é o autor
  bool get isPlaintiff => type == PartyType.plaintiff;

  /// Verifica se é o réu
  bool get isDefendant => type == PartyType.defendant;

  /// Retorna representação sucinta para exibição
  String get displayText {
    final representation = isRepresentedBySelf 
        ? '(própria pessoa)' 
        : lawyer != null 
            ? '(Adv: $lawyer)'
            : '(sem representação)';
    
    return '$name $representation';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    documentNumber,
    address,
    lawyer,
    isRepresentedBySelf,
    notes,
  ];
} 