import 'package:meu_app/src/core/error/exceptions.dart';
import 'package:meu_app/src/core/services/api_service.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/lawyers/data/models/lawyer_model.dart';
import 'package:meu_app/src/features/firms/data/models/law_firm_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<dynamic>> performSearch(SearchParams params);
}

/// Wrapper para resultados de busca com metadados de contexto
class SearchResultWrapper {
  final dynamic item; // LawyerModel ou LawFirmModel
  final String searchContext; // 'semantic', 'directory', 'hybrid'
  final double searchScore;
  final String? badge; // Badge para exibição na UI
  
  SearchResultWrapper({
    required this.item,
    required this.searchContext,
    required this.searchScore,
    this.badge,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  SearchRemoteDataSourceImpl();

  @override
  Future<List<dynamic>> performSearch(SearchParams params) async {
    try {
      // 🎯 BUSCA HÍBRIDA: Combina busca semântica + consulta direta ao diretório
      
      // 1. EXECUÇÃO PARALELA da busca semântica e de diretório
      final results = await Future.wait([
        _performSemanticSearch(params),
        _performDirectorySearch(params),
      ]);
      
      final semanticResults = results[0] as List<SearchResultWrapper>;
      final directoryResults = results[1] as List<SearchResultWrapper>;

      // 2. COMBINA RESULTADOS com deduplicação e scoring
      List<SearchResultWrapper> hybridResults = _combineAndRankResults(
        semanticResults, 
        directoryResults, 
        params
      );
      
      // 3. APLICA FILTROS FINAIS e retorna os itens originais
      return _applyFinalFilters(hybridResults, params)
          .map((wrapper) => wrapper.item)
          .toList();
      
    } catch (e) {
      throw ServerException(message: 'Falha ao realizar a busca híbrida.');
    }
  }

  /// Busca semântica via API (usa IA para matching inteligente)
  Future<List<SearchResultWrapper>> _performSemanticSearch(SearchParams params) async {
    try {
      const caseId = 'semantic_search_case';
      
      final result = await ApiService.getMatches(
        caseId,
        preset: params.preset,
        customLatitude: params.latitude,
        customLongitude: params.longitude,
        radiusKm: params.radiusKm,
      );

      final lawyers = (result['lawyers'] as List? ?? [])
          .map((data) => LawyerModel.fromJson(data))
          .toList();
      
      final firms = (result['firms'] as List? ?? [])
          .map((data) => LawFirmModel.fromJson(data))
          .toList();

      List<SearchResultWrapper> wrappedResults = [];
      
      // Envolve advogados com metadados semânticos
      for (var lawyer in lawyers) {
        wrappedResults.add(SearchResultWrapper(
          item: lawyer,
          searchContext: 'semantic',
          searchScore: 0.8, // Score alto para busca semântica
          badge: '🧠 Semântico',
        ));
      }
      
      // Envolve escritórios com metadados semânticos
      for (var firm in firms) {
        wrappedResults.add(SearchResultWrapper(
          item: firm,
          searchContext: 'semantic',
          searchScore: 0.8,
          badge: '🧠 Semântico',
        ));
      }

      return wrappedResults;
    } catch (e) {
      // Se busca semântica falhar, retorna lista vazia
      return [];
    }
  }

  /// Busca direta no diretório (filtros específicos + busca textual)
  Future<List<SearchResultWrapper>> _performDirectorySearch(SearchParams params) async {
    try {
      // Chama o novo endpoint de busca por diretório
      final results = await ApiService.directorySearch(params);
      
      // Envolve resultados com metadados de diretório
      List<SearchResultWrapper> wrappedResults = [];
      for (var item in results) {
        wrappedResults.add(SearchResultWrapper(
          item: item,
          searchContext: 'directory',
          searchScore: (item is LawyerModel) ? item.score : 0.7, // Usa score da API
          badge: '🗄️ Diretório',
        ));
      }
      
      return wrappedResults;
    } catch (e) {
      // Em caso de erro, retorna lista vazia para não quebrar a busca híbrida
      return [];
    }
  }

  /// Busca textual por nome e especialização (mock)
  Future<List<dynamic>> _searchByNameAndSpecialty(String query) async {
    // Mock de dados para demonstração da busca híbrida
    List<LawyerModel> mockLawyers = [
      LawyerModel(
        id: 'dir_lawyer_1',
        name: 'Maria Silva - Direito Trabalhista',
        avatarUrl: 'https://ui-avatars.com/api/?name=Maria+Silva',
        oab: '123456/SP',
        expertiseAreas: ['Direito do Trabalho', 'Ações Indenizatórias'],
        score: 0.75,
        estimatedResponseTimeHours: 12,
        rating: 4.8,
        reviewTexts: ['Excelente profissional, muito atenciosa.'],
        isAvailable: true,
        totalCases: 89,
        estimatedSuccessRate: 0.92,
        specializationScore: 0.88,
        activityLevel: 'high',
      ),
      LawyerModel(
        id: 'dir_lawyer_2', 
        name: 'João Santos - Direito Civil',
        avatarUrl: 'https://ui-avatars.com/api/?name=João+Santos',
        oab: '654321/RJ',
        expertiseAreas: ['Direito de Família', 'Contratos'],
        score: 0.81,
        estimatedResponseTimeHours: 6,
        rating: 4.9,
        reviewTexts: ['Resolveu meu caso rapidamente.', 'Muito competente.'],
        isAvailable: true,
        totalCases: 120,
        estimatedSuccessRate: 0.95,
        specializationScore: 0.91,
        activityLevel: 'very_high',
      ),
    ];
    
    final queryLower = query.toLowerCase();
    List<dynamic> results = [];
    
    // Busca em advogados
    results.addAll(mockLawyers.where((lawyer) =>
        lawyer.name.toLowerCase().contains(queryLower) ||
        lawyer.oab.toLowerCase().contains(queryLower)
    ));
    
    return results;
  }

  /// Aplica filtros específicos na busca direta
  List<dynamic> _applyDirectoryFilters(List<dynamic> results, SearchParams params) {
    return results.where((item) {
      // Por ora, mantém todos os resultados
      // Em produção, aplicaria filtros baseados nos campos dos modelos
      return true;
    }).toList();
  }

  /// Combina resultados semânticos e de diretório com deduplicação
  List<SearchResultWrapper> _combineAndRankResults(
    List<SearchResultWrapper> semanticResults,
    List<SearchResultWrapper> directoryResults,
    SearchParams params,
  ) {
    Map<String, SearchResultWrapper> combinedMap = {};
    
    // Adiciona resultados semânticos (prioridade alta)
    for (var wrapper in semanticResults) {
      String id = _getItemId(wrapper.item);
      combinedMap[id] = wrapper;
    }
    
    // Adiciona resultados de diretório (evita duplicatas)
    for (var wrapper in directoryResults) {
      String id = _getItemId(wrapper.item);
      if (!combinedMap.containsKey(id)) {
        combinedMap[id] = wrapper;
      } else {
        // Se já existe, marca como resultado híbrido e combina scores
        var existing = combinedMap[id]!;
        combinedMap[id] = SearchResultWrapper(
          item: existing.item,
          searchContext: 'hybrid',
          searchScore: (existing.searchScore + wrapper.searchScore) / 2,
          badge: '⚡ Híbrido',
        );
      }
    }
    
    // Converte para lista e ordena por score
    List<SearchResultWrapper> combinedResults = combinedMap.values.toList();
    combinedResults.sort((a, b) => b.searchScore.compareTo(a.searchScore));
    
    return combinedResults;
  }

  /// Aplica filtros finais baseados em query textual
  List<SearchResultWrapper> _applyFinalFilters(List<SearchResultWrapper> results, SearchParams params) {
    if (params.query == null || params.query!.isEmpty) {
      return results;
    }
    
    final query = params.query!.toLowerCase();
    return results.where((wrapper) {
      final item = wrapper.item;
      if (item is LawyerModel) {
        return item.name.toLowerCase().contains(query) ||
               item.oab.toLowerCase().contains(query);
      }
      if (item is LawFirmModel) {
        return item.name.toLowerCase().contains(query);
      }
      return false;
    }).toList();
  }

  /// Calcula score para busca direta (baseado em filtros)
  double _calculateDirectoryScore(dynamic item, SearchParams params) {
    double score = 0.6; // Score base para busca direta
    
    if (item is LawyerModel) {
      // Bonifica por OAB válida
      if (item.oab != 'N/A' && item.oab.isNotEmpty) {
        score += 0.1;
      }
      
      // Bonifica por nome completo
      if (item.name.split(' ').length > 2) {
        score += 0.1;
      }
    } else if (item is LawFirmModel) {
      // Bonifica por nome do escritório
      if (item.name.isNotEmpty) {
        score += 0.2;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Extrai ID único do item
  String _getItemId(dynamic item) {
    if (item is LawyerModel) return 'lawyer_${item.id}';
    if (item is LawFirmModel) return 'firm_${item.id}';
    return 'unknown_${item.hashCode}';
  }
} 
 