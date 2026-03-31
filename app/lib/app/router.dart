import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:imjang_app/features/auth/presentation/screens/login_screen.dart';
import 'package:imjang_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:imjang_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:imjang_app/features/complex/presentation/screens/complex_detail_screen.dart';
import 'package:imjang_app/features/complex/presentation/screens/complex_search_screen.dart';

/// Placeholder HomeScreen — router_test.dart expects Text('HomeScreen')
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('임장노트')),
      body: const Center(child: Text('HomeScreen')),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: '단지'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final currentPath = state.uri.path;

      // While loading auth state, show splash
      if (isLoading) return null;

      final isAuthRoute =
          currentPath == '/login' || currentPath == '/signup';
      final isSplash = currentPath == '/';

      if (!isLoggedIn) {
        // Not authenticated: allow auth routes, redirect everything else to /login
        if (isAuthRoute) return null;
        return '/login';
      } else {
        // Authenticated: redirect auth routes and splash to /home
        if (isAuthRoute || isSplash) return '/home';
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const ComplexSearchScreen(),
      ),
      GoRoute(
        path: '/complex/:id',
        builder: (context, state) {
          final complexId = state.pathParameters['id']!;
          return ComplexDetailScreen(complexId: complexId);
        },
      ),
    ],
  );
});
