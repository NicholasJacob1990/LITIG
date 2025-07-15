import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/partnership_card.dart';
import 'package:meu_app/src/shared/widgets/molecules/empty_state_widget.dart';

class PartnershipsScreen extends StatefulWidget {
  const PartnershipsScreen({super.key});

  @override
  State<PartnershipsScreen> createState() => _PartnershipsScreenState();
}

class _PartnershipsScreenState extends State<PartnershipsScreen> {
  @override
  void initState() {
    super.initState();
    // We need to provide the Bloc for this to work.
    // For now, let's assume it's provided above in the widget tree.
    context.read<PartnershipsBloc>().add(FetchPartnerships());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Parcerias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Navigate to create partnership screen
            },
            tooltip: 'Nova Parceria',
          ),
        ],
      ),
      body: BlocBuilder<PartnershipsBloc, PartnershipsState>(
        builder: (context, state) {
          if (state is PartnershipsLoading || state is PartnershipsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PartnershipsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PartnershipsBloc>().add(FetchPartnerships());
                      },
                      child: const Text('Tentar Novamente'),
                    )
                  ],
                ),
              ),
            );
          }
          if (state is PartnershipsLoaded) {
            if (state.partnerships.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.handshake_outlined,
                message: 'Nenhuma parceria encontrada.',
                actionText: 'Buscar novas parcerias',
                onActionPressed: () {
                  // TODO: Implementar navegação para a busca de parceiros
                },
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PartnershipsBloc>().add(FetchPartnerships());
              },
              child: ListView.builder(
                itemCount: state.partnerships.length,
                itemBuilder: (context, index) {
                  final partnership = state.partnerships[index];
                  return PartnershipCard(partnership: partnership);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
} 