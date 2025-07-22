import 'package:flutter/material.dart';

void main() {
  runApp(const LitigApp());
}

class LitigApp extends StatelessWidget {
  const LitigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LITIG-1 - Sistema Jurídico Avançado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CasesScreen(),
    const LawyersScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel),
            label: 'Casos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Advogados',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LITIG-1 Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo de volta!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gerencie seus casos jurídicos com eficiência',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.account_balance,
                    size: 60,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Cards
            Text(
              'Resumo Geral',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatsCard(
                    context,
                    'Casos Ativos',
                    '24',
                    Icons.gavel,
                    Colors.blue,
                  ),
                  _buildStatsCard(
                    context,
                    'Advogados Parceiros',
                    '128',
                    Icons.people,
                    Colors.green,
                  ),
                  _buildStatsCard(
                    context,
                    'Propostas Pendentes',
                    '15',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  _buildStatsCard(
                    context,
                    'Documentos',
                    '342',
                    Icons.description,
                    Colors.purple,
                  ),
                  _buildStatsCard(
                    context,
                    'Reuniões Hoje',
                    '3',
                    Icons.video_call,
                    Colors.red,
                  ),
                  _buildStatsCard(
                    context,
                    'Taxa de Sucesso',
                    '94%',
                    Icons.trending_up,
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Casos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCaseStatusColor(index),
                child: Text('${index + 1}'),
              ),
              title: Text('Caso Jurídico #${(index + 1).toString().padLeft(3, '0')}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Área: ${_getCaseArea(index)}'),
                  Text('Status: ${_getCaseStatus(index)}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              isThreeLine: true,
              onTap: () {
                _showCaseDetail(context, index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCaseDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCaseStatusColor(int index) {
    List<Color> colors = [Colors.green, Colors.orange, Colors.blue, Colors.red];
    return colors[index % colors.length];
  }

  String _getCaseArea(int index) {
    List<String> areas = ['Civil', 'Penal', 'Trabalhista', 'Tributário', 'Família'];
    return areas[index % areas.length];
  }

  String _getCaseStatus(int index) {
    List<String> statuses = ['Ativo', 'Pendente', 'Em Análise', 'Concluído'];
    return statuses[index % statuses.length];
  }

  void _showCaseDetail(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caso #${(index + 1).toString().padLeft(3, '0')}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Área: ${_getCaseArea(index)}'),
            Text('Status: ${_getCaseStatus(index)}'),
            const Text('Cliente: João Silva'),
            const Text('Advogado Responsável: Dr. Maria Santos'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Caso'),
        content: const Text('Funcionalidade de criação de caso em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class LawyersScreen extends StatelessWidget {
  const LawyersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advogados Disponíveis'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${index + 10}',
                ),
              ),
              title: Text('Dr(a). ${_getLawyerName(index)}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getLawyerSpecialty(index)),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${_getLawyerRating(index)} (${_getReviewCount(index)} avaliações)'),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'R\$ ${_getLawyerPrice(index)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    '/hora',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                _showLawyerProfile(context, index);
              },
            ),
          );
        },
      ),
    );
  }

  String _getLawyerName(int index) {
    List<String> names = [
      'Ana Silva', 'Carlos Santos', 'Maria Oliveira', 'João Ferreira',
      'Fernanda Costa', 'Rafael Lima', 'Juliana Pereira', 'Lucas Alves',
    ];
    return names[index % names.length];
  }

  String _getLawyerSpecialty(int index) {
    List<String> specialties = [
      'Direito Civil', 'Direito Penal', 'Direito Trabalhista', 
      'Direito Tributário', 'Direito de Família',
    ];
    return specialties[index % specialties.length];
  }

  String _getLawyerRating(int index) {
    List<String> ratings = ['4.8', '4.5', '4.9', '4.7', '4.6'];
    return ratings[index % ratings.length];
  }

  String _getReviewCount(int index) {
    return '${20 + (index * 5)}';
  }

  String _getLawyerPrice(int index) {
    List<String> prices = ['150', '200', '180', '220', '175'];
    return prices[index % prices.length];
  }

  void _showLawyerProfile(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=${index + 10}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr(a). ${_getLawyerName(index)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(_getLawyerSpecialty(index)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${_getLawyerRating(index)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Sobre:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Advogado experiente com mais de 10 anos de atuação na área. '
              'Especialista em casos complexos e com histórico de sucesso comprovado.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Experiência:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('• 150+ casos resolvidos\n• Taxa de sucesso: 92%\n• Atendimento em português e inglês'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.message),
                    label: const Text('Enviar Mensagem'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.handshake),
                    label: const Text('Contratar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${index + 20}',
                ),
              ),
              title: Text('Dr(a). ${_getChatName(index)}'),
              subtitle: Text(_getLastMessage(index)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getTime(index),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (index % 3 == 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () {
                _openChat(context, index);
              },
            ),
          );
        },
      ),
    );
  }

  String _getChatName(int index) {
    List<String> names = [
      'Ana Advocacia', 'Carlos Silva', 'Tribunal Regional', 'Maria Santos',
      'João Pereira', 'Fernanda Costa', 'Lucas Almeida', 'Carla Oliveira'
    ];
    return names[index % names.length];
  }

  String _getLastMessage(int index) {
    List<String> messages = [
      'Documentos enviados com sucesso',
      'Reunião agendada para amanhã',
      'Processo atualizado',
      'Proposta aceita',
      'Aguardando confirmação',
      'Audiência marcada',
      'Contrato revisado',
      'Parecer finalizado',
    ];
    return messages[index % messages.length];
  }

  String _getTime(int index) {
    List<String> times = ['14:30', '13:15', '12:45', '11:20', '10:15', '09:30', '08:45', '08:00'];
    return times[index % times.length];
  }

  void _openChat(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatName: _getChatName(index)),
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatName;
  
  const ChatDetailScreen({super.key, required this.chatName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10,
              itemBuilder: (context, index) {
                bool isMe = index % 2 == 0;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _getChatMessage(index),
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatMessage(int index) {
    List<String> messages = [
      'Olá! Como posso ajudá-lo hoje?',
      'Preciso revisar os documentos do processo',
      'Claro! Vou enviar ainda hoje',
      'Perfeito, aguardo o retorno',
      'Documentos enviados por email',
      'Recebidos! Vou analisar',
      'Alguma dúvida sobre o caso?',
      'Não, está tudo claro',
      'Ótimo! Qualquer coisa me chame',
      'Obrigado pelo atendimento!',
    ];
    return messages[index % messages.length];
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=1'),
            ),
            const SizedBox(height: 16),
            Text(
              'João Silva',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Cliente Premium',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Info Cards
            _buildInfoCard(
              context,
              'Informações Pessoais',
              [
                _buildInfoRow(Icons.email, 'joao.silva@email.com'),
                _buildInfoRow(Icons.phone, '+55 (11) 99999-9999'),
                _buildInfoRow(Icons.location_on, 'São Paulo, SP'),
                _buildInfoRow(Icons.business, 'Empresa XYZ Ltda'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoCard(
              context,
              'Estatísticas',
              [
                _buildInfoRow(Icons.gavel, '24 casos ativos'),
                _buildInfoRow(Icons.check_circle, '156 casos concluídos'),
                _buildInfoRow(Icons.star, 'Avaliação: 4.9/5.0'),
                _buildInfoRow(Icons.calendar_today, 'Cliente desde 2022'),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showFeatureDialog(context, 'Editar Perfil');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showFeatureDialog(context, 'Configurações');
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurações'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showFeatureDialog(context, 'Ajuda e Suporte');
                },
                icon: const Icon(Icons.help),
                label: const Text('Ajuda e Suporte'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('Funcionalidade "$feature" em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}