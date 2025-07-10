import 'package:flutter/material.dart';
import 'package:meu_app/src/core/services/api_service.dart';
import 'package:meu_app/src/features/recommendations/presentation/widgets/lawyer_match_card.dart';

class RecomendacoesScreen extends StatefulWidget {
  final String caseId;

  const RecomendacoesScreen({super.key, required this.caseId});

  @override
  State<RecomendacoesScreen> createState() => _RecomendacoesScreenState();
}

class _RecomendacoesScreenState extends State<RecomendacoesScreen> {
  late Future<List<dynamic>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = ApiService.getMatches(widget.caseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advogados Recomendados'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao buscar recomendações: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum advogado encontrado.'));
          }

          final matches = snapshot.data!;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final lawyer = matches[index];
              return LawyerMatchCard(lawyer: lawyer);
            },
          );
        },
      ),
    );
  }
} 
 

class RecomendacoesScreen extends StatefulWidget {
  final String caseId;

  const RecomendacoesScreen({super.key, required this.caseId});

  @override
  State<RecomendacoesScreen> createState() => _RecomendacoesScreenState();
}

class _RecomendacoesScreenState extends State<RecomendacoesScreen> {
  late Future<List<dynamic>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = ApiService.getMatches(widget.caseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advogados Recomendados'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao buscar recomendações: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum advogado encontrado.'));
          }

          final matches = snapshot.data!;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final lawyer = matches[index];
              return LawyerMatchCard(lawyer: lawyer);
            },
          );
        },
      ),
    );
  }
} 
 
 