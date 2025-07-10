import 'dart:io';

import 'package:meu_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

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
      await remoteDataSource.registerLawyer(
        email: email,
        password: password,
        name: name,
        cpf: cpf,
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
      );
    } on supabase.AuthException catch (e) {
      throw Exception('Falha no registro: ${e.message}');
    }
  }
} 