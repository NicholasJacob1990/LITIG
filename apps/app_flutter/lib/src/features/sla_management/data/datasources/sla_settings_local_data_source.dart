import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sla_settings_model.dart';

/// Data source local para configurações SLA
/// 
/// Responsável pelo armazenamento local das configurações SLA
/// usando SharedPreferences para persistência offline
abstract class SlaSettingsLocalDataSource {
  /// Obtém configurações SLA do armazenamento local
  Future<SlaSettingsModel?> getSettings({required String firmId});
  
  /// Salva configurações SLA no armazenamento local
  Future<void> saveSettings({required SlaSettingsModel settings});
  
  /// Remove configurações SLA do armazenamento local
  Future<void> deleteSettings({required String firmId});
  
  /// Obtém todas as configurações salvas localmente
  Future<List<SlaSettingsModel>> getAllSettings();
  
  /// Limpa todo o cache local
  Future<void> clearCache();
  
  /// Verifica se há configurações salvas para uma firma
  Future<bool> hasSettings({required String firmId});
  
  /// Obtém timestamp da última modificação
  Future<DateTime?> getLastModified({required String firmId});
  
  /// Salva configurações de backup
  Future<void> saveBackup({required String firmId, required Map<String, dynamic> data});
  
  /// Restaura configurações de backup
  Future<SlaSettingsModel?> restoreBackup({required String firmId});
}

class SlaSettingsLocalDataSourceImpl implements SlaSettingsLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _keyPrefix = 'sla_settings_';
  static const String _backupPrefix = 'sla_backup_';
  static const String _timestampPrefix = 'sla_timestamp_';
  static const String _allSettingsKey = 'all_sla_settings';
  
  const SlaSettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<SlaSettingsModel?> getSettings({required String firmId}) async {
    try {
      final key = _keyPrefix + firmId;
      final jsonString = sharedPreferences.getString(key);
      
      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(jsonMap);
      }
      
      return null;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter configurações locais: $e');
    }
  }

  @override
  Future<void> saveSettings({required SlaSettingsModel settings}) async {
    try {
      final key = _keyPrefix + settings.firmId;
      final timestampKey = _timestampPrefix + settings.firmId;
      
      // Salva as configurações
      final jsonString = json.encode(settings.toJson());
      await sharedPreferences.setString(key, jsonString);
      
      // Salva timestamp da modificação
      await sharedPreferences.setString(
        timestampKey, 
        DateTime.now().toIso8601String(),
      );
      
      // Atualiza lista de todas as configurações
      await _updateAllSettingsList(settings.firmId);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao salvar configurações locais: $e');
    }
  }

  @override
  Future<void> deleteSettings({required String firmId}) async {
    try {
      final key = _keyPrefix + firmId;
      final timestampKey = _timestampPrefix + firmId;
      final backupKey = _backupPrefix + firmId;
      
      await Future.wait([
        sharedPreferences.remove(key),
        sharedPreferences.remove(timestampKey),
        sharedPreferences.remove(backupKey),
      ]);
      
      await _removeFromAllSettingsList(firmId);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao deletar configurações locais: $e');
    }
  }

  @override
  Future<List<SlaSettingsModel>> getAllSettings() async {
    try {
      final firmIds = sharedPreferences.getStringList(_allSettingsKey) ?? [];
      final settings = <SlaSettingsModel>[];
      
      for (final firmId in firmIds) {
        final setting = await getSettings(firmId: firmId);
        if (setting != null) {
          settings.add(setting);
        }
      }
      
      return settings;
    } catch (e) {
      throw LocalDataSourceException('Erro ao obter todas as configurações: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final firmIds = sharedPreferences.getStringList(_allSettingsKey) ?? [];
      
      for (final firmId in firmIds) {
        await deleteSettings(firmId: firmId);
      }
      
      await sharedPreferences.remove(_allSettingsKey);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao limpar cache: $e');
    }
  }

  @override
  Future<bool> hasSettings({required String firmId}) async {
    try {
      final key = _keyPrefix + firmId;
      return sharedPreferences.containsKey(key);
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
  Future<void> saveBackup({required String firmId, required Map<String, dynamic> data}) async {
    try {
      final backupKey = _backupPrefix + firmId;
      final backupData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'firmId': firmId,
      };
      
      final jsonString = json.encode(backupData);
      await sharedPreferences.setString(backupKey, jsonString);
      
    } catch (e) {
      throw LocalDataSourceException('Erro ao salvar backup: $e');
    }
  }

  @override
  Future<SlaSettingsModel?> restoreBackup({required String firmId}) async {
    try {
      final backupKey = _backupPrefix + firmId;
      final jsonString = sharedPreferences.getString(backupKey);
      
      if (jsonString != null) {
        final backupData = json.decode(jsonString) as Map<String, dynamic>;
        final settingsData = backupData['data'] as Map<String, dynamic>;
        
        return SlaSettingsModel.fromJson(settingsData);
      }
      
      return null;
    } catch (e) {
      throw LocalDataSourceException('Erro ao restaurar backup: $e');
    }
  }

  /// Atualiza lista de todas as configurações
  Future<void> _updateAllSettingsList(String firmId) async {
    final firmIds = sharedPreferences.getStringList(_allSettingsKey) ?? [];
    
    if (!firmIds.contains(firmId)) {
      firmIds.add(firmId);
      await sharedPreferences.setStringList(_allSettingsKey, firmIds);
    }
  }

  /// Remove firma da lista de configurações
  Future<void> _removeFromAllSettingsList(String firmId) async {
    final firmIds = sharedPreferences.getStringList(_allSettingsKey) ?? [];
    
    if (firmIds.contains(firmId)) {
      firmIds.remove(firmId);
      await sharedPreferences.setStringList(_allSettingsKey, firmIds);
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