import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_datasource.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';

class LawyersRepositoryImpl implements LawyersRepository {
  final LawyersRemoteDataSource remoteDataSource;

  LawyersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MatchedLawyer>> findMatches({String? caseId}) async {
    // TODO: Se caseId for nulo, buscar o último caso do usuário aqui
    // antes de chamar o remoteDataSource.
    if (caseId == null) {
      // Por enquanto, retorna uma lista vazia para não quebrar.
      return [];
    }
    
    try {
      final lawyers = await remoteDataSource.findMatches(caseId: caseId);
      
      // Converter List<Lawyer> para List<MatchedLawyer>
      return lawyers.map((lawyer) => MatchedLawyer(
        id: lawyer.id,
        nome: lawyer.name,
        primaryArea: lawyer.primaryArea,
        reviewCount: 0, // TODO: Buscar do backend
        distanceKm: lawyer.distanceKm,
        isAvailable: lawyer.isAvailable,
        avatarUrl: lawyer.avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(lawyer.name)}&background=6B7280&color=fff',
        rating: lawyer.rating,
        fair: lawyer.fairScore,
        equity: 0.0, // TODO: Buscar do backend  
        features: LawyerFeatures(
          successRate: lawyer.features['T'] ?? 0.0,
          softSkills: lawyer.features['C'] ?? 0.0,
          responseTime: (lawyer.features['U'] ?? 0.0).round(),
        ),
      )).toList();
    } catch (e) {
      print('Erro no repositório de lawyers: $e');
      rethrow;
    }
  }
} 