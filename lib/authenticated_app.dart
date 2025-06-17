import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '/routes/app_router.dart';

import 'package:anchor_app/presentation/screens/dashboard/dashboard_screen.dart';


class AuthenticatedApp extends StatelessWidget {
  final String uid;
  const AuthenticatedApp({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // print('[AuthenticatedApp] Entered with UID: $uid');         // debugging
    return MultiProvider(
      providers: [
        
        // list any repositories that are used by more than one bloc
        // it's best to just have one instance of each repository

      ],
      child: MultiBlocProvider(
        providers: [
          
          
          // list any bloc providers that will be used when the app in 
          // the authenticated state

        ],
        child: MaterialApp(
          title: 'Grapevine Authenticated',
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.authenticatedRoutes,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
