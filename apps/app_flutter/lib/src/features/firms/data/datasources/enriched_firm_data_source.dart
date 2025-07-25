import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/enriched_firm_model.dart';

abstract class EnrichedFirmDataSource {
  Future<EnrichedFirmModel> getEnrichedFirm(String firmId);
  Future<EnrichedFirmModel> refreshEnrichedFirm(String firmId);
}

class EnrichedFirmDataSourceImpl implements EnrichedFirmDataSource {
  final http.Client client;
  final String baseUrl;

  EnrichedFirmDataSourceImpl({
    required this.client,
    this.baseUrl = 'http://localhost:8000',
  });

  @override
  Future<EnrichedFirmModel> getEnrichedFirm(String firmId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return EnrichedFirmModel.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load enriched firm data: ${response.statusCode}');
    }
  }

  @override
  Future<EnrichedFirmModel> refreshEnrichedFirm(String firmId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/refresh'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return EnrichedFirmModel.fromJson(jsonMap);
    } else {
      throw Exception('Failed to refresh enriched firm data: ${response.statusCode}');
    }
  }
} 
import 'package:http/http.dart' as http;
import '../models/enriched_firm_model.dart';

abstract class EnrichedFirmDataSource {
  Future<EnrichedFirmModel> getEnrichedFirm(String firmId);
  Future<EnrichedFirmModel> refreshEnrichedFirm(String firmId);
}

class EnrichedFirmDataSourceImpl implements EnrichedFirmDataSource {
  final http.Client client;
  final String baseUrl;

  EnrichedFirmDataSourceImpl({
    required this.client,
    this.baseUrl = 'http://localhost:8000',
  });

  @override
  Future<EnrichedFirmModel> getEnrichedFirm(String firmId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/complete'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return EnrichedFirmModel.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load enriched firm data: ${response.statusCode}');
    }
  }

  @override
  Future<EnrichedFirmModel> refreshEnrichedFirm(String firmId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/enriched-firms/firm/$firmId/refresh'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return EnrichedFirmModel.fromJson(jsonMap);
    } else {
      throw Exception('Failed to refresh enriched firm data: ${response.statusCode}');
    }
  }
} 