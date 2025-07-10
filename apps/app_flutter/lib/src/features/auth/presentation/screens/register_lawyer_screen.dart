import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;

class RegisterLawyerScreen extends StatefulWidget {
  const RegisterLawyerScreen({super.key});

  @override
  State<RegisterLawyerScreen> createState() => _RegisterLawyerScreenState();
}

class _RegisterLawyerScreenState extends State<RegisterLawyerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers...
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oabController = TextEditingController();
  final _areasController = TextEditingController();
  final _maxCasesController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  File? _cvFile;
  File? _oabFile;
  File? _residenceProofFile;

  String? _gender;
  String? _ethnicity;
  bool _isPcd = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    // Dispose all controllers
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, corrija os erros marcados em vermelho.')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar os termos para continuar.')),
      );
      setState(() => _currentStep = 4); // Navigate to terms step
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterLawyerRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        cpf: _cpfController.text,
        phone: _phoneController.text,
        oab: _oabController.text.trim(),
        areas: _areasController.text.trim(),
        maxCases: int.tryParse(_maxCasesController.text.trim()) ?? 0,
        cep: _cepController.text,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        cvFile: _cvFile,
        oabFile: _oabFile,
        residenceProofFile: _residenceProofFile,
        gender: _gender,
        ethnicity: _ethnicity,
        isPcd: _isPcd,
        agreedToTerms: _agreedToTerms,
      ));
  }

  Future<void> _pickFile(Function(File) onFilePicked, {required List<String> allowedExtensions}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result != null) {
      setState(() => onFilePicked(File(result.files.single.path!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Advogado(a)'),
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
                    content: Text('Cadastro enviado para análise! Verifique seu e-mail.'),
                    backgroundColor: Colors.green,
                  ));
            context.go('/login');
          }
        },
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                final isLastStep = _currentStep == getSteps().length - 1;
                if (isLastStep) {
                  _handleRegister();
                } else {
                  setState(() => _currentStep += 1);
                }
              },
              onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
              onStepTapped: (step) => setState(() => _currentStep = step),
              steps: getSteps(),
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == getSteps().length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: BlocBuilder<AuthBloc, auth_states.AuthState>(
                              builder: (context, state) {
                            if (isLastStep && state is auth_states.AuthLoading) {
                              return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator());
                            }
                            return Text(isLastStep ? 'Finalizar Cadastro' : 'Continuar');
                          }),
                        ),
                      ),
                      if (details.onStepCancel != null) ...[
                        const SizedBox(width: 12),
                        Expanded(child: TextButton(onPressed: details.onStepCancel, child: const Text('Voltar'))),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          title: const Text('Informações Pessoais'),
          content: _buildStep1(),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Dados Profissionais'),
          content: _buildStep2(),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Documentos'),
          content: _buildStep3(),
          isActive: _currentStep >= 2,
        ),
        Step(
          title: const Text('Diversidade'),
          content: _buildStep4(),
          isActive: _currentStep >= 3,
        ),
        Step(
          title: const Text('Termos de Uso'),
          content: _buildStep5(),
          isActive: _currentStep >= 4,
        ),
      ];
      
  Widget _buildStep1() => Column(children: [
    _buildTextField(controller: _nameController, hintText: 'Nome Completo', textCapitalization: TextCapitalization.words, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
    _buildTextField(controller: _cpfController, hintText: 'CPF', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()], validator: (v) => v!.length != 14 ? 'CPF inválido' : null),
    _buildTextField(controller: _phoneController, hintText: 'Telefone com DDD', keyboardType: TextInputType.phone, inputFormatters: [PhoneInputFormatter()], validator: (v) => v!.length < 14 ? 'Telefone inválido' : null),
    _buildTextField(controller: _emailController, hintText: 'E-mail', keyboardType: TextInputType.emailAddress, validator: (v) => (v!.isEmpty || !v.contains('@')) ? 'E-mail inválido' : null),
    _buildTextField(controller: _passwordController, hintText: 'Senha (mínimo 8 caracteres)', obscureText: true, validator: (v) => (v!.length < 8) ? 'Senha muito curta' : null),
  ]);

  Widget _buildStep2() => Column(children: [
    _buildTextField(controller: _oabController, hintText: 'Nº da OAB (Ex: 123456/SP)', validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
    _buildTextField(controller: _areasController, hintText: 'Áreas de Atuação (separadas por vírgula)', validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
    _buildTextField(controller: _maxCasesController, hintText: 'Nº máximo de casos simultâneos', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
    _buildTextField(controller: _cepController, hintText: 'CEP', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, CepInputFormatter()], validator: (v) => v!.length != 9 ? 'CEP inválido' : null),
    _buildTextField(controller: _addressController, hintText: 'Endereço Completo', validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
    Row(children: [
      Expanded(child: _buildTextField(controller: _cityController, hintText: 'Cidade', validator: (v) => v!.isEmpty ? 'Obrigatório' : null)),
      const SizedBox(width: 16),
      Expanded(child: _buildTextField(controller: _stateController, hintText: 'UF', validator: (v) => v!.isEmpty ? 'Obrigatório' : null)),
    ]),
  ]);

  Widget _buildStep3() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Anexe os documentos para validação.', style: Theme.of(context).textTheme.bodyLarge),
    const SizedBox(height: 24),
    _buildFileUploadField(label: 'Currículo (PDF/DOC)', file: _cvFile, onTap: () => _pickFile((f) => _cvFile = f, allowedExtensions: ['pdf', 'doc', 'docx'])),
    _buildFileUploadField(label: 'Cópia da OAB (PDF/JPG/PNG)', file: _oabFile, onTap: () => _pickFile((f) => _oabFile = f, allowedExtensions: ['pdf', 'jpg', 'png'])),
    _buildFileUploadField(label: 'Comprov. de Residência (PDF/JPG/PNG)', file: _residenceProofFile, onTap: () => _pickFile((f) => _residenceProofFile = f, allowedExtensions: ['pdf', 'jpg', 'png'])),
  ]);

  Widget _buildStep4() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Informações de Diversidade (Opcional)', style: Theme.of(context).textTheme.bodyLarge),
    Text('Estes dados são usados para promover equidade na distribuição de casos.', style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 24),
    _buildDropdownField(label: 'Gênero', value: _gender, items: ['Masculino', 'Feminino', 'Não-binário', 'Outro', 'Prefiro não informar'], onChanged: (v) => setState(() => _gender = v)),
    _buildDropdownField(label: 'Etnia/Raça', value: _ethnicity, items: ['Branco', 'Preto', 'Pardo', 'Amarelo', 'Indígena', 'Prefiro não informar'], onChanged: (v) => setState(() => _ethnicity = v)),
    SwitchListTile(
      title: const Text('Você se identifica como Pessoa com Deficiência (PCD)?'),
      value: _isPcd,
      onChanged: (value) => setState(() => _isPcd = value),
      activeColor: Theme.of(context).colorScheme.primary,
      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ]);

  Widget _buildStep5() => Column(children: [
    Text('Termos de Uso e Contrato de Parceria', style: Theme.of(context).textTheme.bodyLarge),
    const SizedBox(height: 16),
    Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const SingleChildScrollView(
        child: Text(
          'Ao clicar em "FINALIZAR CADASTRO", você concorda com os Termos de Parceria e a Política de Privacidade do LITIG. Você declara que todas as informações fornecidas são verdadeiras e que sua situação na OAB está regular. O LITIG se reserva o direito de verificar as informações e, caso encontre inconsistências, poderá suspender ou encerrar sua conta na plataforma...',
        ),
      ),
    ),
    const SizedBox(height: 16),
    CheckboxListTile(
      title: const Text('Li e concordo com os termos'),
      value: _agreedToTerms,
      onChanged: (value) => setState(() => _agreedToTerms = value!),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Theme.of(context).colorScheme.primary,
      tileColor: Theme.of(context).inputDecorationTheme.fillColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ]);

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, String? Function(String?)? validator, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(controller: controller, obscureText: obscureText, decoration: InputDecoration(hintText: hintText), validator: validator, keyboardType: keyboardType, inputFormatters: inputFormatters, textCapitalization: textCapitalization),
    );
  }

  Widget _buildFileUploadField({required String label, required File? file, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: theme.colorScheme.onSurface.withOpacity(0.4),
        strokeWidth: 1.5,
        dashPattern: const [6, 6],
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(11)),
            child: file == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(LucideIcons.uploadCloud, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text(label, style: theme.textTheme.bodyMedium),
                  ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(LucideIcons.fileCheck2, color: Colors.green.shade400),
                    const SizedBox(width: 12),
                    Expanded(child: Text(file.path.split('/').last, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
                  ]),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(hintText: label),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Formatters - Manter como estão, mas poderiam ser movidos para um arquivo de utils
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    var formatted = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '.';
      } else if (i == 9) {
        formatted += '-';
      }
      formatted += text[i];
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length <= 2) return newValue.copyWith(text: '($text');
    if (text.length <= 7) return newValue.copyWith(text: '(${text.substring(0, 2)}) ${text.substring(2)}');
    return newValue.copyWith(text: '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7, 11)}');
  }
}

class CepInputFormatter extends TextInputFormatter {
   @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    var formatted = '';
     for (var i = 0; i < text.length; i++) {
      if (i == 5) {
        formatted += '-';
      }
      formatted += text[i];
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 