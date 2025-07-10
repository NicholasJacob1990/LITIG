import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';

class RegisterLawyerScreen extends StatefulWidget {
  const RegisterLawyerScreen({super.key});

  @override
  State<RegisterLawyerScreen> createState() => _RegisterLawyerScreenState();
}

class _RegisterLawyerScreenState extends State<RegisterLawyerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isPasswordVisible = false;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Step 2 Controllers
  final _oabController = TextEditingController();
  final _areasController = TextEditingController();
  final _maxCasesController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Step 3 File Holders
  File? _cvFile;
  File? _oabFile;
  File? _residenceProofFile;

  // Step 4 Controllers
  String? _gender;
  String? _ethnicity;
  bool _isPcd = false;
  
  // Step 5
  bool _agreedToTerms = false;


  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _oabController.dispose();
    _areasController.dispose();
    _maxCasesController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Validação final de todas as etapas (pode ser melhorada)
    if (!_formKey.currentState!.validate()) {
       // Tenta navegar para o primeiro passo com erro
      return;
    }
    if (!_agreedToTerms) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você deve aceitar os termos para continuar.')),
        );
      return;
    }
    
    context.read<AuthBloc>().add(
      AuthRegisterLawyerRequested(
        // Step 1
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        cpf: _cpfController.text,
        phone: _phoneController.text,
        // Step 2
        oab: _oabController.text.trim(),
        areas: _areasController.text.trim(),
        maxCases: int.tryParse(_maxCasesController.text.trim()) ?? 0,
        cep: _cepController.text,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        // Step 3
        cvFile: _cvFile,
        oabFile: _oabFile,
        residenceProofFile: _residenceProofFile,
        // Step 4
        gender: _gender,
        ethnicity: _ethnicity,
        isPcd: _isPcd,
        // Step 5
        agreedToTerms: _agreedToTerms,
      ),
    );
  }
  
  Future<void> _pickCvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _cvFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        onImagePicked(File(image.path));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Advogado'),
        centerTitle: true,
      ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastro enviado para análise! Verifique seu e-mail para ativar a conta.'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/login');
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: () {
              final isLastStep = _currentStep == getSteps().length - 1;
              if (isLastStep) {
                _handleRegister();
              } else {
                // Adicionar validação por passo aqui se necessário
                setState(() {
                  _currentStep += 1;
                });
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
            onStepTapped: (step) => setState(() => _currentStep = step),
            steps: getSteps(),
             controlsBuilder: (context, details) {
              final isLastStep = _currentStep == getSteps().length - 1;
              return Container(
                margin: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                     Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(isLastStep ? 'FINALIZAR CADASTRO' : 'CONTINUAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      Expanded(
                        child: TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('VOLTAR'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 0,
          title: const Text('Pessoal'),
          content: _buildStep1(),
        ),
        Step(
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 1,
          title: const Text('Profissional'),
          content: _buildStep2(),
        ),
        Step(
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 2,
          title: const Text('Documentos'),
          content: _buildStep3(),
        ),
        Step(
          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          isActive: _currentStep >= 3,
          title: const Text('Diversidade'),
          content: _buildStep4(),
        ),
        Step(
          isActive: _currentStep >= 4,
          title: const Text('Termos'),
          content: _buildStep5(),
        ),
      ];

  Widget _buildStep1() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nome Completo',
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        _buildTextField(
          controller: _cpfController,
          label: 'CPF',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
          validator: (value) => value!.length < 14 ? 'CPF inválido' : null,
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Telefone',
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
           validator: (value) => value!.length < 15 ? 'Telefone inválido' : null,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
          validator: (value) => !RegExp(r'\S+@\S+\.\S+').hasMatch(value!) ? 'E-mail inválido' : null,
        ),
        _buildTextField(
          controller: _passwordController,
          label: 'Senha',
          obscureText: !_isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(_isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          validator: (value) => value!.length < 8 ? 'Mínimo 8 caracteres' : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
     return Column(
      children: [
        _buildTextField(
          controller: _oabController,
          label: 'Nº da OAB',
          hintText: 'Ex: 123456/SP',
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
         _buildTextField(
          controller: _areasController,
          label: 'Áreas de Atuação',
          hintText: 'Trabalhista, Civil, Penal...',
           validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
         _buildTextField(
          controller: _maxCasesController,
          label: 'Nº máximo de casos simultâneos',
          keyboardType: TextInputType.number,
           validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        _buildTextField(
          controller: _cepController,
          label: 'CEP',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CepInputFormatter()],
           validator: (value) => value!.length < 9 ? 'CEP inválido' : null,
        ),
         _buildTextField(
          controller: _addressController,
          label: 'Endereço',
           validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: _cityController, label: 'Cidade', validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(controller: _stateController, label: 'UF', validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null)),
          ],
        )
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text('Anexe os documentos necessários', style: Theme.of(context).textTheme.titleMedium),
         const SizedBox(height: 16),
        _buildFileUploadField(
          label: 'Currículo (PDF, DOC)',
          file: _cvFile,
          onTap: _pickCvFile,
        ),
        const SizedBox(height: 16),
        _buildFileUploadField(
          label: 'Cópia da OAB (Imagem)',
          file: _oabFile,
          onTap: () => _pickImage((file) => _oabFile = file),
        ),
        const SizedBox(height: 16),
        _buildFileUploadField(
          label: 'Comprovante de Residência (Imagem)',
          file: _residenceProofFile,
          onTap: () => _pickImage((file) => _residenceProofFile = file),
        ),
      ],
    );
  }
  
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informações de Diversidade (Opcional)', style: Theme.of(context).textTheme.titleMedium),
        Text('Estes dados são usados para promover equidade na distribuição de casos.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gênero',
          value: _gender,
          items: ['Masculino', 'Feminino', 'Não-binário', 'Outro', 'Prefiro não informar'],
          onChanged: (value) => setState(() => _gender = value),
        ),
        _buildDropdownField(
          label: 'Etnia/Raça',
          value: _ethnicity,
          items: ['Branco', 'Preto', 'Pardo', 'Amarelo', 'Indígena', 'Prefiro não informar'],
          onChanged: (value) => setState(() => _ethnicity = value),
        ),
        SwitchListTile(
          title: const Text('Você se identifica como PCD?'),
          value: _isPcd,
          onChanged: (value) => setState(() => _isPcd = value),
        ),
      ],
    );
  }

  Widget _buildStep5() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Termos e Contrato', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)
          ),
          child: const SingleChildScrollView(
            child: Text(
              'Ao clicar em "FINALIZAR CADASTRO", você concorda com os Termos de Parceria e a Política de Privacidade do LITIG. Você declara que todas as informações fornecidas são verdadeiras e que sua situação na OAB está regular. O LITIG se reserva o direito de verificar as informações e, caso encontre inconsistências, poderá suspender ou encerrar sua conta na plataforma...'
              ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Li e concordo com os termos'),
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      color: Colors.grey,
      strokeWidth: 1,
      dashPattern: const [6, 6],
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.uploadCloud, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(color: Colors.grey)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.fileCheck, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.path.split('/').last,
                        style: const TextStyle(color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

   Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
       child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
       ),
     );
  }
}

// Formatters
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