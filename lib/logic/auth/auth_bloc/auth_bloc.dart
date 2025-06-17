import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '/data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthStartedInitialCheck>(_onInitialCheck);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        add(AuthStarted(user));
      } else {
        add(AuthSignOutRequested());
      }
    });
  }

  // Startup check for Firebase persistence
  Future<void> _onInitialCheck(AuthStartedInitialCheck event, Emitter<AuthState> emit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        role: event.role,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      // No emit — wait for authStateChanges
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(error: e.message ?? 'Signup failed'));
    } on FirebaseException catch (e) {
      emit(AuthFailure(error: 'Firestore error: ${e.message}'));
    } catch (e) {
      emit(AuthFailure(error: 'Unexpected error: $e'));
    }
  }

  Future<void> _onSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(error: e.message ?? 'Sign-in failed'));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final uid = json['uid'] as String?;

    // Firebase must be fully initialized at this point
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.uid == uid && user.email == email) {
      return AuthAuthenticated(user);
    }

    return AuthUnauthenticated(); // fallback if rehydration is invalid
  }


  @override
  Map<String, dynamic>? toJson(AuthState state) {
    if (state is AuthAuthenticated) {
      return {
        'uid': state.user.uid,
        'email': state.user.email,
      };
    }
    return null;
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
