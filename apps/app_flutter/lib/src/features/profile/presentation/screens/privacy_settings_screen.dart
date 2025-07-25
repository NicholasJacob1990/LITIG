import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/client_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late PrivacySettings _privacySettings;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile('current_user'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade e Proteção de Dados'),
        backgroundColor: Colors.purple[700],
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePrivacySettings,
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
                content: Text('Configurações de privacidade salvas com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const PrivacySkeletonLoader();
          }
          
          if (state is ProfileLoaded) {
            _privacySettings = state.profile.privacySettings;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const LGPDHeaderCard(),
                  
                  const SizedBox(height: 24),
                  
                  DataUsageConsentSection(
                    consents: _privacySettings.dataUsageConsents,
                    onChanged: _updateDataUsageConsents,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  ThirdPartySharingSection(
                    sharing: _privacySettings.thirdPartySharing,
                    onChanged: _updateThirdPartySharing,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  DataSubjectRightsSection(
                    settings: _privacySettings,
                    onExerciseRight: _exerciseDataRight,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  PrivacyActivitySection(
                    lastUpdated: _privacySettings.lastUpdated,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  PrivacyActions(
                    hasUnsavedChanges: _hasUnsavedChanges,
                    onSave: _savePrivacySettings,
                    onReset: _resetPrivacySettings,
                  ),
                ],
              ),
            );
          }
          
          return const PrivacyErrorWidget();
        },
      ),
    );
  }

  void _updateDataUsageConsents(Map<String, bool> consents) {
    setState(() {
      _privacySettings = PrivacySettings(
        dataUsageConsents: consents,
        thirdPartySharing: _privacySettings.thirdPartySharing,
        allowDataExport: _privacySettings.allowDataExport,
        allowDataDeletion: _privacySettings.allowDataDeletion,
        lastUpdated: DateTime.now(),
      );
      _hasUnsavedChanges = true;
    });
  }

  void _updateThirdPartySharing(Map<String, bool> sharing) {
    setState(() {
      _privacySettings = PrivacySettings(
        dataUsageConsents: _privacySettings.dataUsageConsents,
        thirdPartySharing: sharing,
        allowDataExport: _privacySettings.allowDataExport,
        allowDataDeletion: _privacySettings.allowDataDeletion,
        lastUpdated: DateTime.now(),
      );
      _hasUnsavedChanges = true;
    });
  }

  void _exerciseDataRight(DataSubjectRight right) {
    showDialog(
      context: context,
      builder: (context) => DataRightDialog(
        right: right,
        onConfirm: () => _processDataRight(right),
      ),
    );
  }

  void _processDataRight(DataSubjectRight right) {
    // TODO: Implement data right processing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitação de ${_getDataRightName(right)} processada'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getDataRightName(DataSubjectRight right) {
    switch (right) {
      case DataSubjectRight.access:
        return 'acesso aos dados';
      case DataSubjectRight.rectification:
        return 'correção de dados';
      case DataSubjectRight.erasure:
        return 'exclusão de dados';
      case DataSubjectRight.portability:
        return 'portabilidade de dados';
      case DataSubjectRight.objection:
        return 'oposição ao processamento';
      case DataSubjectRight.restriction:
        return 'limitação do processamento';
    }
  }

  void _savePrivacySettings() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      final updatedProfile = ClientProfile(
        id: profileState.profile.id,
        type: profileState.profile.type,
        personalData: profileState.profile.personalData,
        contactData: profileState.profile.contactData,
        addresses: profileState.profile.addresses,
        documents: profileState.profile.documents,
        communicationPreferences: profileState.profile.communicationPreferences,
        privacySettings: _privacySettings,
        createdAt: profileState.profile.createdAt,
        updatedAt: DateTime.now(),
      );
      
      context.read<ProfileBloc>().add(UpdateProfile(updatedProfile));
    }
  }

  void _resetPrivacySettings() {
    context.read<ProfileBloc>().add(const LoadProfile('current_user'));
    setState(() {
      _hasUnsavedChanges = false;
    });
  }
}

enum DataSubjectRight {
  access,
  rectification,
  erasure,
  portability,
  objection,
  restriction,
}

class LGPDHeaderCard extends StatelessWidget {
  const LGPDHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: Colors.purple[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Proteção de Dados - LGPD',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.purple[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus dados pessoais são protegidos conforme a Lei Geral de Proteção de Dados (Lei 13.709/2018). '
              'Você tem controle total sobre como suas informações são coletadas, processadas e compartilhadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.purple[800]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('Saiba mais sobre a LGPD'),
              onPressed: () => _showLGPDInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLGPDInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LGPDInfoDialog(),
    );
  }
}

class DataUsageConsentSection extends StatelessWidget {
  final Map<String, bool> consents;
  final ValueChanged<Map<String, bool>> onChanged;
  
  const DataUsageConsentSection({
    super.key,
    required this.consents,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consentimentos de Uso de Dados', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Gerencie suas autorizações para processamento de dados pessoais.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            _buildConsentToggle(
              context,
              'service_provision',
              'Prestação de Serviços Jurídicos',
              'Permitir o processamento de dados para prestação de serviços advocatícios',
              true, // Required consent
              Icons.gavel,
            ),
            
            _buildConsentToggle(
              context,
              'communications',
              'Comunicações e Notificações',
              'Receber comunicações sobre seus casos e serviços',
              false,
              Icons.message,
            ),
            
            _buildConsentToggle(
              context,
              'service_improvement',
              'Melhoria dos Serviços',
              'Usar dados para aprimorar a qualidade dos serviços oferecidos',
              false,
              Icons.trending_up,
            ),
            
            _buildConsentToggle(
              context,
              'analytics',
              'Análises e Estatísticas',
              'Permitir análises agregadas e anônimas para fins estatísticos',
              false,
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentToggle(
    BuildContext context,
    String key,
    String title,
    String description,
    bool isRequired,
    IconData icon,
  ) {
    final isConsented = consents[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Switch(
                value: isConsented,
                onChanged: isRequired ? null : (value) => _updateConsent(key, value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600]),
          ),
          
          if (isRequired) ...[ 
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consentimento obrigatório para o funcionamento do serviço.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateConsent(String key, bool value) {
    final updatedConsents = Map<String, bool>.from(consents);
    updatedConsents[key] = value;
    onChanged(updatedConsents);
  }
}

class ThirdPartySharingSection extends StatelessWidget {
  final Map<String, bool> sharing;
  final ValueChanged<Map<String, bool>> onChanged;
  
  const ThirdPartySharingSection({
    super.key,
    required this.sharing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compartilhamento com Terceiros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Configure com quais terceiros seus dados podem ser compartilhados.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            _buildSharingToggle(
              'law_enforcement',
              'Autoridades Legais',
              'Compartilhar dados quando exigido por lei ou ordem judicial',
              Icons.account_balance,
              Colors.red,
            ),
            
            _buildSharingToggle(
              'service_providers',
              'Prestadores de Serviços',
              'Compartilhar com parceiros técnicos necessários para prestação do serviço',
              Icons.business,
              Colors.blue,
            ),
            
            _buildSharingToggle(
              'marketing_partners',
              'Parceiros Comerciais',
              'Permitir compartilhamento para ofertas de serviços complementares',
              Icons.campaign,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingToggle(
    String key,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isAllowed = sharing[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(description),
        value: isAllowed,
        onChanged: (value) => _updateSharing(key, value),
      ),
    );
  }

  void _updateSharing(String key, bool value) {
    final updatedSharing = Map<String, bool>.from(sharing);
    updatedSharing[key] = value;
    onChanged(updatedSharing);
  }
}

class DataSubjectRightsSection extends StatelessWidget {
  final PrivacySettings settings;
  final Function(DataSubjectRight) onExerciseRight;
  
  const DataSubjectRightsSection({
    super.key,
    required this.settings,
    required this.onExerciseRight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seus Direitos como Titular de Dados', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'A LGPD garante diversos direitos sobre seus dados pessoais.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            DataRightOption(
              icon: Icons.visibility,
              title: 'Acessar meus dados',
              description: 'Solicitar uma cópia de todos os dados pessoais que processamos sobre você.',
              onTap: () => onExerciseRight(DataSubjectRight.access),
            ),
            
            DataRightOption(
              icon: Icons.edit,
              title: 'Corrigir meus dados',
              description: 'Solicitar correção de dados pessoais inexatos ou incompletos.',
              onTap: () => onExerciseRight(DataSubjectRight.rectification),
            ),
            
            DataRightOption(
              icon: Icons.delete_forever,
              title: 'Excluir meus dados',
              description: 'Solicitar a exclusão de dados pessoais quando não há necessidade de processamento.',
              onTap: () => onExerciseRight(DataSubjectRight.erasure),
              isDestructive: true,
            ),
            
            DataRightOption(
              icon: Icons.file_download,
              title: 'Exportar meus dados',
              description: 'Obter seus dados em formato estruturado e legível por máquina.',
              onTap: () => onExerciseRight(DataSubjectRight.portability),
            ),
          ],
        ),
      ),
    );
  }
}

class DataRightOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isDestructive;
  
  const DataRightOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive ? Colors.red.withValues(alpha: 0.3) : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyActivitySection extends StatelessWidget {
  final DateTime lastUpdated;
  
  const PrivacyActivitySection({
    super.key,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atividade de Privacidade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text('Última atualização: ${DateFormat('dd/MM/yyyy HH:mm').format(lastUpdated)}'),
              ],
            ),
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver Histórico Completo'),
              onPressed: () => _showPrivacyHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyHistory(BuildContext context) {
    // TODO: Implement privacy history dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Histórico de privacidade será implementado'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class PrivacyActions extends StatelessWidget {
  final bool hasUnsavedChanges;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const PrivacyActions({
    super.key,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasUnsavedChanges) ...[
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton.icon(
          onPressed: hasUnsavedChanges ? onSave : null,
          icon: const Icon(Icons.save),
          label: const Text('Salvar Configurações'),
        ),
      ],
    );
  }
}

class DataRightDialog extends StatelessWidget {
  final DataSubjectRight right;
  final VoidCallback onConfirm;
  
  const DataRightDialog({
    super.key,
    required this.right,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getRightTitle(right)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getRightDescription(right)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta solicitação será processada em até 15 dias úteis conforme a LGPD.',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Confirmar Solicitação'),
        ),
      ],
    );
  }

  String _getRightTitle(DataSubjectRight right) {
    switch (right) {
      case DataSubjectRight.access:
        return 'Solicitar Acesso aos Dados';
      case DataSubjectRight.rectification:
        return 'Solicitar Correção de Dados';
      case DataSubjectRight.erasure:
        return 'Solicitar Exclusão de Dados';
      case DataSubjectRight.portability:
        return 'Solicitar Portabilidade de Dados';
      case DataSubjectRight.objection:
        return 'Opor-se ao Processamento';
      case DataSubjectRight.restriction:
        return 'Limitar Processamento';
    }
  }

  String _getRightDescription(DataSubjectRight right) {
    switch (right) {
      case DataSubjectRight.access:
        return 'Você receberá uma cópia completa de todos os dados pessoais que temos sobre você.';
      case DataSubjectRight.rectification:
        return 'Poderá solicitar a correção de dados pessoais inexatos ou incompletos.';
      case DataSubjectRight.erasure:
        return 'Seus dados pessoais serão excluídos quando não houver necessidade de processamento.';
      case DataSubjectRight.portability:
        return 'Receberá seus dados em formato estruturado e legível por máquina.';
      case DataSubjectRight.objection:
        return 'Poderá se opor ao processamento de seus dados em situações específicas.';
      case DataSubjectRight.restriction:
        return 'O processamento de seus dados será limitado em circunstâncias específicas.';
    }
  }
}

class LGPDInfoDialog extends StatelessWidget {
  const LGPDInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sobre a LGPD'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A Lei Geral de Proteção de Dados (LGPD - Lei 13.709/2018) é a legislação brasileira que regulamenta o tratamento de dados pessoais.',
            ),
            SizedBox(height: 16),
            Text(
              'Seus direitos incluem:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Confirmação da existência de tratamento'),
            Text('• Acesso aos dados'),
            Text('• Correção de dados incompletos, inexatos ou desatualizados'),
            Text('• Anonimização, bloqueio ou eliminação'),
            Text('• Portabilidade dos dados'),
            Text('• Eliminação dos dados tratados com consentimento'),
            Text('• Informação sobre compartilhamento'),
            Text('• Informação sobre a possibilidade de não fornecer consentimento'),
            Text('• Revogação do consentimento'),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}

class PrivacySkeletonLoader extends StatelessWidget {
  const PrivacySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(height: 200), // Placeholder for content
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyErrorWidget extends StatelessWidget {
  const PrivacyErrorWidget({super.key});

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
            'Erro ao carregar configurações de privacidade',
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