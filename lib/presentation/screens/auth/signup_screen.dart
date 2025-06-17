import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '/logic/auth/auth_bloc.dart';
// import '/logic/auth/auth_event.dart';
// import '/logic/auth/auth_state.dart';

class SignupScreen extends StatelessWidget {
  final String role;

  const SignupScreen({
    super.key,
    required this.role
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      // body: const _SignupForm(),
    );
  }
}
