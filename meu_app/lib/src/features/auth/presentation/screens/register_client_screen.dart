import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:go_router/go_router.dart';

enum UserType { pessoaFisica, pessoaJuridica }

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _userType = UserType.pessoaFisica;
  bool _isPasswordVisible = false;

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _razaoSocialController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<AuthBloc, auth_states.AuthState>(
        listener: (context, state) {
          if (state is auth_states.AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is auth_states.Unauthenticated) {
            // Sucesso no registro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastro realizado com sucesso! Verifique seu e-mail para ativar a conta.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/login');
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Title
                Text(
                  'Crie sua Conta de Cliente',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha os dados abaixo para começar.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // User Type Selector
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _userType = UserType.pessoaFisica),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _userType == UserType.pessoaFisica 
                                  ? Colors.white 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: _userType == UserType.pessoaFisica
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Pessoa Física',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _userType == UserType.pessoaFisica 
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _userType = UserType.pessoaJuridica),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _userType == UserType.pessoaJuridica 
                                  ? Colors.white 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: _userType == UserType.pessoaJuridica
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Pessoa Jurídica',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _userType == UserType.pessoaJuridica 
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Conditional Fields
                if (_userType == UserType.pessoaFisica) ...[
                  _buildInput(
                    label: 'Nome Completo',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.trim().isEmpty ? 'Nome é obrigatório' : null,
                  ),
                  _buildInput(
                    label: 'CPF',
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                    validator: (v) {
                      if (v!.isEmpty) return 'CPF é obrigatório';
                      if (v.replaceAll(RegExp(r'[^\d]'), '').length != 11) return 'CPF deve ter 11 dígitos';
                      return null;
                    },
                  ),
                ] else ...[
                  _buildInput(
                    label: 'Razão Social',
                    controller: _razaoSocialController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.trim().isEmpty ? 'Razão Social é obrigatória' : null,
                  ),
                  _buildInput(
                    label: 'CNPJ',
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    maxLength: 18,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CnpjInputFormatter()],
                     validator: (v) {
                      if (v!.isEmpty) return 'CNPJ é obrigatório';
                      if (v.replaceAll(RegExp(r'[^\d]'), '').length != 14) return 'CNPJ deve ter 14 dígitos';
                      return null;
                    },
                  ),
                ],

                // Common Fields
                _buildInput(
                  label: 'E-mail',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'E-mail é obrigatório';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) return 'Formato de e-mail inválido';
                    return null;
                  },
                ),
                _buildInput(
                  label: 'Telefone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, PhoneInputFormatter()],
                  validator: (v) {
                    if (v!.isEmpty) return 'Telefone é obrigatório';
                    if (v.replaceAll(RegExp(r'[^\d]'), '').length < 10) return 'Telefone inválido';
                    return null;
                  },
                ),

                // Password Field
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        icon: Icon(
                          _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Senha é obrigatória';
                      if (v.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Register Button
                BlocBuilder<AuthBloc, auth_states.AuthState>(
                  builder: (context, state) {
                    final isLoading = state is auth_states.AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
                        style: isLoading 
                            ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9DB2BF)) 
                            : null,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Criar Conta'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// Formatters
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    var newText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.length > 11) newText = newText.substring(0, 11);
    
    var formattedText = '';
    if (newText.length > 9) {
      formattedText = '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6, 9)}-${newText.substring(9)}';
    } else if (newText.length > 6) {
      formattedText = '${newText.substring(0, 3)}.${newText.substring(3, 6)}.${newText.substring(6)}';
    } else if (newText.length > 3) {
      formattedText = '${newText.substring(0, 3)}.${newText.substring(3)}';
    } else {
      formattedText = newText;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    var newText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.length > 14) newText = newText.substring(0, 14);
    
    var formattedText = '';
    if (newText.length > 12) {
      formattedText = '${newText.substring(0, 2)}.${newText.substring(2, 5)}.${newText.substring(5, 8)}/${newText.substring(8, 12)}-${newText.substring(12)}';
    } else if (newText.length > 8) {
      formattedText = '${newText.substring(0, 2)}.${newText.substring(2, 5)}.${newText.substring(5, 8)}/${newText.substring(8)}';
    } else if (newText.length > 5) {
      formattedText = '${newText.substring(0, 2)}.${newText.substring(2, 5)}.${newText.substring(5)}';
    } else if (newText.length > 2) {
      formattedText = '${newText.substring(0, 2)}.${newText.substring(2)}';
    } else {
      formattedText = newText;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    var newText = text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.length > 11) newText = newText.substring(0, 11);
    
    var formattedText = '';
    if (newText.length > 10) { // Celular com 9 dígitos
      formattedText = '(${newText.substring(0, 2)}) ${newText.substring(2, 7)}-${newText.substring(7)}';
    } else if (newText.length > 6) {
      formattedText = '(${newText.substring(0, 2)}) ${newText.substring(2, 6)}-${newText.substring(6)}';
    } else if (newText.length > 2) {
      formattedText = '(${newText.substring(0, 2)}) ${newText.substring(2)}';
    } else {
      formattedText = newText;
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
} 