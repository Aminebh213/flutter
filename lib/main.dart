// lib/main.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/gestion_contact.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true, // utile en dev pour voir le routing dans la console
  routes: <GoRoute>[
    GoRoute(
      name: 'signin',
      path: '/',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      name: 'signup',
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      name: 'contacts',
      path: '/contacts',
      builder: (context, state) {
        // récupérer userEmail passé via state.extra (optionnel)
        String userEmail = '';
        final extra = state.extra;
        if (extra is Map && extra['userEmail'] is String) {
          userEmail = (extra['userEmail'] as String);
        }
        return GestionContactPage(userEmail: userEmail);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gestion des Contacts',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,

      // Theme clair
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),

      // Theme sombre
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),

      themeMode: ThemeMode.system,
    );
  }
}
