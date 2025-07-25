/// Teste de sistema para o módulo de perfil
/// Verifica a integração completa entre UI, BLoC e repositórios
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports do sistema de perfil
import 'domain/entities/client_profile.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/datasources/profile_remote_data_source.dart';
import 'data/datasources/profile_local_data_source.dart';
import 'presentation/bloc/profile_bloc.dart';
import 'presentation/bloc/profile_event.dart';
import 'presentation/bloc/profile_state.dart';
import 'presentation/widgets/address_section.dart';
import '../../shared/utils/validators.dart';

class ProfileSystemTestPage extends StatelessWidget {
  const ProfileSystemTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Sistema de Perfil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocProvider(
        create: (context) => ProfileBloc(
          profileRepository: ProfileRepositoryImpl(
            remoteDataSource: ProfileRemoteDataSourceImpl(),
            localDataSource: ProfileLocalDataSourceImpl(),
          ),
        ),
        child: const ProfileSystemTestView(),
      ),
    );
  }
}

class ProfileSystemTestView extends StatefulWidget {
  const ProfileSystemTestView({super.key});

  @override
  State<ProfileSystemTestView> createState() => _ProfileSystemTestViewState();
}

class _ProfileSystemTestViewState extends State<ProfileSystemTestView> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  List<Address> _testAddresses = [];

  @override
  void initState() {
    super.initState();
    _runSystemTests();
  }

  void _runSystemTests() {
    print('🧪 Iniciando testes do sistema de perfil...');
    
    // Teste 1: Validadores
    _testValidators();
    
    // Teste 2: Criar perfil mock
    _testProfileCreation();
    
    // Teste 3: Carregar perfil via BLoC
    context.read<ProfileBloc>().add(const LoadProfile('test_user_123'));
    
    print('✅ Testes básicos concluídos!');
  }

  void _testValidators() {
    print('🔍 Testando validadores...');
    
    // Teste CPF válido
    final validCPF = Validators.validateCPF('123.456.789-00');
    print('CPF válido: ${validCPF == null ? "✅ OK" : "❌ $validCPF"}');
    
    // Teste CPF inválido
    final invalidCPF = Validators.validateCPF('123.456.789-99');
    print('CPF inválido: ${invalidCPF != null ? "✅ OK" : "❌ Deveria ser inválido"}');
    
    // Teste email
    final validEmail = Validators.validateEmail('teste@exemplo.com');
    print('Email válido: ${validEmail == null ? "✅ OK" : "❌ $validEmail"}');
    
    // Teste telefone
    final validPhone = Validators.validatePhone('(11) 99999-9999');
    print('Telefone válido: ${validPhone == null ? "✅ OK" : "❌ $validPhone"}');
  }

  void _testProfileCreation() {
    print('👤 Testando criação de perfil...');
    
    try {
      final testProfile = ClientProfile(
        id: 'test_user_123',
        type: ClientType.individual,
        personalData: const PersonalData(
          cpf: '123.456.789-00',
          rg: '12.345.678-9',
          rgIssuingBody: 'SSP/SP',
        ),
        contactData: const ContactData(
          primaryPhone: '(11) 99999-9999',
          whatsappAuthorized: true,
        ),
        addresses: const [],
        documents: const [],
        communicationPreferences: const CommunicationPreferences(
          preferredChannels: [
            PreferredChannel(
              type: ChannelType.email,
              isEnabled: true,
              priority: 1,
            ),
          ],
          availability: ClientAvailability(
            timezone: 'America/Sao_Paulo',
            weeklySchedule: {},
            acceptHolidays: false,
            acceptEmergencyOutsideHours: true,
          ),
          notificationSettings: {},
          authorizations: {},
        ),
        privacySettings: PrivacySettings(
          dataUsageConsents: const {},
          thirdPartySharing: const {},
          allowDataExport: true,
          allowDataDeletion: true,
          lastUpdated: DateTime.now(),
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      
      // Teste copyWith
      final updatedProfile = testProfile.copyWith(
        personalData: const PersonalData(
          cpf: '123.456.789-00',
          rg: '98.765.432-1',
          rgIssuingBody: 'SSP/RJ',
        ),
      );
      
      print('Perfil criado: ✅ OK');
      print('CopyWith funcionando: ${updatedProfile.personalData.rg == "98.765.432-1" ? "✅ OK" : "❌ Erro"}');
      
    } catch (e) {
      print('❌ Erro na criação do perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status do Sistema',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  BlocConsumer<ProfileBloc, ProfileState>(
                    listener: (context, state) {
                      if (state is ProfileError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${state.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (state is ProfileLoaded) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Perfil carregado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is ProfileLoading) {
                        return const Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Carregando perfil...'),
                          ],
                        );
                      } else if (state is ProfileLoaded) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Sistema funcionando corretamente!'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Perfil ID: ${state.profile.id}'),
                            Text('Tipo: ${state.profile.type.name}'),
                            Text('CPF: ${state.profile.personalData.cpf ?? "Não informado"}'),
                            Text('Telefone: ${state.profile.contactData.primaryPhone ?? "Não informado"}'),
                            Text('Endereços: ${state.profile.addresses.length}'),
                            Text('Documentos: ${state.profile.documents.length}'),
                          ],
                        );
                      } else if (state is ProfileError) {
                        return Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Erro: ${state.message}')),
                          ],
                        );
                      }
                      
                      return const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Sistema inicializado'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Teste dos validadores em tempo real
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teste de Validadores',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '123.456.789-00',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateCPF,
                    onChanged: (value) => setState(() {}),
                  ),
                  if (_cpfController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        Validators.validateCPF(_cpfController.text) ?? '✅ CPF válido',
                        style: TextStyle(
                          color: Validators.validateCPF(_cpfController.text) == null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'usuario@exemplo.com',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateEmail,
                    onChanged: (value) => setState(() {}),
                  ),
                  if (_emailController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        Validators.validateEmail(_emailController.text) ?? '✅ Email válido',
                        style: TextStyle(
                          color: Validators.validateEmail(_emailController.text) == null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Teste do widget de endereços
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teste Widget de Endereços',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  AddressesSection(
                    addresses: _testAddresses,
                    onChanged: (addresses) {
                      setState(() {
                        _testAddresses = addresses;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Endereços atualizados: ${addresses.length} endereços'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botões de teste
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ações de Teste',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.read<ProfileBloc>().add(
                          const LoadProfile('test_user_123'),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recarregar Perfil'),
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          print('🧪 Executando teste completo...');
                          _runSystemTests();
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Executar Testes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
    void _cpfController.dispose();
    void _emailController.dispose();
    void _phoneController.dispose();
    void super.dispose();
  }
}