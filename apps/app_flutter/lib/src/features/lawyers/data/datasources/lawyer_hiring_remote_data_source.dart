import 'dart:convert';
import '../models/hiring_proposal_model.dart';
import '../models/hiring_result_model.dart';
import '../../domain/usecases/hire_lawyer.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/simple_api_service.dart';

abstract class LawyerHiringRemoteDataSource {
  Future<HiringResultModel> sendHiringProposal(HireLawyerParams params);
  Future<List<HiringProposalModel>> getHiringProposals(String lawyerId, String? status);
  Future<HiringProposalModel> acceptHiringProposal(String proposalId);
  Future<HiringProposalModel> rejectHiringProposal(String proposalId, String? reason);
}

class LawyerHiringRemoteDataSourceImpl implements LawyerHiringRemoteDataSource {
  final SimpleApiService apiService;

  LawyerHiringRemoteDataSourceImpl({required this.apiService});

  @override
  Future<HiringResultModel> sendHiringProposal(HireLawyerParams params) async {
    try {
      final response = await apiService.post(
        '/lawyers/hire',
        data: {
          'lawyer_id': params.lawyerId,
          'case_id': params.caseId,
          'client_id': params.clientId,
          'contract_type': params.contractType,
          'budget': params.budget,
          'notes': params.notes,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.data);
        return HiringResultModel.fromJson(jsonResponse);
      } else {
        throw ServerException(
          message: 'Failed to send hiring proposal: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<List<HiringProposalModel>> getHiringProposals(String lawyerId, String? status) async {
    try {
      final queryParams = <String, String>{
        'lawyer_id': lawyerId,
        if (status != null) 'status': status,
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await apiService.get(
        '/hiring-proposals?$queryString',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.data);
        final List<dynamic> proposalsJson = jsonResponse['proposals'];
        return proposalsJson
            .map((json) => HiringProposalModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get hiring proposals',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<HiringProposalModel> acceptHiringProposal(String proposalId) async {
    try {
      final response = await apiService.patch(
        '/hiring-proposals/$proposalId/accept',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.data);
        return HiringProposalModel.fromJson(jsonResponse['proposal']);
      } else {
        throw ServerException(
          message: 'Failed to accept hiring proposal',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<HiringProposalModel> rejectHiringProposal(String proposalId, String? reason) async {
    try {
      final response = await apiService.patch(
        '/hiring-proposals/$proposalId/reject',
        data: {
          'reason': reason ?? '',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.data);
        return HiringProposalModel.fromJson(jsonResponse['proposal']);
      } else {
        throw ServerException(
          message: 'Failed to reject hiring proposal',
        );
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }
}