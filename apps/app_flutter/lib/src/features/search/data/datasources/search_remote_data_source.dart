import 'package:dio/dio.dart';
import 'package:meu_app/src/core/error/exceptions.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/core/services/api_service.dart'; // Mantido para a lógica original
import 'package:meu_app/src/features/lawyers/data/models/lawyer_model.dart';
import 'package:meu_app/src/features/firms/data/models/law_firm_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<dynamic>> performSearch(SearchParams params);
  Future<List<dynamic>> performSemanticFirmSearch(SearchParams params);
}

// Classe Wrapper restaurada
class SearchResultWrapper {
  final dynamic item;
  final String searchContext;
  final double searchScore;
  final String? badge;
  
  SearchResultWrapper({
    required this.item,
    required this.searchContext,
    required this.searchScore,
    this.badge,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio dio;

  SearchRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<dynamic>> performSearch(SearchParams params) async {
    try {
      // 🎯 BUSCA HÍBRIDA: Combina busca semântica + consulta direta ao diretório
      
      // 1. EXECUÇÃO PARALELA da busca semântica e de diretório
      final results = await Future.wait([
        _performSemanticSearch(params),
        _performDirectorySearch(params),
      ]);
      
      final semanticResults = results[0];
      final directoryResults = results[1];

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

  @override
  Future<List<dynamic>> performSemanticFirmSearch(SearchParams params) async {
    if (params.query == null || params.query!.trim().isEmpty) {
      return [];
    }
    
    try {
      final response = await dio.post(
        '/api/firms/semantic-search',
        data: {
          'query': params.query,
          'top_k': 15,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      } else {
        throw ServerException(message: 'Erro ao buscar escritórios via busca semântica.');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['detail'] ?? 'Erro de rede ao buscar escritórios.');
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

  /// Extrai ID único do item
  String _getItemId(dynamic item) {
    if (item is LawyerModel) return 'lawyer_${item.id}';
    if (item is LawFirmModel) return 'firm_${item.id}';
    return 'unknown_${item.hashCode}';
  }
}
