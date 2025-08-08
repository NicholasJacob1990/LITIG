import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/injection_container.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart' as events;
import 'package:meu_app/src/features/partnerships/presentation/widgets/partnership_card.dart';

class RelatedPartnershipsSection extends StatelessWidget {
  final String caseId;

  const RelatedPartnershipsSection({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PartnershipsBloc>()..add(events.LoadPartnerships()),
      child: BlocBuilder<PartnershipsBloc, PartnershipsState>(
        builder: (context, state) {
          if (state is PartnershipsLoading) {
            return _buildLoading();
          }

          if (state is PartnershipsError) {
            return _buildError(state.message);
          }

          if (state is PartnershipsLoaded) {
            final authState = BlocProvider.of<AuthBloc>(context).state;
            final currentUserId = (authState is Authenticated)
                ? authState.user.id
                : (authState is Authenticated // keep compatibility if names differ
                    ? authState.user.id
                    : null);
            final related = state.partnerships
                .where((p) => (p.linkedCaseId != null && p.linkedCaseId == caseId) || p.isExternalPartnership)
                .toList();

            if (related.isEmpty) {
              return _buildEmpty();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handshake_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Parcerias Relacionadas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...related.map((p) => PartnershipCard(partnership: p, currentUserId: currentUserId)).toList(),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 56,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildError(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Erro ao carregar parcerias: $message')),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      children: const [
        Icon(Icons.link_off, size: 18, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(child: Text('Nenhuma parceria relacionada a este caso.')),
      ],
    );
  }
}


