import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/core/constants/search_presets.dart';

void main() {
  group('SearchPresets', () {
    test('should validate all presets correctly', () {
      final result = SearchPresets.validateAllPresets();
      
      // Todos os presets devem ser válidos (soma = 1.0)
      expect(result.isValid, isTrue, reason: result.errorMessage);
      expect(result.invalidPresets, isEmpty);
      
      // Verificar se temos todos os presets esperados
      expect(result.presetSums.keys, containsAll([
        'fast',
        'expert', 
        'balanced',
        'economic',
        'correspondent',
        'expert_opinion',
      ]));
      
      // Cada preset deve somar exatamente 1.0 (com tolerância)
      for (final entry in result.presetSums.entries) {
        expect(
          (entry.value - 1.0).abs(),
          lessThanOrEqualTo(1e-6),
          reason: 'Preset ${entry.key} soma ${entry.value}, deveria ser 1.0'
        );
      }
      
      print('✅ Validação de presets: ${result.summary}');
    });

    test('should validate individual presets', () {
      expect(SearchPresets.validatePreset('balanced'), isTrue);
      expect(SearchPresets.validatePreset('correspondent'), isTrue);
      expect(SearchPresets.validatePreset('expert_opinion'), isTrue);
      expect(SearchPresets.validatePreset('nonexistent'), isFalse);
    });

    test('should return correct preset sums', () {
      expect(SearchPresets.getPresetSum('balanced'), closeTo(1.0, 1e-6));
      expect(SearchPresets.getPresetSum('correspondent'), closeTo(1.0, 1e-6));
      expect(SearchPresets.getPresetSum('expert_opinion'), closeTo(1.0, 1e-6));
      expect(SearchPresets.getPresetSum('nonexistent'), equals(0.0));
    });

    test('should validate context-specific presets', () {
      // Presets para clientes
      expect(SearchPresets.isValidForContext('balanced', 'client'), isTrue);
      expect(SearchPresets.isValidForContext('fast', 'client'), isTrue);
      expect(SearchPresets.isValidForContext('correspondent', 'client'), isFalse);
      
      // Presets para advogados
      expect(SearchPresets.isValidForContext('correspondent', 'lawyer'), isTrue);
      expect(SearchPresets.isValidForContext('expert_opinion', 'lawyer'), isTrue);
      expect(SearchPresets.isValidForContext('fast', 'lawyer'), isFalse);
    });

    test('should have labels for all presets', () {
      for (final preset in SearchPresets.presetWeights.keys) {
        expect(SearchPresets.presetLabels.containsKey(preset), isTrue,
            reason: 'Preset $preset não tem label definido');
        expect(SearchPresets.presetDescriptions.containsKey(preset), isTrue,
            reason: 'Preset $preset não tem descrição definida');
      }
    });

    test('preset validation result should provide useful error messages', () {
      // Simular preset inválido (este teste é mais conceitual já que nossos presets são válidos)
      final result = SearchPresets.validateAllPresets();
      
      if (!result.isValid) {
        expect(result.errorMessage, isNotEmpty);
        expect(result.summary, contains('inválidos'));
      } else {
        expect(result.errorMessage, isEmpty);
        expect(result.summary, contains('✅'));
      }
    });
  });
} 
 