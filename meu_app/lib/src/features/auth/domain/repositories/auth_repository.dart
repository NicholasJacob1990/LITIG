import 'dart:io';

import 'package:meu_app/src/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  
  Future<User?> getCurrentUser();

  Future<void> login({
    required String email,
    required String password,
  });

  Future<void> registerClient({
    required String email,
    required String password,
    required String name,
    required String userType, // 'PF' ou 'PJ'
    String? cpf,
    String? cnpj,
  });

  Future<void> registerLawyer({
    // Step 1
    required String email,
    required String password,
    required String name,
    required String cpf,
    required String phone,
    
    // Step 2
    required String oab,
    required String areas,
    required int maxCases,
    required String cep,
    required String address,
    required String city,
    required String state,

    // Step 3
    File? cvFile,
    File? oabFile,
    File? residenceProofFile,

    // Step 4
    String? gender,
    String? ethnicity,
    required bool isPcd,
    
    // Step 5
    required bool agreedToTerms,
  });

  Future<void> signOut();
} 