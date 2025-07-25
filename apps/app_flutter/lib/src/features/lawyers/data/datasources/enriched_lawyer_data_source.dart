import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/enriched_lawyer.dart';
import '../models/enriched_lawyer_model.dart';

abstract class EnrichedLawyerDataSource {
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId);
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId);
}

class EnrichedLawyerRemoteDataSource implements EnrichedLawyerDataSource {
  final http.Client client;
  final String baseUrl;

  EnrichedLawyerRemoteDataSource({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/enriched-profiles/lawyer/$lawyerId/complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EnrichedLawyerModel.fromJson(jsonData).toEntity();
    } else {
      throw Exception('Failed to load enriched lawyer data: ${response.statusCode}');
    }
  }

  @override
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId) async {
    // Primeiro, solicita uma atualização dos dados
    final refreshResponse = await client.post(
      Uri.parse('$baseUrl/api/enriched-profiles/lawyer/$lawyerId/refresh'),
      headers: {'Content-Type': 'application/json'},
    );

    if (refreshResponse.statusCode != 202) {
      throw Exception('Failed to request data refresh: ${refreshResponse.statusCode}');
    }

    // Aguarda um momento para o processamento
    await Future.delayed(const Duration(seconds: 2));

    // Busca os dados atualizados
    return getEnrichedLawyer(lawyerId);
  }
} 
import 'package:http/http.dart' as http;
import '../../domain/entities/enriched_lawyer.dart';
import '../models/enriched_lawyer_model.dart';

abstract class EnrichedLawyerDataSource {
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId);
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId);
}

class EnrichedLawyerRemoteDataSource implements EnrichedLawyerDataSource {
  final http.Client client;
  final String baseUrl;

  EnrichedLawyerRemoteDataSource({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/enriched-profiles/lawyer/$lawyerId/complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EnrichedLawyerModel.fromJson(jsonData).toEntity();
    } else {
      throw Exception('Failed to load enriched lawyer data: ${response.statusCode}');
    }
  }

  @override
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId) async {
    // Primeiro, solicita uma atualização dos dados
    final refreshResponse = await client.post(
      Uri.parse('$baseUrl/api/enriched-profiles/lawyer/$lawyerId/refresh'),
      headers: {'Content-Type': 'application/json'},
    );

    if (refreshResponse.statusCode != 202) {
      throw Exception('Failed to request data refresh: ${refreshResponse.statusCode}');
    }

    // Aguarda um momento para o processamento
    await Future.delayed(const Duration(seconds: 2));

    // Busca os dados atualizados
    return getEnrichedLawyer(lawyerId);
  }
} 