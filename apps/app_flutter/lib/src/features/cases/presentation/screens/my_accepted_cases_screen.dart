import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/privacy_cases_bloc.dart';

class MyAcceptedCasesScreen extends StatelessWidget {
  const MyAcceptedCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Casos Aceitos')),
      body: BlocConsumer<PrivacyCasesBloc, PrivacyCasesState>(
        listener: (context, state) {
          if (state is PrivacyCasesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is PrivacyCasesInitial) {
            context.read<PrivacyCasesBloc>().add(LoadMyAcceptedCases());
          }
          if (state is PrivacyCasesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyAcceptedCasesLoaded) {
            if (state.cases.isEmpty) {
              return const Center(child: Text('Nenhum caso aceito ainda.'));
            }
            return ListView.separated(
              itemCount: state.cases.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = state.cases[index];
                return ListTile(
                  title: Text(c.title ?? 'Caso ${c.id}'),
                  subtitle: Text('${c.area ?? 'Geral'} • ${c.status}'),
                  trailing: c.acceptedAt != null
                      ? Text(
                          'Aceito em\n${c.acceptedAt!.toLocal().toString().split(".").first}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
    onTap: () => GoRouter.of(context).push('/case-detail/${c.id}'),
                );
              },
            );
          }
          if (state is PrivacyCasesError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}


