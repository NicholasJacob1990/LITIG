import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/services/social_auth_service.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

class SocialConnectionsScreen extends StatefulWidget {
  const SocialConnectionsScreen({super.key});

  @override
  _SocialConnectionsScreenState createState() =>
      _SocialConnectionsScreenState();
}

class _SocialConnectionsScreenState extends State<SocialConnectionsScreen> {
  final _socialAuthService = SocialAuthService();

  bool _isLinkedInConnected = false;
  bool _isInstagramConnected = false;
  bool _isFacebookConnected = false;
  bool _isOutlookConnected = false; // Novo estado para Outlook
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexões e Contas'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Conectando..."),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader("Redes Sociais"),
                _buildConnectionCard(
                  platform: 'LinkedIn',
                  description: 'Conecte seu perfil profissional',
                  svgAsset: 'assets/icons/linkedin.svg',
                  color: const Color(0xFF0077B5),
                  isConnected: _isLinkedInConnected,
                  onTap: () => _connectLinkedIn(),
                ),
                const SizedBox(height: 16),
                _buildConnectionCard(
                  platform: 'Instagram',
                  description: 'Mostre seu lado pessoal e profissional',
                  svgAsset: 'assets/icons/instagram.svg',
                  color: const Color(0xFFE4405F),
                  isConnected: _isInstagramConnected,
                  onTap: () => _showConnectionDialog('Instagram'),
                ),
                const SizedBox(height: 16),
                _buildConnectionCard(
                  platform: 'Facebook',
                  description: 'Comunicação adicional com clientes',
                  svgAsset: 'assets/icons/facebook.svg',
                  color: const Color(0xFF1877F2),
                  isConnected: _isFacebookConnected,
                  onTap: () => _showConnectionDialog('Facebook'),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("Contas de Email e Calendário"),
                _buildConnectionCard(
                  platform: 'Outlook',
                  description: 'Conecte seu email e calendário',
                  svgAsset: 'assets/icons/outlook.svg', // Caminho corrigido para o novo ícone
                  color: const Color(0xFF0078D4),
                  isConnected: _isOutlookConnected,
                  onTap: () => _connectOutlook(),
                ),
                 const SizedBox(height: 16),
                _buildConnectionCard(
                  platform: 'Google Calendar',
                  description: 'Sincronize seus eventos',
                  svgAsset: 'assets/icons/google_calendar.svg',
                  color: const Color(0xFF34A853),
                  isConnected: false, // Adicionar lógica se necessário
                  onTap: () {
                    // Lógica para conectar Google Calendar
                  },
                ),
                const SizedBox(height: 32),
                _buildBenefitsCard(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildConnectionCard({
    required String platform,
    required String description,
    required String svgAsset, // Mudar para svgAsset
    required Color color,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    // Lista de plataformas com logos multicoloridos que não devem ser pintados.
    const multicolorPlatforms = ['Outlook', 'Google Calendar'];
    final bool applyColorFilter = !multicolorPlatforms.contains(platform);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset( // Usar SvgPicture
                svgAsset,
                width: 24,
                height: 24,
                // Aplica o filtro de cor apenas se não for um logo multicolorido
                colorFilter: applyColorFilter ? ColorFilter.mode(color, BlendMode.srcIn) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(platform, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isConnected ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? AppColors.success : color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isConnected ? 'Conectado' : 'Conectar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LucideIcons.sparkles, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Benefícios das Conexões', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 12),
            const Text(
              '• Perfil mais completo e confiável\n'
              '• Validação automática de dados\n'
              '• Canais adicionais de comunicação\n'
              '• Melhor posicionamento no ranking\n',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _connectLinkedIn() {
    // TODO: Implementar conexão com LinkedIn
    _showConnectionDialog('LinkedIn');
  }

  void _connectOutlook() {
    // Para OAuth, geralmente não se usa um dialog de usuário/senha.
    // A chamada ao service deve iniciar o fluxo OAuth no navegador.
    _handleConnection(context, 'Outlook', '', '');
  }

  void _showConnectionDialog(String platform) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conectar $platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Usuário/Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => _handleConnection(context, platform, usernameController.text, passwordController.text),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnection(BuildContext context, String platform, String username, String password) async {
    Navigator.of(context).pop(); // Fecha o dialog
    setState(() => _isConnecting = true);

    try {
      dynamic result;
      if (platform == 'Instagram') {
        result = await _socialAuthService.connectInstagram(username: username, password: password);
        if (result['success']) setState(() => _isInstagramConnected = true);
      } else if (platform == 'Facebook') {
        result = await _socialAuthService.connectFacebook(username: username, password: password);
        if (result['success']) setState(() => _isFacebookConnected = true);
      } else if (platform == 'LinkedIn') {
        // Chamar método de conexão do LinkedIn aqui quando implementado
        // result = await _socialAuthService.connectLinkedIn(username: username, password: password);
        // if (result['success']) setState(() => _isLinkedInConnected = true);
        throw Exception("Conexão com LinkedIn ainda não implementada.");
      } else if (platform == 'Outlook') {
        // result = await _socialAuthService.connectOutlook(); // Sem user/pass
        // if (result['success']) setState(() => _isOutlookConnected = true);
        throw Exception("Conexão com Outlook ainda não implementada no backend.");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform conectado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }
} 