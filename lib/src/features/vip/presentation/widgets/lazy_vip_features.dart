import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Sistema de Lazy Loading para Features VIP
///
/// 🚀 OTIMIZAÇÕES IMPLEMENTADAS:
/// - Carregamento sob demanda apenas quando necessário
/// - Cache de widgets carregados para evitar re-loading
/// - Priorização de features VIP vs features normais
/// - Skeleton loading para melhor UX
class LazyVipFeatures extends HookWidget {
  final String userId;
  final String? userPlan;
  final bool isVip;

  const LazyVipFeatures({
    super.key,
    required this.userId,
    required this.userPlan,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    // Estados de carregamento memoizados
    final isLoadingBenefits = useState<bool>(false);
    final isLoadingPremiumLawyers = useState<bool>(false);
    final isLoadingSupport = useState<bool>(false);
    
    // Cache de features carregadas
    final benefitsCache = useRef<Widget?>(null);
    final lawyersCache = useRef<Widget?>(null);
    final supportCache = useRef<Widget?>(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🎯 BENEFÍCIOS VIP - Carregamento expansível
        ExpansionTile(
          leading: Icon(
            Icons.star,
            color: isVip ? Colors.amber : Colors.grey,
          ),
          title: Text(
            'Benefícios ${isVip ? 'VIP' : 'Padrão'}',
            style: TextStyle(
              fontWeight: isVip ? FontWeight.bold : FontWeight.normal,
              color: isVip ? Colors.amber.shade700 : Colors.grey.shade700,
            ),
          ),
          subtitle: Text(
            isVip 
              ? 'Acesso a benefícios premium'
              : 'Benefícios básicos disponíveis',
          ),
          onExpansionChanged: (isExpanded) {
            if (isExpanded && benefitsCache.value == null) {
              _loadVipBenefits(
                userId, 
                userPlan, 
                isLoadingBenefits, 
                benefitsCache
              );
            }
          },
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBenefitsContent(
                isLoadingBenefits.value,
                benefitsCache.value,
                isVip,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🏢 ADVOGADOS PREMIUM - Só carrega se VIP
        if (isVip) 
          ExpansionTile(
            leading: const Icon(Icons.gavel, color: Colors.blue),
            title: const Text(
              'Advogados Premium',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Acesso exclusivo a advogados premium'),
            onExpansionChanged: (isExpanded) {
              if (isExpanded && lawyersCache.value == null) {
                _loadPremiumLawyers(
                  userId, 
                  isLoadingPremiumLawyers, 
                  lawyersCache
                );
              }
            },
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildLawyersContent(
                  isLoadingPremiumLawyers.value,
                  lawyersCache.value,
                ),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // 📞 SUPORTE - Carregamento condicional
        ExpansionTile(
          leading: Icon(
            Icons.support_agent,
            color: isVip ? Colors.green : Colors.grey,
          ),
          title: Text(
            isVip ? 'Suporte Premium 24/7' : 'Suporte Padrão',
            style: TextStyle(
              fontWeight: isVip ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            isVip 
              ? 'Atendimento prioritário disponível'
              : 'Horário comercial',
          ),
          onExpansionChanged: (isExpanded) {
            if (isExpanded && supportCache.value == null) {
              _loadSupportOptions(
                userId, 
                isVip, 
                isLoadingSupport, 
                supportCache
              );
            }
          },
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildSupportContent(
                isLoadingSupport.value,
                supportCache.value,
                isVip,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitsContent(
    bool isLoading, 
    Widget? cachedContent, 
    bool isVip
  ) {
    if (isLoading) {
      return _buildBenefitsSkeleton();
    }
    
    if (cachedContent != null) {
      return cachedContent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        isVip 
          ? 'Toque para carregar benefícios VIP'
          : 'Toque para ver benefícios disponíveis',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLawyersContent(bool isLoading, Widget? cachedContent) {
    if (isLoading) {
      return _buildLawyersSkeleton();
    }
    
    if (cachedContent != null) {
      return cachedContent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Toque para carregar advogados premium',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSupportContent(
    bool isLoading, 
    Widget? cachedContent, 
    bool isVip
  ) {
    if (isLoading) {
      return _buildSupportSkeleton();
    }
    
    if (cachedContent != null) {
      return cachedContent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        isVip 
          ? 'Toque para acessar suporte premium'
          : 'Toque para ver opções de suporte',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 🔄 Skeleton Loaders
  Widget _buildBenefitsSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLawyersSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) => 
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(2, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🚀 Funções de carregamento assíncrono
  Future<void> _loadVipBenefits(
    String userId,
    String? userPlan,
    ValueNotifier<bool> isLoading,
    ObjectRef<Widget?> cache,
  ) async {
    isLoading.value = true;
    
    try {
      // Simula carregamento de benefícios
      await Future.delayed(const Duration(milliseconds: 800));
      
      final benefits = await _fetchVipBenefits(userId, userPlan);
      cache.value = _buildBenefitsList(benefits);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPremiumLawyers(
    String userId,
    ValueNotifier<bool> isLoading,
    ObjectRef<Widget?> cache,
  ) async {
    isLoading.value = true;
    
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final lawyers = await _fetchPremiumLawyers(userId);
      cache.value = _buildLawyersList(lawyers);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSupportOptions(
    String userId,
    bool isVip,
    ValueNotifier<bool> isLoading,
    ObjectRef<Widget?> cache,
  ) async {
    isLoading.value = true;
    
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final supportOptions = await _fetchSupportOptions(userId, isVip);
      cache.value = _buildSupportOptions(supportOptions);
    } finally {
      isLoading.value = false;
    }
  }

  // 📊 Funções de fetch (simuladas)
  Future<List<String>> _fetchVipBenefits(String userId, String? plan) async {
    switch (plan?.toUpperCase()) {
      case 'VIP':
        return [
          'Atendimento prioritário',
          'Consultas ilimitadas', 
          'Suporte 24/7',
          'Acesso a advogados premium',
        ];
      case 'ENTERPRISE':
        return [
          'Soluções corporativas',
          'Equipe dedicada',
          'SLA garantido',
          'Relatórios customizados',
        ];
      default:
        return [
          'Consultas básicas',
          'Suporte em horário comercial',
          'Acesso ao sistema',
        ];
    }
  }

  Future<List<Map<String, String>>> _fetchPremiumLawyers(String userId) async {
    return [
      {'name': 'Dr. João Silva', 'specialty': 'Direito Corporativo'},
      {'name': 'Dra. Maria Santos', 'specialty': 'Direito Trabalhista'},
      {'name': 'Dr. Pedro Costa', 'specialty': 'Direito Tributário'},
    ];
  }

  Future<List<Map<String, String>>> _fetchSupportOptions(
    String userId, 
    bool isVip
  ) async {
    if (isVip) {
      return [
        {'title': 'Chat 24/7', 'description': 'Suporte instantâneo'},
        {'title': 'Telefone Premium', 'description': 'Linha direta VIP'},
        {'title': 'E-mail Prioritário', 'description': 'Resposta em 1h'},
      ];
    }
    
    return [
      {'title': 'Chat Padrão', 'description': 'Horário comercial'},
      {'title': 'E-mail', 'description': 'Resposta em 24h'},
    ];
  }

  // 🎨 Builders de conteúdo
  Widget _buildBenefitsList(List<String> benefits) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: benefits.map((benefit) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(benefit)),
              ],
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildLawyersList(List<Map<String, String>> lawyers) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: lawyers.map((lawyer) => 
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(lawyer['name']![0]),
                backgroundColor: Colors.blue.shade100,
              ),
              title: Text(lawyer['name']!),
              subtitle: Text(lawyer['specialty']!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildSupportOptions(List<Map<String, String>> options) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: options.map((option) => 
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.support_agent,
                color: Colors.green,
              ),
              title: Text(option['title']!),
              subtitle: Text(option['description']!),
              trailing: const Icon(Icons.launch, size: 16),
            ),
          ),
        ).toList(),
      ),
    );
  }
} 