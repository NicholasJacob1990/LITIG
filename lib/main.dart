import 'package:flutter/material.dart';
import 'package:meu_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:meu_app/src/features/auth/presentation/screens/register_client_screen.dart';
import 'package:meu_app/src/features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LITIG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register-client': (context) => const RegisterClientScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}     );
  }
} 
