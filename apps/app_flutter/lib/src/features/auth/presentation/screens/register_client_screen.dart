import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;

enum UserType { pessoaFisica, pessoaJuridica }

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _userType = UserType.pessoaFisica;

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); // Adicionado

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _razaoSocialController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose(); // Adicionado
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthRegisterClientRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _userType == UserType.pessoaFisica
                ? _nameController.text.trim()
                : _razaoSocialController.text.trim(),
            userType: _userType == UserType.pessoaFisica ? 'PF' : 'PJ',
            cpf: _userType == UserType.pessoaFisica ? _cpfController.text : null,
            cnpj: _userType == UserType.pessoaJuridica ? _cnpjController.text : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Cliente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          if (state is auth_states.AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is auth_states.AuthSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('Cadastro realizado! Verifique seu e-mail para ativar a conta.'),
                backgroundColor: Colors.green,
              ));
            context.go('/login');
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildUserTypeSelector(context),
                  const SizedBox(height: 24),
                  _buildFormFields(),
                  const SizedBox(height: 24),
                  _buildRegisterButton(),
                  const SizedBox(height: 24),
                  _buildDivider(context),
                  const SizedBox(height: 24),
                  _buildSocialRegistration(context),
                  const SizedBox(height: 32),
                  _buildLoginPrompt(context),
                ],
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
        Text('Crie sua Conta', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Comece a resolver suas questões jurídicas hoje.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserTypeSelector(BuildContext context) {
    return SegmentedButton<UserType>(
      segments: const [
        ButtonSegment<UserType>(
          value: UserType.pessoaFisica,
          label: Text('Pessoa Física'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment<UserType>(
          value: UserType.pessoaJuridica,
          label: Text('Pessoa Jurídica'),
          icon: Icon(Icons.business),
        ),
      ],
      selected: {_userType},
      onSelectionChanged: (Set<UserType> newSelection) {
        setState(() {
          _userType = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
        selectedBackgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (_userType == UserType.pessoaFisica) ...[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Nome Completo'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v!.trim().isEmpty ? 'Nome é obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cpfController,
            decoration: const InputDecoration(hintText: 'CPF'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
            validator: (v) => (v!.replaceAll(RegExp(r'[^\d]'), '').length != 11) ? 'CPF inválido' : null,
          ),
        ] else ...[
          TextFormField(
            controller: _razaoSocialController,
            decoration: const InputDecoration(hintText: 'Razão Social'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v!.trim().isEmpty ? 'Razão Social é obrigatória' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cnpjController,
            decoration: const InputDecoration(hintText: 'CNPJ'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CnpjInputFormatter()],
            validator: (v) => (v!.replaceAll(RegExp(r'[^\d]'), '').length != 14) ? 'CNPJ inválido' : null,
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(hintText: 'E-mail'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v!.isEmpty || !v.contains('@')) ? 'E-mail inválido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(hintText: 'Senha'),
          obscureText: true,
          validator: (v) => (v!.length < 8) ? 'A senha deve ter pelo menos 8 caracteres' : null,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, auth_states.AuthState>(
      builder: (context, state) {
        final isLoading = state is auth_states.AuthLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _handleRegister,
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Text('Criar Conta'),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou cadastre-se com',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialRegistration(BuildContext context) {
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
                      // Para registro, usamos um evento específico que pode capturar dados sociais
                      context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                    },
              icon: const Icon(Icons.login), // Google icon placeholder
              label: const Text('Cadastrar com Google'),
            ),
            
            const SizedBox(height: 12),
            
            // Redes Sociais (preparadas para implementação futura)
            Text(
              'Outras opções sociais (em breve):',
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
                    icon: const Icon(Icons.business, size: 16),
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
                    icon: const Icon(Icons.camera_alt, size: 16),
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
                    icon: const Icon(Icons.facebook, size: 16),
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

  Widget _buildLoginPrompt(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Já tem uma conta?', style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Faça Login'),
        ),
      ],
    );
  }
}

// Formatters
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 11) return oldValue;
    
    var formatted = '';
    for (var i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 2 || i == 5) formatted += '.';
      if (i == 8) formatted += '-';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 14) return oldValue;

    var formatted = '';
     for (var i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 1) formatted += '.';
      if (i == 4) formatted += '.';
      if (i == 7) formatted += '/';
      if (i == 11) formatted += '-';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 11) return oldValue;

    var formatted = '';
    if (text.length > 2) {
      formatted = '(${text.substring(0, 2)}) ';
      if (text.length > 7) {
        formatted += '${text.substring(2, 7)}-${text.substring(7)}';
      } else {
        formatted += text.substring(2);
      }
    } else {
      formatted = text;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 