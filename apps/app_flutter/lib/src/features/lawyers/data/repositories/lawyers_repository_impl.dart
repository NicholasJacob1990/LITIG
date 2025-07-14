import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_datasource.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';
import 'package:meu_app/src/core/mocks/mock_lawyers.dart'; // 👈 IMPORTAR DADOS MOCK
import 'package:flutter/foundation.dart'; // 👈 IMPORTAR PARA kDebugMode

class LawyersRepositoryImpl implements LawyersRepository {
  final LawyersRemoteDataSource remoteDataSource;

  LawyersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MatchedLawyer>> findMatches({String? caseId}) async {
    if (caseId == null) {
      return [];
    }
    
    try {
      final lawyers = await remoteDataSource.findMatches(caseId: caseId);
      
      // A conversão agora é necessária e corrigida
      return lawyers.map((lawyer) => MatchedLawyer(
        id: lawyer.id,
        nome: lawyer.name,
        primaryArea: lawyer.primaryArea,
        reviewCount: lawyer.casesCount, // Mapeando de casesCount
        distanceKm: lawyer.distanceKm,
        isAvailable: lawyer.isAvailable,
        avatarUrl: lawyer.avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyer.name)}&background=6B7280&color=fff',
        rating: lawyer.rating,
        fair: lawyer.fairScore,
        equity: 0.0, // Campo não disponível em 'Lawyer', usando valor padrão
        features: LawyerFeatures(
          successRate: lawyer.features['T'] ?? 0.0,
          softSkills: lawyer.features['C'] ?? 0.0,
          responseTime: (lawyer.features['U'] ?? 24).toInt(),
        ),
      )).toList();

    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AVISO: Falha na API. Usando dados mockados para LawyersRepository.findMatches');
        await Future.delayed(const Duration(milliseconds: 750));
        return MOCK_MATCHED_LAWYERS;
      }
      rethrow;
    }
  }
} 