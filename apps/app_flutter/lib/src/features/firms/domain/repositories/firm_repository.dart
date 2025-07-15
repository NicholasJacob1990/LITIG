import '../entities/law_firm.dart';
import '../entities/firm_kpi.dart';
import '../entities/firm_stats.dart';
import '../entities/lawyer.dart';
import '../../../../core/utils/result.dart';

/// Repositório abstrato para operações relacionadas a escritórios
/// 
/// Esta interface define os contratos para todas as operações de escritórios,
/// mantendo o domínio independente de implementações específicas.
abstract class FirmRepository {
  /// Busca uma lista de escritórios com filtros opcionais
  /// 
  /// Retorna [Result.success] com lista de escritórios ou [Result.failure] com falha
  Future<Result<List<LawFirm>>> getFirms({
    int limit = 50,
    int offset = 0,
    bool includeKpis = true,
    bool includeLawyersCount = true,
    double? minSuccessRate,
    int? minTeamSize,
  });

  /// Busca um escritório específico por ID
  /// 
  /// Retorna [Result.success] com escritório ou [Result.failure] com falha
  /// Se não encontrado, retorna [Result.success] com null
  Future<Result<LawFirm?>> getFirmById(
    String firmId, {
    bool includeKpis = true,
    bool includeLawyersCount = true,
  });

  /// Busca estatísticas agregadas dos escritórios
  /// 
  /// Retorna [Result.success] com estatísticas ou [Result.failure] com falha
  Future<Result<FirmStats>> getFirmStats();

  /// Busca KPIs específicos de um escritório
  /// 
  /// Retorna [Result.success] com KPIs ou [Result.failure] com falha
  /// Se não encontrado, retorna [Result.success] com null
  Future<Result<FirmKPI?>> getFirmKpis(String firmId);

  /// Busca advogados de um escritório específico
  /// 
  /// Retorna [Result.success] com a lista de advogados ou [Result.failure] com falha
  Future<Result<List<Lawyer>>> getFirmLawyers(
    String firmId, {
    int limit = 50,
    int offset = 0,
  });

  /// Cria um novo escritório (admin only)
  /// 
  /// Retorna [Result.success] com escritório criado ou [Result.failure] com falha
  Future<Result<LawFirm>> createFirm(Map<String, dynamic> firmData);

  /// Atualiza dados de um escritório
  /// 
  /// Retorna [Result.success] com escritório atualizado ou [Result.failure] com falha
  Future<Result<LawFirm>> updateFirm(
    String firmId, 
    Map<String, dynamic> firmData,
  );

  /// Atualiza ou cria KPIs de um escritório
  /// 
  /// Retorna [Result.success] com KPIs atualizados ou [Result.failure] com falha
  Future<Result<FirmKPI>> updateFirmKpis(
    String firmId, 
    Map<String, dynamic> kpiData,
  );

  /// Deleta um escritório (admin only)
  /// 
  /// Retorna [Result.success] com true se deletado ou [Result.failure] com falha
  Future<Result<bool>> deleteFirm(String firmId);
} 