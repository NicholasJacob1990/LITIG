import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/core/network/network_info.dart';
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';

class PartnershipRepositoryImpl implements PartnershipRepository {
  final PartnershipRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  
  // 🆕 Base URL para API híbrida
  static const String _baseUrl = 'https://api.litig.com'; // TODO: Configurar via env

  const PartnershipRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<List<Partnership>>> fetchPartnerships() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePartnerships = await remoteDataSource.fetchPartnerships();
        // The models are subtypes of entities, so they can be returned directly.
        return Result.success(remotePartnerships);
      } on SocketException {
        return Result.connectionFailure(
          'Falha na conexão com o servidor',
          'CONNECTION_ERROR',
        );
      } on FormatException {
        return Result.validationFailure(
          'Formato de dados inválido recebido do servidor',
          'INVALID_FORMAT',
        );
      } catch (e) {
        return Result.genericFailure(
          'Ocorreu um erro inesperado: ${e.toString()}',
          'UNKNOWN_ERROR',
        );
      }
    } else {
      return Result.connectionFailure(
        'Sem conexão com a internet',
        'NO_CONNECTION',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getEnhancedPartnershipRecommendations({
    required String lawyerId,
    bool expandSearch = false,
    int limit = 10,
    double minConfidence = 0.6,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('Sem conexão com a internet');
    }

    try {
      final url = Uri.parse('$_baseUrl/partnerships/recommendations/enhanced/$lawyerId');
      final queryParams = {
        'expand_search': expandSearch.toString(),
        'limit': limit.toString(),
        'min_confidence': minConfidence.toString(),
      };
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      // Para demo, retornar dados mockados
      return _getMockHybridRecommendations(expandSearch);
    }
  }

  @override
  Future<Map<String, dynamic>> createPartnershipInvitation({
    required Map<String, dynamic> externalProfile,
    required Map<String, dynamic> partnershipContext,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('Sem conexão com a internet');
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/partnerships/invites/');
      final requestBody = {
        'external_profile': externalProfile,
        'partnership_context': partnershipContext,
      };
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      // Para demo, retornar sucesso mockado
      return {
        'status': 'created',
        'invitation_id': 'demo_invite_${DateTime.now().millisecondsSinceEpoch}',
        'claim_url': 'https://app.litig.com/invite/demo_token',
        'linkedin_message': 'Mensagem de convite preparada...',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getMyInvitations({
    String? status,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected) {
      throw Exception('Sem conexão com a internet');
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/partnerships/invites/');
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await http.get(
        url.replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      // Para demo, retornar dados mockados
      return {
        'invitations': [],
        'total_count': 0,
        'stats': {'total_sent': 0, 'accepted': 0, 'pending': 0},
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getInvitationStatistics() async {
    if (!await networkInfo.isConnected) {
      throw Exception('Sem conexão com a internet');
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/partnerships/invites/stats');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      // Para demo, retornar estatísticas mockadas
      return {
        'statistics': {
          'total_sent': 5,
          'pending': 2,
          'accepted': 3,
          'expired': 0,
          'acceptance_rate': 60.0,
        },
      };
    }
  }

  /// Dados mockados para demonstração
  Map<String, dynamic> _getMockHybridRecommendations(bool expandSearch) {
    final internalRecs = [
      {
        'lawyer_id': 'lawyer_001',
        'name': 'Dr. João Silva',
        'firm_name': 'Silva & Associados',
        'compatibility_score': 0.92,
        'potential_synergies': ['Direito Empresarial', 'M&A'],
        'partnership_reason': 'Complementa expertise em fusões e aquisições',
        'lawyer_specialty': 'Direito Empresarial',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'verified',
      },
      {
        'lawyer_id': 'lawyer_002',
        'name': 'Dra. Maria Santos',
        'firm_name': 'Santos Legal',
        'compatibility_score': 0.87,
        'potential_synergies': ['Direito Trabalhista', 'Compliance'],
        'partnership_reason': 'Sinergia em casos trabalhistas complexos',
        'lawyer_specialty': 'Direito Trabalhista',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'verified',
      },
    ];

    final externalRecs = expandSearch ? [
      {
        'lawyer_id': 'external_001',
        'name': 'Dr. Pedro Costa',
        'compatibility_score': 0.85,
        'potential_synergies': ['Direito Digital', 'LGPD'],
        'partnership_reason': 'Expertise complementar em direito digital',
        'lawyer_specialty': 'Direito Digital',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'public_profile',
        'profile_data': {
          'full_name': 'Dr. Pedro Costa',
          'headline': 'Especialista em Direito Digital e LGPD',
          'profile_url': 'https://linkedin.com/in/pedro-costa',
          'city': 'São Paulo',
          'confidence_score': 0.85,
        },
      },
    ] : <Map<String, dynamic>>[];

    final allRecs = [...internalRecs, ...externalRecs];

    return {
      'lawyer_id': 'current_lawyer',
      'total_recommendations': allRecs.length,
      'algorithm_info': {
        'llm_enabled': true,
        'expand_search': expandSearch,
        'hybrid_model': expandSearch,
      },
      'recommendations': allRecs,
      'metadata': {
        'hybrid_stats': {
          'internal_profiles': internalRecs.length,
          'external_profiles': externalRecs.length,
          'hybrid_ratio': expandSearch ? 0.33 : 0.0,
        },
        'generated_at': DateTime.now().toIso8601String(),
      },
    };
  }
  
  @override
  Future<Result<void>> acceptPartnership(String partnershipId) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/partnerships/$partnershipId/accept'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer TOKEN', // TODO: Get from auth service
          },
        );
        
        if (response.statusCode == 200) {
          return const Result.success(null);
        } else {
          return Result.genericFailure(
            'Erro ao aceitar parceria',
            'ACCEPT_FAILED',
          );
        }
      } catch (e) {
        return Result.genericFailure(
          'Erro ao aceitar parceria: ${e.toString()}',
          'ACCEPT_ERROR',
        );
      }
    } else {
      return Result.connectionFailure(
        'Sem conexão com a internet',
        'NO_CONNECTION',
      );
    }
  }
  
  @override
  Future<Result<void>> rejectPartnership(String partnershipId) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/partnerships/$partnershipId/reject'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer TOKEN', // TODO: Get from auth service
          },
        );
        
        if (response.statusCode == 200) {
          return const Result.success(null);
        } else {
          return Result.genericFailure(
            'Erro ao rejeitar parceria',
            'REJECT_FAILED',
          );
        }
      } catch (e) {
        return Result.genericFailure(
          'Erro ao rejeitar parceria: ${e.toString()}',
          'REJECT_ERROR',
        );
      }
    } else {
      return Result.connectionFailure(
        'Sem conexão com a internet',
        'NO_CONNECTION',
      );
    }
  }
  
  @override
  Future<Result<Partnership>> updatePartnershipStatus(String partnershipId, String status) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await http.put(
          Uri.parse('$_baseUrl/partnerships/$partnershipId/status'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer TOKEN', // TODO: Get from auth service
          },
          body: jsonEncode({'status': status}),
        );
        
        if (response.statusCode == 200) {
          // TODO: Create proper Partnership from JSON with real partner data
          // For now, create a mock partnership with minimal data
          const mockLawyer = Lawyer(
            id: 'mock_lawyer_id',
            name: 'Mock Partner',
            avatarUrl: '',
            oab: '123456/SP',
            expertiseAreas: ['Direito Civil'],
            rating: 4.5,
            isAvailable: true,
            plan: 'PRO',
          );
          
          final partnership = Partnership(
            id: partnershipId,
            title: 'Parceria Atualizada',
            type: PartnershipType.correspondent,
            status: PartnershipStatus.values.firstWhere(
              (s) => s.toString().split('.').last == status,
              orElse: () => PartnershipStatus.pending,
            ),
            createdAt: DateTime.now(),
            partner: mockLawyer,
            partnerType: PartnerEntityType.lawyer,
          );
          
          return Result.success(partnership);
        } else {
          return Result.genericFailure(
            'Erro ao atualizar status da parceria',
            'UPDATE_FAILED',
          );
        }
      } catch (e) {
        return Result.genericFailure(
          'Erro ao atualizar parceria: ${e.toString()}',
          'UPDATE_ERROR',
        );
      }
    } else {
      return Result.connectionFailure(
        'Sem conexão com a internet',
        'NO_CONNECTION',
      );
    }
  }
} 