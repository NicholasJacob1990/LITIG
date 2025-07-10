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
 
 