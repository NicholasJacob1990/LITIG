import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Serviço de autenticação social unificada via Unipile SDK
/// 
/// Gerencia conexões com LinkedIn, Instagram e Facebook através
/// dos endpoints FastAPI que utilizam o Unipile SDK.
class SocialAuthService {
  final Dio _dio;
  
  SocialAuthService(this._dio);

  /// Conecta conta do LinkedIn
  Future<SocialConnectionResult> connectLinkedIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2.2/unipile/connect-linkedin',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SocialConnectionResult.success(
          provider: 'linkedin',
          accountData: response.data['account_data'],
          message: response.data['message'],
        );
      } else {
        return SocialConnectionResult.error(
          provider: 'linkedin',
          message: response.data['detail'] ?? 'Erro desconhecido',
        );
      }
    } on DioException catch (e) {
      return SocialConnectionResult.error(
        provider: 'linkedin',
        message: e.response?.data['detail'] ?? 'Erro de conexão',
      );
    } catch (e) {
      return SocialConnectionResult.error(
        provider: 'linkedin',
        message: 'Erro inesperado: $e',
      );
    }
  }

  /// Conecta conta do Instagram
  Future<SocialConnectionResult> connectInstagram({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2.2/unipile/connect-instagram',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SocialConnectionResult.success(
          provider: 'instagram',
          accountData: response.data['account_data'],
          message: response.data['message'],
        );
      } else {
        return SocialConnectionResult.error(
          provider: 'instagram',
          message: response.data['detail'] ?? 'Erro desconhecido',
        );
      }
    } on DioException catch (e) {
      return SocialConnectionResult.error(
        provider: 'instagram',
        message: e.response?.data['detail'] ?? 'Erro de conexão',
      );
    } catch (e) {
      return SocialConnectionResult.error(
        provider: 'instagram',
        message: 'Erro inesperado: $e',
      );
    }
  }

  /// Conecta conta do Facebook
  Future<SocialConnectionResult> connectFacebook({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2.2/unipile/connect-facebook',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SocialConnectionResult.success(
          provider: 'facebook',
          accountData: response.data['account_data'],
          message: response.data['message'],
        );
      } else {
        return SocialConnectionResult.error(
          provider: 'facebook',
          message: response.data['detail'] ?? 'Erro desconhecido',
        );
      }
    } on DioException catch (e) {
      return SocialConnectionResult.error(
        provider: 'facebook',
        message: e.response?.data['detail'] ?? 'Erro de conexão',
      );
    } catch (e) {
      return SocialConnectionResult.error(
        provider: 'facebook',
        message: 'Erro inesperado: $e',
      );
    }
  }

  /// Lista contas sociais conectadas
  Future<List<SocialAccount>> getConnectedAccounts() async {
    try {
      final response = await _dio.get('/api/v2.2/unipile/accounts');

      if (response.statusCode == 200) {
        final accountsData = response.data['accounts'] as List;
        return accountsData
            .map((account) => SocialAccount.fromJson(account))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      debugPrint('Erro ao buscar contas conectadas: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Erro inesperado ao buscar contas: $e');
      return [];
    }
  }

  /// Obtém perfil social do Instagram
  Future<SocialProfile?> getInstagramProfile(String accountId) async {
    try {
      final response = await _dio.get('/api/v2.2/unipile/instagram-profile/$accountId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SocialProfile.fromJson(response.data['instagram_data']);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar perfil Instagram: $e');
      return null;
    }
  }

  /// Obtém perfil social do Facebook
  Future<SocialProfile?> getFacebookProfile(String accountId) async {
    try {
      final response = await _dio.get('/api/v2.2/unipile/facebook-profile/$accountId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SocialProfile.fromJson(response.data['facebook_data']);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar perfil Facebook: $e');
      return null;
    }
  }

  /// Obtém dados sociais consolidados de um advogado
  Future<LawyerSocialData?> getLawyerSocialData(String lawyerId) async {
    try {
      final response = await _dio.get('/api/v2.2/unipile/social-profiles/$lawyerId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return LawyerSocialData.fromJson(response.data['social_data']);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar dados sociais do advogado: $e');
      return null;
    }
  }

  /// Sincroniza dados sociais
  Future<bool> syncSocialData(String lawyerId, Map<String, String> platforms) async {
    try {
      final response = await _dio.post(
        '/api/v2.2/unipile/sync-social/$lawyerId',
        data: {'platforms': platforms},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Erro ao sincronizar dados sociais: $e');
      return false;
    }
  }

  /// Verifica saúde da conexão Unipile
  Future<bool> checkHealthStatus() async {
    try {
      final response = await _dio.get('/api/v2.2/unipile/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro no health check: $e');
      return false;
    }
  }
}

/// Resultado de uma tentativa de conexão social
class SocialConnectionResult {
  final bool success;
  final String provider;
  final String message;
  final Map<String, dynamic>? accountData;

  SocialConnectionResult._({
    required this.success,
    required this.provider,
    required this.message,
    this.accountData,
  });

  factory SocialConnectionResult.success({
    required String provider,
    required Map<String, dynamic> accountData,
    required String message,
  }) {
    return SocialConnectionResult._(
      success: true,
      provider: provider,
      message: message,
      accountData: accountData,
    );
  }

  factory SocialConnectionResult.error({
    required String provider,
    required String message,
  }) {
    return SocialConnectionResult._(
      success: false,
      provider: provider,
      message: message,
    );
  }
}

/// Representação de uma conta social conectada
class SocialAccount {
  final String id;
  final String provider;
  final String? email;
  final String status;
  final DateTime? lastSync;

  SocialAccount({
    required this.id,
    required this.provider,
    this.email,
    required this.status,
    this.lastSync,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'],
      provider: json['provider'],
      email: json['email'],
      status: json['status'],
      lastSync: json['last_sync'] != null 
          ? DateTime.parse(json['last_sync'])
          : null,
    );
  }

  bool get isActive => status == 'active';
  
  String get displayName {
    switch (provider) {
      case 'linkedin':
        return 'LinkedIn';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      default:
        return provider.toUpperCase();
    }
  }
}

/// Perfil social com métricas
class SocialProfile {
  final String provider;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> posts;

  SocialProfile({
    required this.provider,
    required this.profile,
    required this.posts,
  });

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      provider: json['provider'],
      profile: json['profile'] ?? {},
      posts: json['posts'] ?? {},
    );
  }

  int get followersCount => profile['followers_count'] ?? 0;
  int get postsCount => posts['total_posts'] ?? 0;
  double get engagementRate => posts['avg_engagement']?.toDouble() ?? 0.0;
}

/// Dados sociais consolidados de um advogado
class LawyerSocialData {
  final Map<String, dynamic> socialScore;
  final Map<String, dynamic> profiles;
  final List<String> recommendations;

  LawyerSocialData({
    required this.socialScore,
    required this.profiles,
    required this.recommendations,
  });

  factory LawyerSocialData.fromJson(Map<String, dynamic> json) {
    return LawyerSocialData(
      socialScore: json['social_score'] ?? {},
      profiles: json['profiles'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  double get overallScore => socialScore['overall_score']?.toDouble() ?? 0.0;
  
  bool get hasLinkedIn => profiles.containsKey('linkedin');
  bool get hasInstagram => profiles.containsKey('instagram');
  bool get hasFacebook => profiles.containsKey('facebook');
  
  int get totalPlatforms => [hasLinkedIn, hasInstagram, hasFacebook].where((x) => x).length;
  
  String get scoreRating {
    if (overallScore >= 0.8) return 'Excelente';
    if (overallScore >= 0.6) return 'Boa';
    if (overallScore >= 0.4) return 'Moderada';
    return 'Baixa';
  }
} 