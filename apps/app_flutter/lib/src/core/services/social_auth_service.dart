import 'package:dio/dio.dart';
import 'package:meu_app/src/core/services/dio_service.dart';

/// Serviço para autenticação e interação com APIs de redes sociais
/// através do nosso backend.
class SocialAuthService {
  static const String _baseUrl = '/api/v1';

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
      throw Exception('Ocorreu um erro inesperado: $e');
    }
  }
}       throw Exception(result['error'] ?? 'Falha na conexão');
    } catch (e) {
      Logger.error('Erro ao conectar Instagram', {'error': e.toString()});
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Conecta conta de email (Gmail/Outlook) usando Unipile V2
  Future<Map<String, dynamic>> connectEmail({
    required String email,
    required String provider, // 'gmail' ou 'outlook'
  }) async {
    try {
      Logger.info('Conectando email via Unipile V2', {
        'email': email,
        'provider': provider,
      });

      late Map<String, dynamic> result;
      
      if (provider == 'gmail') {
        result = await _unipileService.connectGmail(email: email);
      } else if (provider == 'outlook') {
        result = await _unipileService.connectOutlook(email: email);
      } else {
        throw Exception('Provider não suportado: $provider');
      }

      if (result['success'] == true) {
        await _saveUserSocialAccount(
          platform: provider,
          accountData: result['data'],
        );

        Logger.info('Email conectado com sucesso');
        return {
          'success': true,
          'account_id': result['data']?['account_id'],
          'platform': provider,
          'email': email,
        };
      }

      throw Exception(result['error'] ?? 'Falha na conexão');
    } catch (e) {
      Logger.error('Erro ao conectar email', {'error': e.toString()});
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Lista todas as contas sociais conectadas
  Future<List<Map<String, dynamic>>> getConnectedAccounts() async {
    try {
      Logger.info('Buscando contas conectadas via Unipile V2');

      final result = await _unipileService.getAccounts();
      
      if (result['success'] == true) {
        final accounts = result['data'] as List<dynamic>? ?? [];
        return accounts.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      Logger.error('Erro ao buscar contas conectadas', {'error': e.toString()});
      return [];
    }
  }

  /// Desconecta uma conta social
  Future<bool> disconnectAccount(String accountId) async {
    try {
      Logger.info('Desconectando conta', {'account_id': accountId});

      final result = await _unipileService.deleteAccount(accountId);
      
      if (result['success'] == true) {
        // Remover do Supabase também
        await _supabase
            .from('user_social_accounts')
            .delete()
            .eq('account_id', accountId);

        Logger.info('Conta desconectada com sucesso');
        return true;
      }

      return false;
    } catch (e) {
      Logger.error('Erro ao desconectar conta', {'error': e.toString()});
      return false;
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

      Logger.info('Conta social salva no Supabase', {
        'platform': platform,
        'account_id': accountData['account_id'],
      });
    } catch (e) {
      Logger.error('Erro ao salvar conta social', {'error': e.toString()});
      // Não propagar o erro para não quebrar o fluxo principal
    }
  }
} 
