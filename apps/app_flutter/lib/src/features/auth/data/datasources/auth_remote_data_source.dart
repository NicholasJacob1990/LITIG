import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> login({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> updateUser({required String fullName});
  Future<void> registerClient({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? cpf,
    String? cnpj,
  });
  Future<void> registerLawyer({
    required String email,
    required String password,
    required String name,
    required String cpf,
    required String phone,
    required String oab,
    required String areas,
    required int maxCases,
    required String cep,
    required String address,
    required String city,
    required String state,
    File? cvFile,
    File? oabFile,
    File? residenceProofFile,
    String? gender,
    String? ethnicity,
    required bool isPcd,
    required bool agreedToTerms,
  });
  Future<void> signOut();
  User? getCurrentSupabaseUser();
  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl(this._supabaseClient)
      : _googleSignIn = GoogleSignIn();

  @override
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  @override
  User? getCurrentSupabaseUser() {
    return _supabaseClient.auth.currentUser;
  }

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // O tratamento de erro será feito no repositório
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // O usuário cancelou o fluxo de login
        return;
      }
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw const AuthException('Google sign in failed: No Access Token found.');
      }
      if (idToken == null) {
        throw const AuthException('Google sign in failed: No ID Token found.');
      }

      await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      // O tratamento de erro será feito no repositório
      rethrow;
    }
  }

  @override
  Future<void> updateUser({required String fullName}) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(
          data: {'full_name': fullName},
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> registerClient({
    required String email,
    required String password,
    required String name,
    required String userType,
    String? cpf,
    String? cnpj,
  }) async {
    try {
      await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'user_type': userType,
          if (cpf != null) 'cpf': cpf,
          if (cnpj != null) 'cnpj': cnpj,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> registerLawyer({
    required String email,
    required String password,
    required String name,
    required String cpf,
    required String phone,
    required String oab,
    required String areas,
    required int maxCases,
    required String cep,
    required String address,
    required String city,
    required String state,
    File? cvFile,
    File? oabFile,
    File? residenceProofFile,
    String? gender,
    String? ethnicity,
    required bool isPcd,
    required bool agreedToTerms,
  }) async {
    try {
       // O ideal é ter uma transação ou uma função de borda no Supabase
       // para garantir atomicidade. Por simplicidade, faremos sequencialmente.

      String? cvFileUrl;
      if (cvFile != null) {
        cvFileUrl = await _uploadFile(cvFile, 'curriculos', 'cv_${DateTime.now().millisecondsSinceEpoch}');
      }

      String? oabFileUrl;
      if (oabFile != null) {
        oabFileUrl = await _uploadFile(oabFile, 'documentos_oab', 'oab_${DateTime.now().millisecondsSinceEpoch}');
      }
      
      String? residenceProofFileUrl;
      if (residenceProofFile != null) {
        residenceProofFileUrl = await _uploadFile(residenceProofFile, 'comprovantes_residencia', 'res_${DateTime.now().millisecondsSinceEpoch}');
      }


      final metadata = {
          'full_name': name,
          'user_type': 'LAWYER',
          'cpf': cpf,
          'phone': phone,
          'oab': oab,
          'areas': areas,
          'max_cases': maxCases.toString(),
          'address': {
            'cep': cep,
            'street': address,
            'city': city,
            'state': state,
          },
          'documents': {
            'cv_url': cvFileUrl,
            'oab_url': oabFileUrl,
            'residence_proof_url': residenceProofFileUrl,
          },
          'diversity': {
            'gender': gender,
            'ethnicity': ethnicity,
            'is_pcd': isPcd,
          },
          'agreed_to_terms': agreedToTerms,
      };

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        throw const AuthException('Falha no registro: usuário não foi criado.');
      }
      
      // TODO: Inserir dados em uma tabela 'lawyers' pública, se necessário,
      // usando o response.user.id como chave estrangeira.

    } catch (e) {
      // TODO: Implementar lógica de rollback para deletar arquivos em caso de falha.
      rethrow;
    }
  }

  Future<String?> _uploadFile(File file, String bucket, String fileName) async {
    try {
      final fileExt = file.path.split('.').last;
      final filePath = '$fileName.$fileExt';
      
      await _supabaseClient.storage.from(bucket).upload(filePath, file);
      
      return _supabaseClient.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      // Não re-lançar a exceção necessariamente, pode ser opcional.
      // Ou, se for crítico, lançar uma exceção específica de storage.
      print('Erro no upload do arquivo para o bucket $bucket: $e');
      return null;
    }
  }


  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
} 