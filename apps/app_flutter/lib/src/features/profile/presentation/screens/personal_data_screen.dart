import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/client_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/address_section.dart';
import '../widgets/contact_data_form.dart';
import '../widgets/personal_data_form_pf.dart';
import '../widgets/personal_data_form_pj.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late ClientProfile _currentProfile;
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados Pessoais'),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePersonalData,
            ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ProfileUpdated) {
            setState(() {
              _hasUnsavedChanges = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dados salvos com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const PersonalDataSkeletonLoader();
          }
          
          if (state is ProfileLoaded) {
            _currentProfile = state.profile;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                onChanged: () {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                },
                child: Column(
                  children: [
                    ClientTypeHeader(clientType: state.profile.type),
                    
                    const SizedBox(height: 24),
                    
                    if (state.profile.type == ClientType.individual) 
                      PersonalDataFormPF(
                        personalData: state.profile.personalData,
                        onChanged: _updatePersonalData,
                      )
                    else 
                      PersonalDataFormPJ(
                        personalData: state.profile.personalData,
                        onChanged: _updatePersonalData,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    ContactDataForm(
                      contactData: state.profile.contactData,
                      onChanged: _updateContactData,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    AddressesSection(
                      addresses: state.profile.addresses,
                      onChanged: _updateAddresses,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    PersonalDataActions(
                      hasUnsavedChanges: _hasUnsavedChanges,
                      onSave: _savePersonalData,
                      onCancel: _cancelChanges,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const PersonalDataErrorWidget();
        },
      ),
    );
  }

  void _updatePersonalData(PersonalData personalData) {
    setState(() {
      _currentProfile = ClientProfile(
        id: _currentProfile.id,
        type: _currentProfile.type,
        personalData: personalData,
        contactData: _currentProfile.contactData,
        addresses: _currentProfile.addresses,
        documents: _currentProfile.documents,
        communicationPreferences: _currentProfile.communicationPreferences,
        privacySettings: _currentProfile.privacySettings,
        createdAt: _currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _updateContactData(ContactData contactData) {
    setState(() {
      _currentProfile = ClientProfile(
        id: _currentProfile.id,
        type: _currentProfile.type,
        personalData: _currentProfile.personalData,
        contactData: contactData,
        addresses: _currentProfile.addresses,
        documents: _currentProfile.documents,
        communicationPreferences: _currentProfile.communicationPreferences,
        privacySettings: _currentProfile.privacySettings,
        createdAt: _currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _updateAddresses(List<Address> addresses) {
    setState(() {
      _currentProfile = ClientProfile(
        id: _currentProfile.id,
        type: _currentProfile.type,
        personalData: _currentProfile.personalData,
        contactData: _currentProfile.contactData,
        addresses: addresses,
        documents: _currentProfile.documents,
        communicationPreferences: _currentProfile.communicationPreferences,
        privacySettings: _currentProfile.privacySettings,
        createdAt: _currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  void _savePersonalData() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      context.read<ProfileBloc>().add(UpdateProfile(_currentProfile));
    }
  }

  void _cancelChanges() {
    context.read<ProfileBloc>().add(const LoadProfile('current_user'));
    setState(() {
      _hasUnsavedChanges = false;
    });
  }
}

class ClientTypeHeader extends StatelessWidget {
  final ClientType clientType;

  const ClientTypeHeader({
    super.key,
    required this.clientType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            clientType == ClientType.individual 
                ? Icons.person 
                : Icons.business,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientType == ClientType.individual 
                    ? 'Pessoa Física' 
                    : 'Pessoa Jurídica',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                clientType == ClientType.individual 
                    ? 'Dados pessoais do cliente individual' 
                    : 'Dados empresariais do cliente corporativo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PersonalDataActions extends StatelessWidget {
  final bool hasUnsavedChanges;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const PersonalDataActions({
    super.key,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasUnsavedChanges) ...[
          OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton.icon(
          onPressed: hasUnsavedChanges ? onSave : null,
          icon: const Icon(Icons.save),
          label: const Text('Salvar Alterações'),
        ),
      ],
    );
  }
}

class PersonalDataSkeletonLoader extends StatelessWidget {
  const PersonalDataSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(height: 80, width: double.infinity),
          SizedBox(height: 24),
          SkeletonLoader(height: 400, width: double.infinity),
          SizedBox(height: 24),
          SkeletonLoader(height: 300, width: double.infinity),
          SizedBox(height: 24),
          SkeletonLoader(height: 200, width: double.infinity),
        ],
      ),
    );
  }
}

class PersonalDataErrorWidget extends StatelessWidget {
  const PersonalDataErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados pessoais',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Por favor, tente novamente mais tarde.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(const LoadProfile('current_user'));
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}