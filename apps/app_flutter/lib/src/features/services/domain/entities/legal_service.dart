import 'package:equatable/equatable.dart';

/// Representa um serviço jurídico disponível na plataforma
class LegalService extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final double? discountPrice;
  final String duration;
  final String expertise;
  final List<String> requirements;
  final List<String> deliverables;
  final bool isActive;
  final bool isPopular;
  final double rating;
  final int reviewCount;
  final String? providerId;
  final String? providerName;
  final String? iconUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LegalService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    this.discountPrice,
    required this.duration,
    required this.expertise,
    required this.requirements,
    required this.deliverables,
    this.isActive = true,
    this.isPopular = false,
    required this.rating,
    required this.reviewCount,
    this.providerId,
    this.providerName,
    this.iconUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Preço final considerando desconto
  double get finalPrice => discountPrice ?? basePrice;

  /// Verifica se o serviço tem desconto ativo
  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;

  /// Percentual de desconto
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((basePrice - discountPrice!) / basePrice) * 100;
  }

  /// Copia o serviço com novos parâmetros
  LegalService copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? basePrice,
    double? discountPrice,
    String? duration,
    String? expertise,
    List<String>? requirements,
    List<String>? deliverables,
    bool? isActive,
    bool? isPopular,
    double? rating,
    int? reviewCount,
    String? providerId,
    String? providerName,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LegalService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      discountPrice: discountPrice ?? this.discountPrice,
      duration: duration ?? this.duration,
      expertise: expertise ?? this.expertise,
      requirements: requirements ?? this.requirements,
      deliverables: deliverables ?? this.deliverables,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    basePrice,
    discountPrice,
    duration,
    expertise,
    requirements,
    deliverables,
    isActive,
    isPopular,
    rating,
    reviewCount,
    providerId,
    providerName,
    iconUrl,
    createdAt,
    updatedAt,
  ];
}

/// Categorias de serviços jurídicos
enum ServiceCategory {
  civilLaw('civil', 'Direito Civil'),
  criminalLaw('criminal', 'Direito Criminal'),
  laborLaw('labor', 'Direito Trabalhista'),
  corporateLaw('corporate', 'Direito Empresarial'),
  taxLaw('tax', 'Direito Tributário'),
  familyLaw('family', 'Direito de Família'),
  realEstate('real_estate', 'Direito Imobiliário'),
  intellectual('intellectual', 'Propriedade Intelectual'),
  administrative('administrative', 'Direito Administrativo'),
  consumer('consumer', 'Direito do Consumidor'),
  other('other', 'Outros');

  const ServiceCategory(this.code, this.displayName);
  
  final String code;
  final String displayName;
}