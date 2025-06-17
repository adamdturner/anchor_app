import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:anchor_app/core/theme/theme_cubit.dart';

import 'package:anchor_app/authenticated_app.dart';
import 'package:anchor_app/firebase_options.dart';

import 'package:anchor_app/data/repositories/auth_repository.dart';

import 'package:anchor_app/logic/auth/auth_bloc/auth_bloc.dart';
import 'package:anchor_app/logic/auth/auth_bloc/auth_event.dart';
import 'package:anchor_app/logic/auth/auth_bloc/auth_state.dart';
import 'package:anchor_app/logic/auth/user_prefs_state/user_prefs_state.dart';

import 'package:anchor_app/presentation/screens/auth/login_screen.dart';
import 'package:anchor_app/presentation/screens/auth/loading_screen.dart';

import 'package:anchor_app/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  HydratedStorage storage;

  if (kIsWeb) {
    // Web-safe: no directory needed
    storage = await HydratedStorage.build(
      storageDirectory: HydratedStorage.webStorageDirectory,
    );
  } else {
    // Mobile-safe: use app documents directory
    final dir = await getApplicationDocumentsDirectory();
    storage = await HydratedStorage.build(
      storageDirectory: dir,
    );
  }

  HydratedBloc.storage = storage;

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
          create: (_) => AuthBloc(authRepository)..add(AuthStartedInitialCheck()),
        ),
        BlocProvider<UserPrefsCubit>(
          create: (_) => UserPrefsCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
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