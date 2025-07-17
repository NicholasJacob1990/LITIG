import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/sla_escalation_entity.dart';
import '../../domain/repositories/sla_escalation_repository.dart';
import '../datasources/sla_escalation_remote_data_source.dart';
import '../datasources/sla_escalation_local_data_source.dart';
import '../models/sla_escalation_model.dart';

class SlaEscalationRepositoryImpl implements SlaEscalationRepository {
  final SlaEscalationRemoteDataSource remoteDataSource;
  final SlaEscalationLocalDataSource localDataSource;
  final Dio dio;

  SlaEscalationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dio,
  });

  @override
  Future<List<SlaEscalationEntity>> getEscalations(String firmId) async {
    try {
      // Try cache first
      final cachedEscalations = await localDataSource.getEscalations(firmId);
      if (cachedEscalations.isNotEmpty) {
        return cachedEscalations;
      }

      // Fetch from remote
      final remoteEscalations = await remoteDataSource.getEscalations(firmId);
      
      // Cache results
      await localDataSource.cacheEscalations(remoteEscalations);
      
      return remoteEscalations;
    } catch (e) {
      // Fallback to cache
      final cachedEscalations = await localDataSource.getEscalations(firmId);
      if (cachedEscalations.isNotEmpty) {
        return cachedEscalations;
      }
      throw Exception('Failed to load escalations: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> createEscalation(SlaEscalationEntity escalation) async {
    try {
      final createdEscalation = await remoteDataSource.createEscalation(escalation);
      await localDataSource.cacheEscalation(createdEscalation);
      return createdEscalation;
    } catch (e) {
      throw Exception('Failed to create escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> updateEscalation(SlaEscalationEntity escalation) async {
    try {
      final updatedEscalation = await remoteDataSource.updateEscalation(escalation);
      await localDataSource.cacheEscalation(updatedEscalation);
      return updatedEscalation;
    } catch (e) {
      throw Exception('Failed to update escalation: $e');
    }
  }

  @override
  Future<void> deleteEscalation(String escalationId) async {
    try {
      await remoteDataSource.deleteEscalation(escalationId);
      await localDataSource.removeEscalation(escalationId);
    } catch (e) {
      throw Exception('Failed to delete escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> getEscalationById(String escalationId) async {
    try {
      final escalation = await remoteDataSource.getEscalationById(escalationId);
      return escalation;
    } catch (e) {
      throw Exception('Failed to get escalation: $e');
    }
  }

  @override
  Future<bool> executeEscalation(String escalationId, Map<String, dynamic> context) async {
    try {
      final result = await remoteDataSource.executeEscalation(escalationId, context);
      return result;
    } catch (e) {
      throw Exception('Failed to execute escalation: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEscalationHistory(String firmId) async {
    try {
      final history = await remoteDataSource.getEscalationHistory(firmId);
      return history;
    } catch (e) {
      throw Exception('Failed to get escalation history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getEscalationStats(String firmId) async {
    try {
      final stats = await remoteDataSource.getEscalationStats(firmId);
      return stats;
    } catch (e) {
      throw Exception('Failed to get escalation stats: $e');
    }
  }

  @override
  Future<bool> testEscalation(String escalationId) async {
    try {
      final result = await remoteDataSource.testEscalation(escalationId);
      return result;
    } catch (e) {
      throw Exception('Failed to test escalation: $e');
    }
  }

  @override
  Future<List<SlaEscalationEntity>> getActiveEscalations(String firmId) async {
    try {
      final activeEscalations = await remoteDataSource.getActiveEscalations(firmId);
      return activeEscalations;
    } catch (e) {
      throw Exception('Failed to get active escalations: $e');
    }
  }

  @override
  Future<void> activateEscalation(String escalationId) async {
    try {
      await remoteDataSource.activateEscalation(escalationId);
      // Update local cache
      final escalation = await getEscalationById(escalationId);
      await localDataSource.cacheEscalation(escalation);
    } catch (e) {
      throw Exception('Failed to activate escalation: $e');
    }
  }

  @override
  Future<void> deactivateEscalation(String escalationId) async {
    try {
      await remoteDataSource.deactivateEscalation(escalationId);
      // Update local cache
      final escalation = await getEscalationById(escalationId);
      await localDataSource.cacheEscalation(escalation);
    } catch (e) {
      throw Exception('Failed to deactivate escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> duplicateEscalation(String escalationId) async {
    try {
      final duplicatedEscalation = await remoteDataSource.duplicateEscalation(escalationId);
      await localDataSource.cacheEscalation(duplicatedEscalation);
      return duplicatedEscalation;
    } catch (e) {
      throw Exception('Failed to duplicate escalation: $e');
    }
  }

  @override
  Future<String> exportEscalation(String escalationId, String format) async {
    try {
      final exportPath = await remoteDataSource.exportEscalation(escalationId, format);
      return exportPath;
    } catch (e) {
      throw Exception('Failed to export escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> importEscalation(String filePath) async {
    try {
      final importedEscalation = await remoteDataSource.importEscalation(filePath);
      await localDataSource.cacheEscalation(importedEscalation);
      return importedEscalation;
    } catch (e) {
      throw Exception('Failed to import escalation: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEscalationLogs(String escalationId) async {
    try {
      final logs = await remoteDataSource.getEscalationLogs(escalationId);
      return logs;
    } catch (e) {
      throw Exception('Failed to get escalation logs: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateEscalation(SlaEscalationEntity escalation) async {
    try {
      final validationResult = await remoteDataSource.validateEscalation(escalation);
      return validationResult;
    } catch (e) {
      throw Exception('Failed to validate escalation: $e');
    }
  }

  @override
  Future<void> clearEscalationCache() async {
    try {
      await localDataSource.clearAllEscalations();
    } catch (e) {
      throw Exception('Failed to clear escalation cache: $e');
    }
  }
} 