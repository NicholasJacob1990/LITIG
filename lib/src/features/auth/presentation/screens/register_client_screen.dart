import 'package:flutter/material.dart';
import 'package:meu_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserType { pessoaFisica, pessoaJuridica }

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _userType = UserType.pessoaFisica;
  bool _isLoading = false;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'user_type': _userType.name,
            'full_name': _userType == UserType.pessoaFisica ? _nomeController.text : _razaoSocialController.text,
            'document': _userType == UserType.pessoaFisica ? _cpfController.text : _cnpjController.text,
            'phone': _telefoneController.text,
            'role': 'client',
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado! Por favor, verifique seu e-mail para confirmar a conta.')),
          );
          Navigator.of(context).pop(); // Volta para a tela de login
        }
      } on AuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FocusScope(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seletor de Tipo de Pessoa com semântica melhorada
                Semantics(
                  label: 'Selecione o tipo de pessoa para cadastro',
                  hint: 'Use as teclas de seta para navegar entre as opções',
                  child: Focus(
                    autofocus: true,
                    child: SegmentedButton<UserType>(
                      segments: const [
                        ButtonSegment(
                          value: UserType.pessoaFisica, 
                          label: Text('Pessoa Física'),
                        ),
                        ButtonSegment(
                          value: UserType.pessoaJuridica, 
                          label: Text('Pessoa Jurídica'),
                        ),
                      ],
                      selected: {_userType},
                      onSelectionChanged: (Set<UserType> newSelection) {
                        setState(() {
                          _userType = newSelection.first;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Campos do Formulário com navegação por teclado otimizada
                if (_userType == UserType.pessoaFisica) ...[
                  Focus(
                    child: TextFormField(
                      controller: _nomeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        helperText: 'Digite seu nome completo',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite seu nome completo';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    child: TextFormField(
                      controller: _cpfController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        helperText: 'Apenas números',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite seu CPF';
                        }
                        return null;
                      },
                    ),
                  ),
                ] else ...[
                  Focus(
                    child: TextFormField(
                      controller: _razaoSocialController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Razão Social',
                        helperText: 'Nome oficial da empresa',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite a razão social';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    child: TextFormField(
                      controller: _cnpjController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        helperText: 'Apenas números',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite o CNPJ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Focus(
                  child: TextFormField(
                    controller: _emailController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      helperText: 'Será usado para login',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'Por favor, digite um e-mail válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Focus(
                  child: TextFormField(
                    controller: _telefoneController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      helperText: 'Com DDD, apenas números',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu telefone';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 24),

              // Botão de Cadastro
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _signUp, child: const Text('Criar Conta')),
            ],
          ),
        ),
      ),
    );
  }
} 
 
import 'package:meu_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserType { pessoaFisica, pessoaJuridica }

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _formKey = GlobalKey<FormState>();
  UserType _userType = UserType.pessoaFisica;
  bool _isLoading = false;

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'user_type': _userType.name,
            'full_name': _userType == UserType.pessoaFisica ? _nomeController.text : _razaoSocialController.text,
            'document': _userType == UserType.pessoaFisica ? _cpfController.text : _cnpjController.text,
            'phone': _telefoneController.text,
            'role': 'client',
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado! Por favor, verifique seu e-mail para confirmar a conta.')),
          );
          Navigator.of(context).pop(); // Volta para a tela de login
        }
      } on AuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seletor de Tipo de Pessoa
              SegmentedButton<UserType>(
                segments: const [
                  ButtonSegment(value: UserType.pessoaFisica, label: Text('Pessoa Física')),
                  ButtonSegment(value: UserType.pessoaJuridica, label: Text('Pessoa Jurídica')),
                ],
                selected: {_userType},
                onSelectionChanged: (Set<UserType> newSelection) {
                  setState(() {
                    _userType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Campos do Formulário
              if (_userType == UserType.pessoaFisica) ...[
                TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome Completo')),
                const SizedBox(height: 16),
                TextFormField(controller: _cpfController, decoration: const InputDecoration(labelText: 'CPF')),
              ] else ...[
                TextFormField(controller: _razaoSocialController, decoration: const InputDecoration(labelText: 'Razão Social')),
                const SizedBox(height: 16),
                TextFormField(controller: _cnpjController, decoration: const InputDecoration(labelText: 'CNPJ')),
              ],
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail')),
              const SizedBox(height: 16),
              TextFormField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 24),

              // Botão de Cadastro
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _signUp, child: const Text('Criar Conta')),
            ],
          ),
        ),
      ),
    );
  }
} 
 
 