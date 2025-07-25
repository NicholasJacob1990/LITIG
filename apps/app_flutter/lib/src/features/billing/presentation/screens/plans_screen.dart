import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meu_app/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:meu_app/src/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String? _selectedPlan;
  bool _isUpgrading = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;
        final entityType = _getEntityTypeFromUser(user);
        final entityId = _getEntityIdFromUser(user);

        return BlocProvider(
          create: (context) => BillingBloc()
            ..add(LoadAvailablePlans(entityType))
            ..add(LoadCurrentPlan(entityType, entityId)),
          child: Scaffold(
            appBar: AppBar(
              title: Text(_getPageTitle(entityType)),
              backgroundColor: _getThemeColor(entityType),
              foregroundColor: Colors.white,
            ),
            body: BlocListener<BillingBloc, BillingState>(
              listener: (context, state) {
                if (state is BillingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is CheckoutSessionCreated) {
                  _launchCheckout(state.checkoutUrl);
                } else if (state is PlanUpgraded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plano atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _isUpgrading = false;
                    _selectedPlan = null;
                  });
                }
              },
              child: BlocBuilder<BillingBloc, BillingState>(
                builder: (context, state) {
                  if (state is BillingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, entityType, user),
                        const SizedBox(height: 24),
                        _buildCurrentPlan(context, state),
                        const SizedBox(height: 32),
                        _buildAvailablePlans(context, state, entityType, entityId),
                        const SizedBox(height: 32),
                        _buildFeatureComparison(context, state, entityType),
                        const SizedBox(height: 32),
                        _buildFAQ(context, entityType),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String entityType, dynamic user) {
    String title, subtitle;
    IconData icon;
    Color color = _getThemeColor(entityType);

    switch (entityType) {
      case 'client':
        title = user.clientType == 'PJ' ? 'Planos Empresariais' : 'Planos Pessoais';
        subtitle = user.clientType == 'PJ' 
          ? 'Soluções jurídicas para sua empresa'
          : 'Assistência jurídica personalizada';
        icon = user.clientType == 'PJ' ? LucideIcons.building : LucideIcons.user;
        break;
      case 'lawyer':
        title = 'Planos Profissionais';
        subtitle = 'Destaque-se e acesse casos premium';
        icon = LucideIcons.briefcase;
        break;
      case 'firm':
        title = 'Planos para Escritórios';
        subtitle = 'Cresça seu escritório com visibilidade máxima';
        icon = LucideIcons.building2;
        break;
      default:
        title = 'Planos Disponíveis';
        subtitle = 'Escolha o melhor plano para você';
        icon = LucideIcons.star;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlan(BuildContext context, BillingState state) {
    if (state is! PlansLoaded) {
      return const SizedBox.shrink();
    }

    final currentPlan = state.currentPlan;
    if (currentPlan == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Plano Atual',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getPlanColor(currentPlan['id']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getPlanColor(currentPlan['id'])),
                  ),
                  child: Text(
                    currentPlan['name'],
                    style: TextStyle(
                      color: _getPlanColor(currentPlan['id']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (currentPlan['price_monthly'] > 0)
                  Text(
                    'R\$ ${currentPlan['price_monthly'].toStringAsFixed(2)}/mês',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    'Gratuito',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recursos inclusos:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...currentPlan['features'].map<Widget>((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(LucideIcons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlans(BuildContext context, BillingState state, String entityType, String entityId) {
    if (state is! PlansLoaded) {
      return const SizedBox.shrink();
    }

    final plans = state.availablePlans.where((plan) => plan['id'] != 'FREE').toList();
    if (plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upgrade Disponíveis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...plans.map((plan) => _buildPlanCard(context, plan, entityType, entityId)),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan, String entityType, String entityId) {
    final isSelected = _selectedPlan == plan['id'];
    final color = _getPlanColor(plan['id']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getPlanIcon(plan['id']), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          plan['description'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${plan['price_monthly'].toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '/mês',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recursos inclusos:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...plan['features'].map<Widget>((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.check, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpgrading ? null : () => _selectPlan(context, plan, entityType, entityId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpgrading && isSelected
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Fazer Upgrade',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context, BillingState state, String entityType) {
    if (state is! PlansLoaded) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparação de Recursos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonTable(context, state.availablePlans, entityType),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<Map<String, dynamic>> plans, String entityType) {
    // Simplified comparison - you can expand this
    return Column(
      children: [
        Row(
          children: [
            const Expanded(flex: 2, child: Text('Recurso')),
            ...plans.map((plan) => Expanded(
              child: Text(
                plan['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),
        const Divider(),
        // Add comparison rows based on entity type
        if (entityType == 'client') ...[
          _buildComparisonRow('Casos por mês', ['2', 'Ilimitados', 'Ilimitados']),
          _buildComparisonRow('Suporte', ['Email', 'Prioritário', '24/7']),
          _buildComparisonRow('SLA', ['Não', 'Não', '1 hora']),
        ] else if (entityType == 'lawyer') ...[
          _buildComparisonRow('Casos por mês', ['5', 'Ilimitados']),
          _buildComparisonRow('Comissão', ['15%', '10%']),
          _buildComparisonRow('Analytics', ['Básico', 'Avançado']),
        ] else if (entityType == 'firm') ...[
          _buildComparisonRow('Advogados', ['3', '20', 'Ilimitados']),
          _buildComparisonRow('Comissão', ['15%', '12%', '8%']),
          _buildComparisonRow('White-label', ['Não', 'Não', 'Sim']),
        ],
      ],
    );
  }

  Widget _buildComparisonRow(String feature, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature)),
          ...values.map((value) => Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context, String entityType) {
    final faqs = _getFAQsForEntityType(entityType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dúvidas Frequentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map((faq) => ExpansionTile(
              title: Text(faq['question'] ?? ''),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(faq['answer'] ?? ''),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  void _selectPlan(BuildContext context, Map<String, dynamic> plan, String entityType, String entityId) {
    setState(() {
      _selectedPlan = plan['id'];
      _isUpgrading = true;
    });

    context.read<BillingBloc>().add(CreateCheckoutSession(
      targetPlan: plan['id'],
      entityType: entityType,
      entityId: entityId,
      successUrl: 'litig://billing/success',
      cancelUrl: 'litig://billing/cancel',
    ));
  }

  void _launchCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao abrir checkout'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      _isUpgrading = false;
      _selectedPlan = null;
    });
  }

  String _getEntityTypeFromUser(dynamic user) {
    if (user.role?.contains('lawyer') == true) {
      return 'lawyer';
    } else if (user.role?.contains('firm') == true || user.role?.contains('office') == true) {
      return 'firm';
    } else {
      return 'client';
    }
  }

  String _getEntityIdFromUser(dynamic user) {
    // This would need to be implemented based on your user model
    return user.id;
  }

  String _getPageTitle(String entityType) {
    switch (entityType) {
      case 'client': return 'Planos e Assinaturas';
      case 'lawyer': return 'Planos Profissionais';
      case 'firm': return 'Planos Corporativos';
      default: return 'Planos';
    }
  }

  Color _getThemeColor(String entityType) {
    switch (entityType) {
      case 'client': return Colors.blue;
      case 'lawyer': return Colors.green;
      case 'firm': return Colors.purple;
      default: return Colors.blue;
    }
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'FREE': return Colors.grey;
      case 'VIP': return Colors.amber;
      case 'ENTERPRISE': return Colors.purple;
      case 'PRO': return Colors.green;
      case 'PARTNER': return Colors.blue;
      case 'PREMIUM': return Colors.indigo;
      default: return Colors.blue;
    }
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'FREE': return LucideIcons.user;
      case 'VIP': return LucideIcons.crown;
      case 'ENTERPRISE': return LucideIcons.building;
      case 'PRO': return LucideIcons.star;
      case 'PARTNER': return LucideIcons.users;
      case 'PREMIUM': return LucideIcons.diamond;
      default: return LucideIcons.star;
    }
  }

  List<Map<String, String>> _getFAQsForEntityType(String entityType) {
    if (entityType == 'client') {
      return [
        {
          'question': 'Como funciona o plano VIP?',
          'answer': 'O plano VIP oferece acesso prioritário aos melhores advogados, suporte dedicado e casos ilimitados.'
        },
        {
          'question': 'Posso cancelar a qualquer momento?',
          'answer': 'Sim, você pode cancelar sua assinatura a qualquer momento sem taxas de cancelamento.'
        },
        {
          'question': 'O que inclui o SLA de 1 hora no Enterprise?',
          'answer': 'Garantimos resposta inicial em até 1 hora útil para questões urgentes.'
        },
      ];
    } else if (entityType == 'lawyer') {
      return [
        {
          'question': 'Como funciona a comissão reduzida?',
          'answer': 'Advogados PRO pagam apenas 10% de comissão por caso fechado, comparado aos 15% padrão.'
        },
        {
          'question': 'Que casos premium terei acesso?',
          'answer': 'Casos de clientes VIP e Enterprise, com valores mais altos e menor concorrência.'
        },
      ];
    } else {
      return [
        {
          'question': 'Quantos advogados posso adicionar?',
          'answer': 'No Partner até 20 advogados, no Premium não há limite.'
        },
        {
          'question': 'O que é white-label?',
          'answer': 'Personalização completa da plataforma com sua marca e identidade visual.'
        },
      ];
    }
  }
} 