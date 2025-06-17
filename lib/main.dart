import 'package:anchor_app/authenticated_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:anchor_app/data/repositories/auth_repository.dart';
import 'package:anchor_app/logic/auth/auth_bloc.dart';
import 'package:anchor_app/logic/auth/auth_event.dart';
import 'package:anchor_app/logic/auth/auth_state.dart';

import 'package:anchor_app/presentation/screens/auth/login_screen.dart';
import 'package:anchor_app/presentation/screens/auth/loading_screen.dart';

import 'package:anchor_app/routes/app_router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AnchorApp());
}

class AnchorApp extends StatelessWidget {
  const AnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository)..add(AuthStarted()),
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return AuthenticatedApp(uid: state.user.uid);
          } else if (state is AuthUnauthenticated || state is AuthFailure) {
            return MaterialApp(
              home: const LoginScreen(),
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          } else {
            return MaterialApp(
              home: const LoadingScreen(),
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          }
        },
      )
    );
  }
}