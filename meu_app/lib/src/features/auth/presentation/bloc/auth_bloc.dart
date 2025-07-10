import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  AuthBloc({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);

    // Listen to auth state changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        final user = data.user;
        add(AuthUserChanged(user));
      },
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        final userRole = _getUserRole(user);
        emit(AuthenticatedState(user: user, userRole: userRole));
      } else {
        emit(const UnauthenticatedState());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        final userRole = _getUserRole(response.user!);
        emit(AuthenticatedState(user: response.user!, userRole: userRole));
      } else {
        emit(const AuthError(message: 'Falha na autenticação'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _supabase.auth.signOut();
      emit(const UnauthenticatedState());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;

    if (user != null) {
      final userRole = _getUserRole(user);
      emit(AuthenticatedState(user: user, userRole: userRole));
    } else {
      emit(const UnauthenticatedState());
    }
  }

  String _getUserRole(User user) {
    // Extrair role dos metadados do usuário
    final metadata = user.userMetadata;
    return metadata?['role'] ?? 'client';
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
} 