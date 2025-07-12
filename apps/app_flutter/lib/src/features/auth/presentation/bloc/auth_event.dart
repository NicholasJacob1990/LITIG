import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'dart:io';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar o estado de autenticação atual
class AuthStateChanged extends AuthEvent {
  final User? user;
  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Evento para realizar login
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {}

/// Evento para registrar um cliente
class AuthRegisterClientRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String userType;
  final String? cpf;
  final String? cnpj;

  const AuthRegisterClientRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.userType,
    this.cpf,
    this.cnpj,
  });

  @override
  List<Object?> get props => [email, password, name, userType, cpf, cnpj];
}

/// Evento para registrar um advogado
class AuthRegisterLawyerRequested extends AuthEvent {
  // Step 1
  final String email;
  final String password;
  final String name;
  final String cpf;
  final String? cnpj; // Adicionado
  final String phone;
  
  // Step 2
  final String oab;
  final String areas;
  final int maxCases;
  final String cep;
  final String address;
  final String city;
  final String state;

  // Step 3
  final File? cvFile;
  final File? oabFile;
  final File? residenceProofFile;

  // Step 4
  final String? gender;
  final String? ethnicity;
  final bool isPcd;
  
  // Step 5
  final bool agreedToTerms;
  final String userType; // Adicionado

  const AuthRegisterLawyerRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.cpf,
    this.cnpj, // Adicionado
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
    required this.userType, // Adicionado
  });

  @override
  List<Object?> get props => [
    email, password, name, cpf, cnpj, phone, oab, areas, maxCases, cep, address, city, state,
    cvFile, oabFile, residenceProofFile, gender, ethnicity, isPcd, agreedToTerms, userType // Adicionado
  ];
}

/// Evento para realizar logout
class AuthLogoutRequested extends AuthEvent {}

/// Evento para verificar o status de autenticação na inicialização
class AuthCheckStatusRequested extends AuthEvent {} 