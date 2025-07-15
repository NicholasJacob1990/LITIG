import 'package:flutter/material.dart';
import '../../domain/entities/partnership.dart';
import '../bloc/partnerships_bloc.dart';
import '../bloc/partnerships_event.dart';
import '../bloc/partnerships_state.dart';
import '../widgets/partnership_card.dart';

class PartnershipsScreen extends StatefulWidget {
  final PartnershipsBloc bloc;

  const PartnershipsScreen({
    super.key,
    required this.bloc,
  });

  @override
  State<PartnershipsScreen> createState() => _PartnershipsScreenState();
}

class _PartnershipsScreenState extends State<PartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.bloc.add(const FetchPartnerships());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcerias'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recebidas'),
            Tab(text: 'Enviadas'),
          ],
        ),
      ),
      body: StreamBuilder<PartnershipsState>(
        stream: widget.bloc.stream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? widget.bloc.state;
          
          if (state is PartnershipsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is PartnershipsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar parcerias',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.bloc.add(const FetchPartnerships()),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          
          if (state is PartnershipsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildPartnershipsList(state.received, 'Nenhuma parceria recebida'),
                _buildPartnershipsList(state.sent, 'Nenhuma parceria enviada'),
              ],
            );
          }
          
          return const Center(
            child: Text('Carregando parcerias...'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePartnershipDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPartnershipsList(List<Partnership> partnerships, String emptyMessage) {
    if (partnerships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.bloc.add(const FetchPartnerships());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: partnerships.length,
        itemBuilder: (context, index) {
          final partnership = partnerships[index];
          return PartnershipCard(
            partnership: partnership,
            onAccept: () => widget.bloc.add(AcceptPartnership(partnership.id)),
            onReject: () => widget.bloc.add(RejectPartnership(partnership.id)),
            onAcceptContract: () => widget.bloc.add(AcceptContract(partnership.id)),
            onGenerateContract: () => widget.bloc.add(GenerateContract(partnership.id)),
          );
        },
      ),
    );
  }

  void _showCreatePartnershipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Parceria'),
        content: const Text('Funcionalidade de criação de parceria será implementada em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
} 