/// Constantes para presets de busca do sistema
class SearchPresets {
  static const Map<String, Map<String, double>> presetWeights = {
    'balanced': {
      'expertise': 0.3,
      'experience': 0.25,
      'rating': 0.2,
      'availability': 0.15,
      'location': 0.1,
    },
    'expert': {
      'expertise': 0.4,
      'experience': 0.35,
      'rating': 0.15,
      'availability': 0.05,
      'location': 0.05,
    },
    'fast': {
      'expertise': 0.25,
      'experience': 0.2,
      'rating': 0.15,
      'availability': 0.3,
      'location': 0.1,
    },
    'economic': {
      'expertise': 0.2,
      'experience': 0.15,
      'rating': 0.1,
      'availability': 0.25,
      'location': 0.3,
    },
    'correspondent': {
      'expertise': 0.3,
      'experience': 0.25,
      'rating': 0.2,
      'availability': 0.15,
      'location': 0.1,
    },
    'expert_opinion': {
      'expertise': 0.45,
      'experience': 0.35,
      'rating': 0.15,
      'availability': 0.03,
      'location': 0.02,
    },
  };

  static const Map<String, String> presetLabels = {
    'balanced': 'Equilibrado',
    'expert': 'Especialista',
    'fast': 'Rápido',
    'economic': 'Econômico',
    'correspondent': 'Correspondente',
    'expert_opinion': 'Parecer Técnico',
  };

  static const Map<String, String> presetDescriptions = {
    'balanced': 'Recomendação balanceada considerando todos os fatores',
    'expert': 'Foco em especialização e experiência',
    'fast': 'Prioriza disponibilidade e tempo de resposta',
    'economic': 'Considera custo-benefício e localização',
    'correspondent': 'Para casos que precisam de correspondente',
    'expert_opinion': 'Especialistas para pareceres técnicos',
  };

  /// Valida se um preset específico soma 1.0
  static bool validatePreset(String preset) {
    final weights = presetWeights[preset];
    if (weights == null) return false;
    
    final sum = weights.values.reduce((a, b) => a + b);
    return (sum - 1.0).abs() < 1e-6;
  }

  /// Retorna a soma dos pesos de um preset
  static double getPresetSum(String preset) {
    final weights = presetWeights[preset];
    if (weights == null) return 0.0;
    
    return weights.values.reduce((a, b) => a + b);
  }

  /// Valida todos os presets
  static PresetValidationResult validateAllPresets() {
    final invalidPresets = <String>[];
    final presetSums = <String, double>{};
    
    for (final preset in presetWeights.keys) {
      final sum = getPresetSum(preset);
      presetSums[preset] = sum;
      
      if ((sum - 1.0).abs() >= 1e-6) {
        invalidPresets.add(preset);
      }
    }
    
    final isValid = invalidPresets.isEmpty;
    final errorMessage = isValid 
        ? '' 
        : 'Presets inválidos: ${invalidPresets.join(', ')}';
    
    return PresetValidationResult(
      isValid: isValid,
      invalidPresets: invalidPresets,
      presetSums: presetSums,
      errorMessage: errorMessage,
    );
  }

  /// Verifica se um preset é válido para um contexto específico
  static bool isValidForContext(String preset, String context) {
    switch (context) {
      case 'client':
        return ['balanced', 'fast', 'economic'].contains(preset);
      case 'lawyer':
        return ['correspondent', 'expert_opinion'].contains(preset);
      default:
        return presetWeights.containsKey(preset);
    }
  }
}

/// Resultado da validação de presets
class PresetValidationResult {
  final bool isValid;
  final List<String> invalidPresets;
  final Map<String, double> presetSums;
  final String errorMessage;

  const PresetValidationResult({
    required this.isValid,
    required this.invalidPresets,
    required this.presetSums,
    required this.errorMessage,
  });

  String get summary {
    if (isValid) {
      return '✅ Todos os ${presetSums.length} presets são válidos';
    } else {
      return '❌ ${invalidPresets.length} presets inválidos de ${presetSums.length}';
    }
  }
} 