import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sla_escalation_model.dart';

/// Data source local para escalações SLA
/// 
/// Responsável pelo armazenamento local das escalações SLA
/// usando SharedPreferences para persistência offline
abstract class SlaEscalationLocalDataSource {
  /// Obtém escalações SLA do armazenamento local
  Future<List<SlaEscalationModel>> getEscalations({required String firmId});
  
  /// Salva escalação SLA no armazenamento local
  Future<void> saveEscalation({required SlaEscalationModel escalation});
  
  /// Remove escalação SLA do armazenamento local
  Future<void> deleteEscalation({required String escalationId});
  
  /// Obtém escalação específica por ID
  Future<SlaEscalationModel?> getEscalation({required String escalationId});
  
  /// Obtém escalações por caso
  Future<List<SlaEscalationModel>> getEscalationsByCase({required String caseId});
  
  /// Obtém escalações por status
  Future<List<SlaEscalationModel>> getEscalationsByStatus({required String status});
  
  /// Limpa todo o cache local
  Future<void> clearCache();
  
  /// Verifica se há escalações salvas para uma firma
  Future<bool> hasEscalations({required String firmId});
  
  /// Obtém timestamp da última modificação
  Future<DateTime?> getLastModified({required String firmId});
  
  /// Salva múltiplas escalações
  Future<void> saveMultipleEscalations({required List<SlaEscalationModel> escalations});
  
  /// Obtém estatísticas de escalações
  Future<Map<String, dynamic>> getEscalationStats({required String firmId});
}

class SlaEscalationLocalDataSourceImpl implements SlaEscalationLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _keyPrefix = 'sla_escalation_';
  static const String _firmEscalationsPrefix = 'firm_escalations_';
  static const String _caseEscalationsPrefix = 'case_escalations_';
  static const String _timestampPrefix = 'escalation_timestamp_';
  static const String _allEscalationsKey = 'all_sla_escalations';
  
  const SlaEscalationLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<SlaEscalationModel>> getEscalations({required String firmId}) async {
    try {
      final escalationIds = sharedPreferences.getStringList(_firmEscalationsPrefix + firmId) ?? [];
      final escalations = <SlaEscalationModel>[];
      
      for (final escalationId in escalationIds) {
        final escalation = await getEscalation(escalationId: escalationId);
        if (escalation != null) {
          escalations.add(escalation);
        }
      }
      
      // Ordenar por data de criação (mais recentes primeiro)
      escalations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return escalations;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter escalações: $e');
    }
  }

  @override
  Future<void> saveEscalation({required SlaEscalationModel escalation}) async {
    try {
      final key = _keyPrefix + escalation.id;
      final timestampKey = _timestampPrefix + escalation.firmId;
      
      // Salva a escalação
      final jsonString = json.encode(escalation.toJson());
      await sharedPreferences.setString(key, jsonString);
      
      // Salva timestamp da modificação
      await sharedPreferences.setString(
        timestampKey, 
        DateTime.now().toIso8601String(),
      );
      
      // Atualiza listas de escalações
      await _updateEscalationLists(escalation);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao salvar escalação: $e');
    }
  }

  @override
  Future<void> deleteEscalation({required String escalationId}) async {
    try {
      final escalation = await getEscalation(escalationId: escalationId);
      if (escalation == null) return;
      
      final key = _keyPrefix + escalationId;
      await sharedPreferences.remove(key);
      
      // Remove das listas
      await _removeFromEscalationLists(escalation);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao deletar escalação: $e');
    }
  }

  @override
  Future<SlaEscalationModel?> getEscalation({required String escalationId}) async {
    try {
      final key = _keyPrefix + escalationId;
      final jsonString = sharedPreferences.getString(key);
      
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(jsonMap);
      }
      
      return null;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter escalação: $e');
    }
  }

  @override
  Future<List<SlaEscalationModel>> getEscalationsByCase({required String caseId}) async {
    try {
      final escalationIds = sharedPreferences.getStringList(_caseEscalationsPrefix + caseId) ?? [];
      final escalations = <SlaEscalationModel>[];
      
      for (final escalationId in escalationIds) {
        final escalation = await getEscalation(escalationId: escalationId);
        if (escalation != null) {
          escalations.add(escalation);
        }
      }
      
      // Ordenar por nível de escalação
      escalations.sort((a, b) => (a.currentLevel ?? 0).compareTo(b.currentLevel ?? 0));
      
      return escalations;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter escalações por caso: $e');
    }
  }

  @override
  Future<List<SlaEscalationModel>> getEscalationsByStatus({required String status}) async {
    try {
      final allIds = sharedPreferences.getStringList(_allEscalationsKey) ?? [];
      final escalations = <SlaEscalationModel>[];
      
      for (final escalationId in allIds) {
        final escalation = await getEscalation(escalationId: escalationId);
        if (escalation != null && escalation.status == status) {
          escalations.add(escalation);
        }
      }
      
      return escalations;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter escalações por status: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final allIds = sharedPreferences.getStringList(_allEscalationsKey) ?? [];
      
      for (final escalationId in allIds) {
        await deleteEscalation(escalationId: escalationId);
      }
      
      await sharedPreferences.remove(_allEscalationsKey);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao limpar cache: $e');
    }
  }

  @override
  Future<bool> hasEscalations({required String firmId}) async {
    try {
      final escalationIds = sharedPreferences.getStringList(_firmEscalationsPrefix + firmId) ?? [];
      return escalationIds.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastModified({required String firmId}) async {
    try {
      final timestampKey = _timestampPrefix + firmId;
      final timestampString = sharedPreferences.getString(timestampKey);
      
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveMultipleEscalations({required List<SlaEscalationModel> escalations}) async {
    try {
      for (final escalation in escalations) {
        await saveEscalation(escalation: escalation);
      }
    } catch (e) {
      throw LocalDataSourceException('Erro ao salvar múltiplas escalações: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getEscalationStats({required String firmId}) async {
    try {
      final escalations = await getEscalations(firmId: firmId);
      
      final stats = <String, dynamic>{
        'total': escalations.length,
        'by_status': <String, int>{},
        'by_level': <String, int>{},
        'by_reason': <String, int>{},
        'average_resolution_time': 0.0,
        'pending_count': 0,
        'resolved_count': 0,
      };
      
      var totalResolutionTime = Duration.zero;
      var resolvedCount = 0;
      
      for (final escalation in escalations) {
        // Contar por status
        stats['by_status'][escalation.status] = 
            (stats['by_status'][escalation.status] ?? 0) + 1;
        
        // Contar por nível
        final levelKey = 'level_${escalation.currentLevel ?? 0}';
        stats['by_level'][levelKey] = 
            (stats['by_level'][levelKey] ?? 0) + 1;
        
        // Contar por motivo (usando status como aproximação)
        stats['by_reason'][escalation.status ?? 'unknown'] = 
            (stats['by_reason'][escalation.status ?? 'unknown'] ?? 0) + 1;
        
        // Calcular tempo de resolução
        if (escalation.status == 'resolved' && escalation.executedAt != null) {
          final resolutionTime = escalation.executedAt!.difference(escalation.createdAt);
          totalResolutionTime += resolutionTime;
          resolvedCount++;
        }
        
        // Contar pendentes e resolvidos
        if (escalation.status == 'pending') {
          stats['pending_count'] = (stats['pending_count'] as int) + 1;
        } else if (escalation.status == 'resolved') {
          stats['resolved_count'] = (stats['resolved_count'] as int) + 1;
        }
      }
      
      // Calcular tempo médio de resolução
      if (resolvedCount > 0) {
        stats['average_resolution_time'] = 
            totalResolutionTime.inHours / resolvedCount;
      }
      
      return stats;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter estatísticas de escalações: $e');
    }
  }

  /// Atualiza listas de escalações
  Future<void> _updateEscalationLists(SlaEscalationModel escalation) async {
    // Atualizar lista geral
    final allIds = sharedPreferences.getStringList(_allEscalationsKey) ?? [];
    if (!allIds.contains(escalation.id)) {
      allIds.add(escalation.id);
      await sharedPreferences.setStringList(_allEscalationsKey, allIds);
    }
    
    // Atualizar lista por firma
    final firmKey = _firmEscalationsPrefix + escalation.firmId;
    final firmIds = sharedPreferences.getStringList(firmKey) ?? [];
    if (!firmIds.contains(escalation.id)) {
      firmIds.add(escalation.id);
      await sharedPreferences.setStringList(firmKey, firmIds);
    }
    
    // Atualizar lista por caso
    final caseKey = _caseEscalationsPrefix + (escalation.caseId ?? '');
    final caseIds = sharedPreferences.getStringList(caseKey) ?? [];
    if (!caseIds.contains(escalation.id)) {
      caseIds.add(escalation.id);
      await sharedPreferences.setStringList(caseKey, caseIds);
    }
  }

  /// Remove escalação das listas
  Future<void> _removeFromEscalationLists(SlaEscalationModel escalation) async {
    // Remover da lista geral
    final allIds = sharedPreferences.getStringList(_allEscalationsKey) ?? [];
    if (allIds.contains(escalation.id)) {
      allIds.remove(escalation.id);
      await sharedPreferences.setStringList(_allEscalationsKey, allIds);
    }
    
    // Remover da lista por firma
    final firmKey = _firmEscalationsPrefix + escalation.firmId;
    final firmIds = sharedPreferences.getStringList(firmKey) ?? [];
    if (firmIds.contains(escalation.id)) {
      firmIds.remove(escalation.id);
      await sharedPreferences.setStringList(firmKey, firmIds);
    }
    
    // Remover da lista por caso
    final caseKey = _caseEscalationsPrefix + (escalation.caseId ?? '');
    final caseIds = sharedPreferences.getStringList(caseKey) ?? [];
    if (caseIds.contains(escalation.id)) {
      caseIds.remove(escalation.id);
      await sharedPreferences.setStringList(caseKey, caseIds);
    }
  }
}

/// Exception específica para erros de data source local
class LocalDataSourceException implements Exception {
  final String message;
  
  const LocalDataSourceException(this.message);
  
  @override
  String toString() => 'LocalDataSourceException: $message';
}