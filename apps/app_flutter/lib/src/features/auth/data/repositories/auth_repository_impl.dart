import 'dart:io';

import 'package:meu_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:meu_app/src/features/auth/data/models/user_model.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/auth/domain/errors/auth_exceptions.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((authState) {
      final supabaseUser = authState.session?.user;
      if (supabaseUser != null) {
        return UserModel.fromSupabase(supabaseUser);
      }
      return null;
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final supabaseUser = remoteDataSource.getCurrentSupabaseUser();
    if (supabaseUser != null) {
      return UserModel.fromSupabase(supabaseUser);
    }
    return null;
  }

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      await remoteDataSource.login(email: email, password: password);
    } on supabase.AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid grant')) {
        throw const InvalidCredentialsException();
      }
      throw ServerException(e.message);
    } catch (e) {
      throw const NetworkException();
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await remoteDataSource.signInWithGoogle();
    } on supabase.AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw const NetworkException();
    }
  }

  @override
  Future<void> updateUser({required String fullName}) async {
    try {
      await remoteDataSource.updateUser(fullName: fullName);
    } catch (e) {
      throw const ServerException('Falha ao atualizar dados do usuário.');
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
      await remoteDataSource.registerClient(
        email: email,
        password: password,
        name: name,
        userType: userType,
        cpf: cpf,
        cnpj: cnpj,
      );
    } on supabase.AuthException catch (e) {
      if (e.message.toLowerCase().contains('already in use')) {
        throw const EmailAlreadyInUseException();
      } else if (e.message.toLowerCase().contains('weak password')) {
        throw const WeakPasswordException();
      }
      throw ServerException(e.message);
    } catch (e) {
      throw const NetworkException();
    }
  }

  @override
  Future<void> registerLawyer({
    required String email,
    required String password,
    required String name,
    required String cpf,
    String? cnpj,
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
    required String userType,
    required bool isPlatformAssociate,
  }) async {
    try {
      await remoteDataSource.registerLawyer(
        email: email,
        password: password,
        name: name,
        cpf: cpf,
        cnpj: cnpj,
        phone: phone,
        oab: oab,
        areas: areas,
        maxCases: maxCases,
        cep: cep,
        address: address,
        city: city,
        state: state,
        cvFile: cvFile,
        oabFile: oabFile,
        residenceProofFile: residenceProofFile,
        gender: gender,
        ethnicity: ethnicity,
        isPcd: isPcd,
        agreedToTerms: agreedToTerms,
        userType: userType,
        isPlatformAssociate: isPlatformAssociate,
      );
    } on supabase.AuthException catch (e) {
      throw Exception('Falha no registro: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw const ServerException('Falha ao fazer logout.');
    }
  }
} 