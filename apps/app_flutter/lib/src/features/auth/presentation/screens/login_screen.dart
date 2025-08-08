import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                    const SizedBox(height: 32),
                    _buildRegisterPrompt(context),
                    const SizedBox(height: 32),
                    _buildDebugSection(context),
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
          color: Theme.of(context).colorScheme.primary,
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
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Text('Entrar'),
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
              child: Text(
                'Cadastre-se como Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Cadastro de Advogado
        Text(
          'É advogado(a)? Cadastre-se como:',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.user),
              label: const Text('Autônomo'),
              onPressed: () => context.go(
                '/register-lawyer',
                extra: {'role': 'lawyer_individual'},
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.users),
              label: const Text('Associado'),
              onPressed: () => context.go(
                '/register-lawyer',
                extra: {'role': 'lawyer_firm_member'},
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.building),
              label: const Text('Escritório'),
              onPressed: () => context.go(
                '/register-lawyer',
                extra: {'role': 'lawyer_office'},
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDebugSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Modo Debug - Entrar sem senha',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Selecione um perfil para testar rapidamente:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildDebugButton(context, 'Cliente PF', 'client_pf', AppColors.info),
            _buildDebugButton(context, 'Advogado Associado', 'lawyer_firm_member', AppColors.success),
            _buildDebugButton(context, 'Advogado Autônomo', 'lawyer_individual', AppColors.primaryPurple),
            _buildDebugButton(context, 'Escritório', 'firm', AppColors.error),
            _buildDebugButton(context, 'Super Associado', 'super_associate', AppColors.warning),
          ],
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
    final debugUsers = <String, User>{
      'client_pf': const User(
        id: 'debug-client-1',
        email: 'cliente@teste.com',
        fullName: 'João Silva (Cliente)',
        role: 'client',
        userRole: 'client_pf',
        permissions: [
          'nav.view.client_home',
          'nav.view.client_cases',
          'nav.view.find_lawyers',
          'nav.view.client_messages',
          'nav.view.services',
          'nav.view.client_profile',
        ],
      ),
      'lawyer_firm_member': const User(
        id: 'debug-lawyer-1',
        email: 'advogado@teste.com',
        fullName: 'Maria Santos (Associada)',
        role: 'lawyer',
        userRole: 'lawyer_firm_member',
        permissions: [
          'nav.view.dashboard',
          'nav.view.cases',
          'nav.view.schedule',
          'nav.view.offers',
          'nav.view.messages',
          'nav.view.profile',
        ],
      ),
      'lawyer_individual': const User(
        id: 'debug-lawyer-2',
        email: 'autonomo@teste.com',
        fullName: 'Pedro Costa (Autônomo)',
        role: 'lawyer',
        userRole: 'lawyer_individual',
        permissions: [
          'nav.view.home',
          'nav.view.cases',
          'nav.view.offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.messages',
          'nav.view.profile',
        ],
      ),
      'firm': const User(
        id: 'debug-firm-1',
        email: 'escritorio@teste.com',
        fullName: 'Escritório Silva & Associados',
        role: 'lawyer',
        userRole: 'firm',
        permissions: [
          'nav.view.home',
          'nav.view.cases',
          'nav.view.offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.messages',
          'nav.view.profile',
        ],
      ),
      'super_associate': const User(
        id: 'debug-super-1',
        email: 'super@teste.com',
        fullName: 'Ana Super (Super Associada)',
        role: 'lawyer',
        userRole: 'super_associate',
        permissions: [
          'nav.view.home',
          'nav.view.cases',
          'nav.view.offers',
          'nav.view.partners',
          'nav.view.partnerships',
          'nav.view.messages',
          'nav.view.profile',
        ],
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
