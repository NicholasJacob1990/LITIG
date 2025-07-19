import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/auth/domain/errors/auth_exceptions.dart';
import 'package:meu_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:meu_app/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:meu_app/src/features/auth/domain/usecases/register_client_usecase.dart';
import 'package:meu_app/src/features/auth/domain/usecases/register_lawyer_usecase.dart';
import 'package:meu_app/src/features/auth/domain/usecases/signin_with_google_usecase.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:async';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final LoginUseCase _loginUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final RegisterClientUseCase _registerClientUseCase;
  final RegisterLawyerUseCase _registerLawyerUseCase;
  final LogoutUseCase _logoutUseCase;
  late StreamSubscription<User?> _userSubscription;

  AuthBloc({required this.authRepository})
      : _loginUseCase = LoginUseCase(authRepository),
        _signInWithGoogleUseCase = SignInWithGoogleUseCase(authRepository),
        _registerClientUseCase = RegisterClientUseCase(authRepository),
        _registerLawyerUseCase = RegisterLawyerUseCase(authRepository),
        _logoutUseCase = LogoutUseCase(authRepository),
        super(AuthInitial()) {
    _userSubscription = authRepository.authStateChanges.listen((user) {
      add(AuthStateChanged(user));
    });

    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthLinkedInSignInRequested>(_onLinkedInSignInRequested);
    on<AuthInstagramSignInRequested>(_onInstagramSignInRequested);
    on<AuthFacebookSignInRequested>(_onFacebookSignInRequested);
    on<AuthRegisterClientRequested>(_onRegisterClientRequested);
    on<AuthRegisterLawyerRequested>(_onRegisterLawyerRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(const AuthError('Erro ao verificar status de autenticação.'));
    }
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _loginUseCase(LoginParams(email: event.email, password: event.password));
      // O stream authStateChanges cuidará de emitir o estado Authenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _signInWithGoogleUseCase();
      // O stream authStateChanges cuidará de emitir o estado Authenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido durante o login com Google.'));
    }
  }

  Future<void> _onLinkedInSignInRequested(
    AuthLinkedInSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // TODO: Implementar autenticação LinkedIn via Unipile
      emit(const AuthError('Autenticação LinkedIn em desenvolvimento. Use o sistema de conexões sociais no perfil.'));
    } catch (e) {
      emit(const AuthError('Erro na autenticação LinkedIn.'));
    }
  }

  Future<void> _onInstagramSignInRequested(
    AuthInstagramSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // TODO: Implementar autenticação Instagram via Unipile
      emit(const AuthError('Autenticação Instagram em desenvolvimento. Use o sistema de conexões sociais no perfil.'));
    } catch (e) {
      emit(const AuthError('Erro na autenticação Instagram.'));
    }
  }

  Future<void> _onFacebookSignInRequested(
    AuthFacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // TODO: Implementar autenticação Facebook via Unipile
      emit(const AuthError('Autenticação Facebook em desenvolvimento. Use o sistema de conexões sociais no perfil.'));
    } catch (e) {
      emit(const AuthError('Erro na autenticação Facebook.'));
    }
  }

  Future<void> _onRegisterClientRequested(AuthRegisterClientRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _registerClientUseCase(RegisterClientParams(
        email: event.email,
        password: event.password,
        name: event.name,
        userType: event.userType,
        cpf: event.cpf,
        cnpj: event.cnpj,
      ));
      emit(const AuthSuccess('Registro de cliente realizado com sucesso! Por favor, verifique seu e-mail.'));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  Future<void> _onRegisterLawyerRequested(AuthRegisterLawyerRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _registerLawyerUseCase(RegisterLawyerParams(
        email: event.email,
        password: event.password,
        name: event.name,
        cpf: event.cpf,
        phone: event.phone,
        oab: event.oab,
        areas: event.areas,
        maxCases: event.maxCases,
        cep: event.cep,
        address: event.address,
        city: event.city,
        state: event.state,
        cvFile: event.cvFile,
        oabFile: event.oabFile,
        residenceProofFile: event.residenceProofFile,
        gender: event.gender,
        ethnicity: event.ethnicity,
        isPcd: event.isPcd,
        agreedToTerms: event.agreedToTerms,
        userType: event.userType,
        isPlatformAssociate: event.isPlatformAssociate, // NOVO: Campo Super Associado
      ));
      emit(const AuthSuccess('Registro de advogado realizado com sucesso! Sua conta está em análise.'));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _logoutUseCase();
       // O stream authStateChanges cuidará de emitir o estado Unauthenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
} 
        areas: event.areas,
        maxCases: event.maxCases,
        cep: event.cep,
        address: event.address,
        city: event.city,
        state: event.state,
        cvFile: event.cvFile,
        oabFile: event.oabFile,
        residenceProofFile: event.residenceProofFile,
        gender: event.gender,
        ethnicity: event.ethnicity,
        isPcd: event.isPcd,
        agreedToTerms: event.agreedToTerms,
        userType: event.userType,
        isPlatformAssociate: event.isPlatformAssociate, // NOVO: Campo Super Associado
      ));
      emit(const AuthSuccess('Registro de advogado realizado com sucesso! Sua conta está em análise.'));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _logoutUseCase();
       // O stream authStateChanges cuidará de emitir o estado Unauthenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
} 
        areas: event.areas,
        maxCases: event.maxCases,
        cep: event.cep,
        address: event.address,
        city: event.city,
        state: event.state,
        cvFile: event.cvFile,
        oabFile: event.oabFile,
        residenceProofFile: event.residenceProofFile,
        gender: event.gender,
        ethnicity: event.ethnicity,
        isPcd: event.isPcd,
        agreedToTerms: event.agreedToTerms,
        userType: event.userType,
        isPlatformAssociate: event.isPlatformAssociate, // NOVO: Campo Super Associado
      ));
      emit(const AuthSuccess('Registro de advogado realizado com sucesso! Sua conta está em análise.'));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _logoutUseCase();
       // O stream authStateChanges cuidará de emitir o estado Unauthenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Ocorreu um erro desconhecido.'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
} 