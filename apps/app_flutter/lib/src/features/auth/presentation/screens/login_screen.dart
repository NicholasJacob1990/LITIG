import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;

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
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Acesse sua Conta',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
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
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
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
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
              icon: const Icon(LucideIcons.user), // Placeholder for Google icon
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
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFF0077B5), // LinkedIn Blue
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFF0077B5)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthLinkedInSignInRequested());
                    },
                    icon: const Icon(LucideIcons.briefcase, size: 16),
                    label: const Text('LinkedIn'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFFE4405F), // Instagram Pink
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFFE4405F)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthInstagramSignInRequested());
                    },
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('Instagram'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: isLoading ? Colors.grey[400] : const Color(0xFF1877F2), // Facebook Blue
                      side: BorderSide(color: isLoading ? Colors.grey[300]! : const Color(0xFF1877F2)),
                    ),
                    onPressed: isLoading ? null : () {
                      context.read<AuthBloc>().add(AuthFacebookSignInRequested());
                    },
                    icon: const Icon(LucideIcons.facebook, size: 16),
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
        Text('É advogado(a)? Cadastre-se como:', style: Theme.of(context).textTheme.titleMedium),
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
        )
      ],
    );
  }
}

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
        Text('É advogado(a)? Cadastre-se como:', style: Theme.of(context).textTheme.titleMedium),
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
        )
      ],
    );
  }
}

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
        Text('É advogado(a)? Cadastre-se como:', style: Theme.of(context).textTheme.titleMedium),
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
        )
      ],
    );
  }
}
