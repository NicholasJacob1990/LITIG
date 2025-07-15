import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart' as auth_states;

class RegisterLawyerScreen extends StatefulWidget {
  final String role;
  
  const RegisterLawyerScreen({super.key, this.role = 'lawyer_individual'});

  @override
  State<RegisterLawyerScreen> createState() => _RegisterLawyerScreenState();
}

class _RegisterLawyerScreenState extends State<RegisterLawyerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
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
  final _officeCodeController = TextEditingController();

  File? _cvFile;
  File? _oabFile;
  File? _residenceProofFile;

  String? _gender;
  String? _ethnicity;
  bool _isPcd = false;
  bool _agreedToTerms = false;
  bool _isPlatformAssociate = false; // NOVO: Campo para Super Associado

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
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
    _officeCodeController.dispose();
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
      // Navega para a última etapa para o aceite
      final steps = getSteps(isOffice: widget.role == 'lawyer_office', isAssociated: widget.role == 'lawyer_associated');
      setState(() => _currentStep = steps.length - 1);
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterLawyerRequested(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      cpf: widget.role != 'lawyer_office' ? _cpfController.text : '',
      cnpj: widget.role == 'lawyer_office' ? _cnpjController.text : null,
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
      userType: widget.role,
      isPlatformAssociate: _isPlatformAssociate, // NOVO: Campo Super Associado
    ));
  }

  Future<void> _pickFile(Function(File) onFilePicked) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        onFilePicked(file);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
    );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffice = widget.role == 'lawyer_office';
    final isAssociated = widget.role == 'lawyer_associated';

    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de ${isOffice ? 'Escritório' : isAssociated ? 'Advogado Associado' : 'Advogado Autônomo'}'),
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
                    content: Text('Cadastro enviado! Verifique seu e-mail.'),
                    backgroundColor: Colors.green,
                  ));
            
            // NOVO: Redirecionar para tela de contrato se for Super Associado
            if (_isPlatformAssociate) {
              context.go('/contract-signature');
            } else {
              context.go('/login');
            }
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              final isLastStep = _currentStep == getSteps(isOffice: isOffice, isAssociated: isAssociated).length - 1;
              if (isLastStep) {
                _handleRegister();
              } else {
                if (_formKey.currentState!.validate()) {
                   setState(() => _currentStep += 1);
                }
              }
            },
            onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
            onStepTapped: (step) => setState(() => _currentStep = step),
            steps: getSteps(isOffice: isOffice, isAssociated: isAssociated),
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == getSteps(isOffice: isOffice, isAssociated: isAssociated).length - 1;
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
                            return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                          }
                          return Text(isLastStep ? 'Finalizar Cadastro' : 'Continuar');
                        }),
                      ),
                    ),
                    if (details.onStepCancel != null) ...[
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('Voltar'))),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Step> getSteps({required bool isOffice, required bool isAssociated}) {
    final steps = [
      Step(
        title: Text(isOffice ? 'Dados do Escritório' : 'Informações Pessoais'),
        content: _buildStep1(isOffice: isOffice),
        isActive: _currentStep >= 0,
      ),
      if (isAssociated)
        Step(
          title: const Text('Vínculo com Escritório'),
          content: _buildOfficeLinkStep(), // Este método será modificado
          isActive: _currentStep >= 1,
        ),
      Step(
        title: const Text('Dados Profissionais'),
        content: _buildStep2(),
        isActive: _currentStep >= (isAssociated ? 2 : 1),
      ),
      if (!isAssociated)
        Step(
          title: const Text('Documentos'),
          content: _buildStep3(),
          isActive: _currentStep >= (isAssociated ? 3 : 2),
        ),
      Step(
        title: const Text('Diversidade (Opcional)'),
        content: _buildStep4(),
        isActive: _currentStep >= (isAssociated ? 4 : 3),
      ),
      Step(
        title: Text(isAssociated ? 'Contrato de Associação' : 'Termos de Uso'),
        content: _buildStep5(isAssociated: isAssociated),
        isActive: _currentStep >= (isAssociated ? 5 : 4),
      ),
    ];
    return steps;
  }
      
  Widget _buildStep1({required bool isOffice}) => Column(children: [
    _buildTextField(
      controller: _nameController, 
      hintText: isOffice ? 'Nome Fantasia do Escritório' : 'Nome Completo', 
      textCapitalization: TextCapitalization.words, 
      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null
    ),
    if (!isOffice)
      _buildTextField(
        controller: _cpfController, 
        hintText: 'CPF', 
        keyboardType: TextInputType.number, 
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()], 
        validator: (v) => v!.length != 14 ? 'CPF inválido' : null,
      ),
     if (isOffice)
      _buildTextField(
        controller: _cnpjController, 
        hintText: 'CNPJ', 
        keyboardType: TextInputType.number, 
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, CnpjInputFormatter()], 
        validator: (v) => v!.length != 18 ? 'CNPJ inválido' : null,
      ),
    _buildTextField(controller: _phoneController, hintText: 'Telefone com DDD', keyboardType: TextInputType.phone, inputFormatters: [PhoneInputFormatter()], validator: (v) => v!.length < 14 ? 'Telefone inválido' : null),
    _buildTextField(controller: _emailController, hintText: 'E-mail de Contato', keyboardType: TextInputType.emailAddress, validator: (v) => (v!.isEmpty || !v.contains('@')) ? 'E-mail inválido' : null),
    _buildTextField(controller: _passwordController, hintText: 'Senha (mínimo 8 caracteres)', obscureText: true, validator: (v) => (v!.length < 8) ? 'Senha muito curta' : null),
  ]);

  Widget _buildOfficeLinkStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _officeCodeController,
          decoration: const InputDecoration(
            labelText: 'Código do Escritório',
            hintText: 'Insira o código fornecido pelo escritório',
            prefixIcon: Icon(Icons.qr_code),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira o código do escritório.';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.withOpacity(0.05),
          ),
          child: CheckboxListTile(
            title: const Text('Sou associado do escritório titular LITGO'),
            subtitle: Text(
              'Super-Associados captam casos diretamente da plataforma e precisam assinar um contrato de associação específico.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: _isPlatformAssociate,
            onChanged: (value) {
              setState(() {
                _isPlatformAssociate = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.blue,
          ),
        ),
      ],
    );
  }

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
    _buildFileUploadField(label: 'Currículo (PDF/DOC)', file: _cvFile, onTap: () => _pickFile((f) => _cvFile = f)),
    _buildFileUploadField(label: 'Cópia da OAB (PDF/JPG/PNG)', file: _oabFile, onTap: () => _pickFile((f) => _oabFile = f)),
    _buildFileUploadField(label: 'Comprov. de Residência (PDF/JPG/PNG)', file: _residenceProofFile, onTap: () => _pickFile((f) => _residenceProofFile = f)),
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

  Widget _buildStep5({required bool isAssociated}) {
    final text = isAssociated 
      ? 'Ao clicar em "FINALIZAR CADASTRO", você concorda com os termos do Contrato de Associação do escritório, que será apresentado para aceite após a aprovação do seu cadastro. A sua relação será exclusivamente com o escritório contratante, nos termos da Lei nº 8.906/94.'
      : 'Ao clicar em "FINALIZAR CADASTRO", você concorda com os Termos de Uso e a Política de Privacidade da plataforma LITIG. Você atuará como parceiro independente, sem vínculo empregatício, e será responsável por seus próprios atos profissionais.';
    
    return Column(children: [
      Text(isAssociated ? 'Contrato de Associação' : 'Termos de Uso e Parceria', style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 16),
      Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: SingleChildScrollView(child: Text(text)),
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        title: const Text('Li e concordo com os termos'),
        value: _agreedToTerms,
        onChanged: (value) => setState(() => _agreedToTerms = value!),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    ]);
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool obscureText = false, String? Function(String?)? validator, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(controller: controller, obscureText: obscureText, decoration: InputDecoration(hintText: hintText, border: const OutlineInputBorder()), validator: validator, keyboardType: keyboardType, inputFormatters: inputFormatters, textCapitalization: textCapitalization),
    );
  }

  Widget _buildFileUploadField({required String label, required File? file, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: file == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.upload_file, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text(label, style: theme.textTheme.bodyMedium),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade400),
                  const SizedBox(width: 12),
                  Expanded(child: Text(file.path.split('/').last, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
                ]),
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
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
      } else if (i == 9) formatted += '-';
      formatted += text[i];
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CnpjInputFormatter extends TextInputFormatter {
   @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    var formatted = '';
     for (var i = 0; i < text.length; i++) {
       if (i == 2 || i == 5) {
         formatted += '.';
       } else if (i == 8) formatted += '/';
       else if (i == 12) formatted += '-';
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
    if (text.length > 11) return oldValue;
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
      if (i == 5) formatted += '-';
      formatted += text[i];
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 