import 'package:dio/dio.dart';
import 'package:meu_app/src/core/services/dio_service.dart';
import 'package:meu_app/src/core/services/unipile_service.dart';
import 'package:meu_app/src/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para autenticação e interação com APIs de redes sociais
/// através do nosso backend.
class SocialAuthService {
  static const String _baseUrl = '/api/v1';
  
  final UnipileService _unipileService;
  final SupabaseClient _supabase;
  
  SocialAuthService({
    UnipileService? unipileService,
    SupabaseClient? supabase,
  }) : _unipileService = unipileService ?? UnipileService(),
       _supabase = supabase ?? Supabase.instance.client;

  /// Conecta uma conta do Instagram.
  ///
  /// Envia as credenciais para o backend, que as utiliza para se conectar
  /// à conta via Unipile SDK.
  Future<Map<String, dynamic>> connectInstagram({
    required String username,
    required String password,
  }) async {
    try {
      final response = await DioService.post(
        '$_baseUrl/instagram/connect',
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Fornece uma mensagem de erro mais clara para o usuário
      final errorMsg = e.response?.data?['detail'] ?? 'Erro desconhecido';
      throw Exception('Falha ao conectar Instagram: $errorMsg');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: $e');
    }
  }

  /// Conecta uma conta do Facebook.
  ///
  /// Envia as credenciais para o backend para conexão via Unipile.
  Future<Map<String, dynamic>> connectFacebook({
    required String username,
    required String password,
  }) async {
    try {
      final response = await DioService.post(
        '$_baseUrl/facebook/connect',
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? 'Erro desconhecido';
      throw Exception('Falha ao conectar Facebook: $errorMsg');
    } catch (e) {
      throw Exception('Erro ao conectar Facebook: $e');
    }
  }

  /// Conecta conta Outlook
  Future<Map<String, dynamic>> connectOutlook() async {
    try {
      // Para OAuth, a requisição pode não precisar de um corpo,
      // a API pode retornar uma URL de redirecionamento.
      final response = await DioService.post(
        '$_baseUrl/outlook/connect',
      );
      return response.data;
    } catch (e) {
      throw Exception('Erro ao conectar Outlook: $e');
    }
  }

  /// Busca um perfil público do Instagram.
  ///
  /// Utiliza a conta conectada do usuário para autenticar a chamada.
  Future<Map<String, dynamic>> getInstagramProfile(String username) async {
    try {
      final response = await DioService.get(
        '$_baseUrl/instagram/profile/$username',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? 'Erro desconhecido';
      throw Exception('Falha ao buscar perfil do Instagram: $errorMsg');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: $e');
    }
  }

  /// Busca os perfis sociais consolidados do usuário logado.
  Future<Map<String, dynamic>> getMySocialProfiles() async {
    try {
      final response = await DioService.get(
        '$_baseUrl/social/profiles/me',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? 'Erro desconhecido';
      throw Exception('Falha ao buscar perfis sociais: $errorMsg');
    } catch (e) {
      AppLogger.error('Erro ao conectar Instagram', {'error': e.toString()});
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtém todas as contas conectadas do usuário
  Future<List<Map<String, dynamic>>> getConnectedAccounts() async {
    try {
      AppLogger.info('Buscando contas conectadas via Unipile V2');
      
      final accounts = await _unipileService.getAccounts();
      return accounts.map((account) => account.toJson()).toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar contas conectadas', {'error': e.toString()});
      return [];
    }
  }

  /// Desconecta uma conta específica
  Future<bool> disconnectAccount(String accountId) async {
    try {
      AppLogger.info('Desconectando conta', {'account_id': accountId});
      
      await _unipileService.deleteAccount(accountId);
      
      // Remove do Supabase também
      await _supabase
          .from('user_social_accounts')
          .delete()
          .eq('external_account_id', accountId);
      
      AppLogger.info('Conta desconectada com sucesso');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao desconectar conta', {'error': e.toString()});
      return false;
    }
  }

  /// Conecta conta de email (Gmail/Outlook) usando Unipile V2
  Future<Map<String, dynamic>> connectEmail({
    required String email,
    required String provider, // 'gmail' ou 'outlook'
  }) async {
    try {
      AppLogger.info('Conectando email via Unipile V2', {
        'email': email,
        'provider': provider,
      });

      late UnipileAccount account;
      
      if (provider == 'gmail') {
        account = await _unipileService.connectGmail();
      } else if (provider == 'outlook') {
        account = await _unipileService.connectOutlook();
      } else {
        throw Exception('Provider não suportado: $provider');
      }

      await _saveUserSocialAccount(
        platform: provider,
        accountData: account.toJson(),
      );

      AppLogger.info('Email conectado com sucesso');
      return {
        'success': true,
        'account_id': account.id,
        'platform': provider,
        'email': account.email,
      };
    } catch (e) {
      AppLogger.error('Erro ao conectar email', {'error': e.toString()});
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Salva informações da conta social no Supabase
  Future<void> _saveUserSocialAccount({
    required String platform,
    required Map<String, dynamic>? accountData,
  }) async {
    if (accountData == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _supabase.from('user_social_accounts').upsert({
        'user_id': user.id,
        'platform': platform,
        'account_id': accountData['account_id'],
        'account_data': accountData,
        'connected_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      AppLogger.info('Conta social salva no Supabase', {
        'platform': platform,
        'account_id': accountData['account_id'],
      });
    } catch (e) {
      AppLogger.error('Erro ao salvar conta social', {'error': e.toString()});
      // Não propagar o erro para não quebrar o fluxo principal
    }
  }
} 
