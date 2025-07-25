import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'premium_criteria_form.dart'; // Corrigido para importação relativa

class PremiumCriteriaListPage extends StatefulWidget {
  const PremiumCriteriaListPage({super.key});

  @override
  _PremiumCriteriaListPageState createState() => _PremiumCriteriaListPageState();
}

class _PremiumCriteriaListPageState extends State<PremiumCriteriaListPage> {
  late final Future<List<Map<String, dynamic>>> _criteriaFuture;

  @override
  void initState() {
    super.initState();
    _criteriaFuture = _fetchCriteria();
  }

  Future<List<Map<String, dynamic>>> _fetchCriteria() async {
    try {
      final response = await Supabase.instance.client
          .from('premium_criteria')
          .select()
          .order('service_code', ascending: true);
          
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao buscar critérios: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return [];
    }
  }

  Future<void> _toggleEnabled(int id, bool currentValue) async {
    try {
      await Supabase.instance.client
          .from('premium_criteria')
          .update({'enabled': !currentValue})
          .eq('id', id);
      
      // Recarrega a lista
      setState(() {
        _criteriaFuture = _fetchCriteria();
      });

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar critério: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  void _navigateToForm([Map<String, dynamic>? criteria]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PremiumCriteriaFormPage(criteria: criteria),
      ),
    ).then((_) {
      // Recarrega a lista quando voltar do formulário
      setState(() {
        _criteriaFuture = _fetchCriteria();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critérios Premium'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _criteriaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum critério encontrado.'));
          }

          final criteriaList = snapshot.data!;

          return ListView.builder(
            itemCount: criteriaList.length,
            itemBuilder: (context, index) {
              final item = criteriaList[index];
              final serviceCode = item['service_code']?.toString().toUpperCase() ?? 'N/A';
              final subserviceCode = item['subservice_code'] ?? '-';
              final minValor = item['min_valor_causa'] ?? '-';
              final minUrgency = item['min_urgency_h'] ?? '-';

              return ListTile(
                title: Text('$serviceCode / $subserviceCode'),
                subtitle: Text('Valor ≥ R\$$minValor · Urg ≤ ${minUrgency}h'),
                trailing: Switch(
                  value: item['enabled'] ?? false,
                  onChanged: (newValue) => _toggleEnabled(item['id'], item['enabled']),
                ),
                onTap: () => _navigateToForm(item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'Novo Critério',
        child: const Icon(Icons.add),
      ),
    );
  }
} 