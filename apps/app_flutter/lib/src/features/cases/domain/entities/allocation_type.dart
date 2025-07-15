/// Tipos de alocação de casos conforme ARQUITETURA_GERAL_DO_SISTEMA.md
/// Sistema de Contextual Case View
enum AllocationType {
  /// Algoritmo → Advogado (Super Associado)
  platformMatchDirect('platform_match_direct'),
  
  /// Algoritmo → Parceria → Advogado  
  platformMatchPartnership('platform_match_partnership'),
  
  /// Parceria criada por busca manual
  partnershipProactiveSearch('partnership_proactive_search'),
  
  /// Parceria sugerida por IA
  partnershipPlatformSuggestion('partnership_platform_suggestion'),
  
  /// Escritório → Advogado Associado
  internalDelegation('internal_delegation');

  const AllocationType(this.value);
  
  final String value;
  
  /// Converte string para enum
  static AllocationType fromString(String value) {
    switch (value) {
      case 'platform_match_direct':
        return AllocationType.platformMatchDirect;
      case 'platform_match_partnership':
        return AllocationType.platformMatchPartnership;
      case 'partnership_proactive_search':
        return AllocationType.partnershipProactiveSearch;
      case 'partnership_platform_suggestion':
        return AllocationType.partnershipPlatformSuggestion;
      case 'internal_delegation':
        return AllocationType.internalDelegation;
      default:
        return AllocationType.platformMatchDirect;
    }
  }
  
  /// Descrição legível do tipo
  String get displayName {
    switch (this) {
      case AllocationType.platformMatchDirect:
        return 'Match Direto';
      case AllocationType.platformMatchPartnership:
        return 'Match via Parceria';
      case AllocationType.partnershipProactiveSearch:
        return 'Parceria Manual';
      case AllocationType.partnershipPlatformSuggestion:
        return 'Parceria sugerida por IA';
      case AllocationType.internalDelegation:
        return 'Delegação Interna';
    }
  }
  
  /// Cor associada ao tipo
  String get color {
    switch (this) {
      case AllocationType.platformMatchDirect:
        return 'blue';
      case AllocationType.platformMatchPartnership:
        return 'purple';
      case AllocationType.partnershipProactiveSearch:
        return 'green';
      case AllocationType.partnershipPlatformSuggestion:
        return 'teal';
      case AllocationType.internalDelegation:
        return 'orange';
    }
  }
} 