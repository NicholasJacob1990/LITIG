import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? 'Usuário';
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937), // Fundo escuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937), // Fundo da AppBar escuro
        elevation: 0,
        title: Text(
          'Bem-vindo, ${_userName ?? '...'}',
          style: const TextStyle(color: Colors.white), // Texto branco
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white), // Ícone branco
            onPressed: _signOut,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 64,
                color: Theme.of(context).colorScheme.secondary, // Azul mais claro para destaque
              ),
              const SizedBox(height: 24),
              Text(
                'Seu Problema Jurídico, Resolvido com Inteligência',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Texto branco
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use nossa IA para uma pré-análise gratuita e seja conectado ao advogado certo para o seu caso.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFE2E8F0), // Cinza claro para contraste
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/triage');
                  },
                  icon: const Icon(LucideIcons.sparkles),
                  label: const Text('Iniciar Consulta com IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary, // Azul mais claro
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
