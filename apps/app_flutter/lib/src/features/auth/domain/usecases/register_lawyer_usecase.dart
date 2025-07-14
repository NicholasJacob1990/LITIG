import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';

class RegisterLawyerUseCase {
  final AuthRepository repository;

  RegisterLawyerUseCase(this.repository);

  Future<void> call(RegisterLawyerParams params) async {
    await repository.registerLawyer(
      email: params.email,
      password: params.password,
      name: params.name,
      cpf: params.cpf,
      cnpj: params.cnpj,
      phone: params.phone,
      oab: params.oab,
      areas: params.areas,
      maxCases: params.maxCases,
      cep: params.cep,
      address: params.address,
      city: params.city,
      state: params.state,
      cvFile: params.cvFile,
      oabFile: params.oabFile,
      residenceProofFile: params.residenceProofFile,
      gender: params.gender,
      ethnicity: params.ethnicity,
      isPcd: params.isPcd,
      agreedToTerms: params.agreedToTerms,
      userType: params.userType,
      isPlatformAssociate: params.isPlatformAssociate, // NOVO: Campo Super Associado
    );
  }
}

class RegisterLawyerParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String cpf;
  final String? cnpj;
  final String phone;
  final String oab;
  final String areas;
  final int maxCases;
  final String cep;
  final String address;
  final String city;
  final String state;
  final File? cvFile;
  final File? oabFile;
  final File? residenceProofFile;
  final String? gender;
  final String? ethnicity;
  final bool isPcd;
  final bool agreedToTerms;
  final String userType;
  final bool isPlatformAssociate;

  const RegisterLawyerParams({
    required this.email,
    required this.password,
    required this.name,
    required this.cpf,
    this.cnpj,
    required this.phone,
    required this.oab,
    required this.areas,
    required this.maxCases,
    required this.cep,
    required this.address,
    required this.city,
    required this.state,
    this.cvFile,
    this.oabFile,
    this.residenceProofFile,
    this.gender,
    this.ethnicity,
    required this.isPcd,
    required this.agreedToTerms,
    required this.userType,
    required this.isPlatformAssociate,
  });

  @override
  List<Object?> get props => [
    email, password, name, cpf, phone, oab, areas, maxCases, cep, address, city, state,
    cvFile, oabFile, residenceProofFile, gender, ethnicity, isPcd, agreedToTerms, userType, isPlatformAssociate
  ];
} 