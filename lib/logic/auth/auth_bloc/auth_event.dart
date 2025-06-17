import 'package:firebase_auth/firebase_auth.dart';


abstract class AuthEvent {}

class AuthStartedInitialCheck extends AuthEvent {}

class AuthStarted extends AuthEvent {
  final User user;

  AuthStarted(this.user);
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String firstName;
  final String lastName;

  AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
  });
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  AuthSignInRequested({required this.email, required this.password});
}

class AuthResetPasswordRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}
