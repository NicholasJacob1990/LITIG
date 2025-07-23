import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/widgets/official_social_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:meu_app/src/features/auth/domain/entities/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          if (state is auth_states.AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildForm(context),
                    const SizedBox(height: 24),
                    _buildDivider(context),
                    const SizedBox(height: 24),
                    _buildSocialLogin(context),
                    const SizedBox(height: 32),
                    _buildRegisterPrompt(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          LucideIcons.shieldCheck,
          size: 64,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: 16),
        Text(
          'Acesse sua Conta',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'E-mail',
              prefixIcon: Icon(LucideIcons.mail),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Senha',
              prefixIcon: const Icon(LucideIcons.lock),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(_isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye),
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: (v) => (v == null || v.length < 8) ? 'A senha deve ter pelo menos 8 caracteres' : null,
          ),
          const SizedBox(height: 8),
          _buildForgotPassword(context),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implementar lógica de esqueci a senha
        },
        child: Text(
          'Esqueceu a senha?',
          style: const TextStyle(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        final isLoading = state is auth_states.AuthLoading;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: isLoading ? null : _handleLogin,
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Text('Entrar'),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        final isLoading = state is auth_states.AuthLoading;
        return Column(
          children: [
            // Google OAuth (funcional)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                    },
              icon: const OfficialSocialIcon(platform: SocialPlatform.google, size: 18),
              label: const Text('Entrar com Google'),
            ),
            
            const SizedBox(height: 12),
            
            // Redes Sociais (em desenvolvimento)
            Text(
              'Outras opções sociais:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : AppColors.info,
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : AppColors.info),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthLinkedInSignInRequested());
                    },
                    icon: const OfficialSocialIcon(platform: SocialPlatform.linkedin, size: 16),
                    label: const Text('LinkedIn'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : AppColors.error,
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : AppColors.error),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthInstagramSignInRequested());
                    },
                    icon: const OfficialSocialIcon(platform: SocialPlatform.instagram, size: 16),
                    label: const Text('Instagram'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : AppColors.primaryBlue,
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : AppColors.primaryBlue),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthFacebookSignInRequested());
                    },
                    icon: const OfficialSocialIcon(platform: SocialPlatform.facebook, size: 16),
                    label: const Text('Facebook'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cadastro de Cliente
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Não tem uma conta?'),
            TextButton(
              onPressed: () => context.go('/register-client'),
              child: const Text(
                'Cadastre-se como Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        const Divider(),
        
        const SizedBox(height: 24),

        // Cadastro de Advogado
        Text('É advogado(a)? Cadastre-se como:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.user),
              label: const Text('Autônomo'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_individual'}),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.users),
              label: const Text('Associado'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_associated'}),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.building),
              label: const Text('Escritório'),
              onPressed: () => context.go('/register-lawyer', extra: {'role': 'lawyer_office'}),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // === MODO DEBUG ===
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Modo Debug - Teste de Usuários',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Clique em um botão abaixo para testar como diferentes tipos de usuário:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDebugButton(context, 'Cliente', 'PF', AppColors.info),
                  _buildDebugButton(context, 'Advogado Associado', 'lawyer_associated', AppColors.success),
                  _buildDebugButton(context, 'Advogado Autônomo', 'lawyer_individual', AppColors.primaryPurple),
                  _buildDebugButton(context, 'Escritório', 'lawyer_office', AppColors.error),
                  _buildDebugButton(context, 'Super Associado', 'lawyer_platform_associate', AppColors.warning),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebugButton(BuildContext context, String label, String userRole, Color color) {
    return ElevatedButton(
      onPressed: () => _switchToDebugUser(context, userRole),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  void _switchToDebugUser(BuildContext context, String userRole) {
    final debugUsers = {
      'PF': const User(
        id: 'debug-client-1',
        email: 'cliente@teste.com',
        fullName: 'João Silva (Cliente)',
        role: 'client',
        userRole: 'PF',
        permissions: ['nav.view.client_home', 'nav.view.client_cases', 'nav.view.find_lawyers', 'nav.view.client_messages', 'nav.view.services', 'nav.view.client_profile'],
      ),
      'lawyer_associated': const User(
        id: 'debug-lawyer-1',
        email: 'advogado@teste.com',
        fullName: 'Maria Santos (Advogada Associada)',
        role: 'lawyer',
        userRole: 'lawyer_associated',
        permissions: ['nav.view.dashboard', 'nav.view.cases', 'nav.view.schedule', 'nav.view.offers', 'nav.view.messages', 'nav.view.profile'],
      ),
      'lawyer_individual': const User(
        id: 'debug-lawyer-2',
        email: 'autonomo@teste.com',
        fullName: 'Pedro Costa (Advogado Autônomo)',
        role: 'lawyer',
        userRole: 'lawyer_individual',
        permissions: ['nav.view.home', 'nav.view.cases', 'nav.view.offers', 'nav.view.partners', 'nav.view.partnerships', 'nav.view.messages', 'nav.view.profile'],
      ),
      'lawyer_office': const User(
        id: 'debug-office-1',
        email: 'escritorio@teste.com',
        fullName: 'Escritório Silva & Associados',
        role: 'lawyer',
        userRole: 'lawyer_office',
        permissions: ['nav.view.home', 'nav.view.cases', 'nav.view.offers', 'nav.view.partners', 'nav.view.partnerships', 'nav.view.messages', 'nav.view.profile'],
      ),
      'lawyer_platform_associate': const User(
        id: 'debug-super-1',
        email: 'super@teste.com',
        fullName: 'Ana Super (Super Associada)',
        role: 'lawyer',
        userRole: 'lawyer_platform_associate',
        permissions: ['nav.view.home', 'nav.view.cases', 'nav.view.offers', 'nav.view.partners', 'nav.view.partnerships', 'nav.view.messages', 'nav.view.profile'],
      ),
    };

    final user = debugUsers[userRole];
    if (user != null) {
      context.read<AuthBloc>().add(AuthDebugUserSwitch(user));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modo debug: ${user.fullName}'),
          backgroundColor: AppColors.info,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
