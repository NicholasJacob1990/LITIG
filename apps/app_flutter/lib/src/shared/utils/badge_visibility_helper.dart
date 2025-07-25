/// Helper para gerenciar a lógica de visibilidade de badges em contexto B2B
/// 
/// Este helper implementa a matriz completa de visibilidade baseada nos tipos de usuário:
/// - Advogados: associado, super associado, escritório, autônomo
/// - Pessoas Jurídicas: clientes corporativos
/// - Relações B2B entre todos os tipos
class BadgeVisibilityHelper {
  
  /// Tipos de usuário advogado
  static const Set<String> _lawyerRoles = {
    'lawyer_associated',      // Advogado associado
    'lawyer_platform_associate', // Super associado
    'lawyer_office',          // Escritório
    'lawyer_individual',      // Autônomo
    'lawyer',                 // Genérico
  };

  /// Tipos de usuário cliente
  static const Set<String> _clientRoles = {
    'client',
    'client_individual',      // PF
    'client_corporate',       // PJ
    'client_enterprise',      // PJ Enterprise
  };

  /// Planos VIP para clientes (tanto PF quanto PJ)
  static const Set<String> _vipClientPlans = {
    'VIP',
    'ENTERPRISE',
  };

  /// Tipos de usuário administrativo
  static const Set<String> _adminRoles = {
    'admin',
    'super_admin',
    'moderator',
  };

  /// Verifica se o usuário é advogado (qualquer tipo)
  static bool isLawyer(String? role) {
    if (role == null) return false;
    return _lawyerRoles.contains(role);
  }

  /// Verifica se o usuário é cliente (qualquer tipo)
  static bool isClient(String? role) {
    if (role == null) return false;
    return _clientRoles.contains(role);
  }

  /// Verifica se o usuário é cliente PJ
  static bool isCorporateClient(String? role) {
    if (role == null) return false;
    return role == 'client_corporate' || role == 'client_enterprise';
  }

  /// Verifica se o plano do cliente (PF ou PJ) é VIP ou Enterprise
  static bool isVipOrEnterprisePlan(String? clientPlan) {
    if (clientPlan == null) return false;
    return _vipClientPlans.contains(clientPlan.toUpperCase());
  }

  /// Verifica se o usuário é admin
  static bool isAdmin(String? role) {
    if (role == null) return false;
    return _adminRoles.contains(role);
  }

  /// Verifica se o usuário é escritório
  static bool isLawOffice(String? role) {
    return role == 'lawyer_office';
  }

  /// Verifica se o usuário é super associado
  static bool isPlatformAssociate(String? role) {
    return role == 'lawyer_platform_associate';
  }

  /// BADGE PREMIUM CASE - Quem deve ver casos premium
  static bool shouldShowPremiumCaseBadge(String? viewerRole, {bool isPremium = false}) {
    if (!isPremium) return false;
    return isLawyer(viewerRole) || isAdmin(viewerRole);
  }

  /// BADGE ENTERPRISE CASE - Quem deve ver casos enterprise
  static bool shouldShowEnterpriseCaseBadge(String? viewerRole, {bool isEnterprise = false}) {
    if (!isEnterprise) return false;
    return isLawyer(viewerRole) || isAdmin(viewerRole);
  }

  /// BADGE VIP CLIENT - Para marcar clientes importantes (PF ou PJ)
  static bool shouldShowVipClientBadge(String? viewerRole, String? clientPlan) {
    final isVip = isVipOrEnterprisePlan(clientPlan);
    if (!isVip) return false;
    
    // Apenas advogados e escritórios veem clientes VIP (para priorização)
    return isLawyer(viewerRole) || isAdmin(viewerRole);
  }

  /// BADGE PRO LAWYER - Quem deve ver badge PRO do advogado
  static bool shouldShowProLawyerBadge(String? viewerRole, String? lawyerPlan, {bool isPremiumCase = false}) {
    if (lawyerPlan?.toUpperCase() != 'PRO') return false;
    
    // Clientes veem PRO badge para identificar qualidade
    if (isClient(viewerRole)) return true;
    
    // Admins veem tudo
    if (isAdmin(viewerRole)) return true;
    
    // Advogados não veem badge PRO de outros advogados (evita competição visual)
    return false;
  }

  /// BADGE PARTNER FIRM - Quem deve ver badges de parceria de escritório
  static bool shouldShowPartnerFirmBadge(String? viewerRole, String? firmPlan, String? firmTier) {
    final hasPlan = firmPlan?.toUpperCase() == 'PRO';
    final hasTier = firmTier?.toUpperCase() != 'STANDARD';
    
    if (!hasPlan && !hasTier) return false;

    // Clientes PJ veem badges de parceria para avaliar SLA corporativo
    if (isCorporateClient(viewerRole)) return true;
    
    // Advogados veem para identificar oportunidades de parceria
    if (isLawyer(viewerRole)) return true;
    
    // Admins veem tudo
    if (isAdmin(viewerRole)) return true;
    
    return false;
  }

  /// CONTEXTO DE CASO PREMIUM - Lógica especial para casos premium
  static BadgeContext getPremiumCaseContext(String? viewerRole, bool isPremium, bool isEnterprise) {
    if (isEnterprise) {
      return BadgeContext(
        showBadge: shouldShowEnterpriseCaseBadge(viewerRole, isEnterprise: isEnterprise),
        badgeText: 'Enterprise',
        badgeColor: BadgeColor.indigo,
        priority: 1, // Maior prioridade
      );
    } else if (isPremium) {
      return BadgeContext(
        showBadge: shouldShowPremiumCaseBadge(viewerRole, isPremium: isPremium),
        badgeText: 'Premium',
        badgeColor: BadgeColor.amber,
        priority: 2,
      );
    }
    
    return BadgeContext(showBadge: false);
  }

  /// CONTEXTO DE CLIENTE VIP/ENTERPRISE - Função para badges de cliente (PF ou PJ)
  static BadgeContext getVipClientContext(String? viewerRole, String? clientPlan) {
    if (!isVipOrEnterprisePlan(clientPlan)) {
      return BadgeContext(showBadge: false);
    }

    final shouldShow = shouldShowVipClientBadge(viewerRole, clientPlan);
    
    // Determinar texto e cor baseado no plano
    String badgeText;
    BadgeColor badgeColor;
    int priority;
    
    switch (clientPlan?.toUpperCase()) {
      case 'ENTERPRISE':
        badgeText = 'Cliente Enterprise';
        badgeColor = BadgeColor.indigo;
        priority = 1;
        break;
      case 'VIP':
        badgeText = 'Cliente VIP';
        badgeColor = BadgeColor.purple;
        priority = 2;
        break;
      default:
        badgeText = 'Cliente Premium';
        badgeColor = BadgeColor.blue;
        priority = 3;
        break;
    }
    
    return BadgeContext(
      showBadge: shouldShow,
      badgeText: badgeText,
      badgeColor: badgeColor,
      priority: priority,
    );
  }

  /// CONTEXTO DE ADVOGADO PRO - Lógica especial para advogados PRO
  static BadgeContext getProLawyerContext(String? viewerRole, String? lawyerPlan, bool isPremiumCase) {
    if (lawyerPlan?.toUpperCase() != 'PRO') {
      return BadgeContext(showBadge: false);
    }

    final shouldShow = shouldShowProLawyerBadge(viewerRole, lawyerPlan, isPremiumCase: isPremiumCase);
    
    return BadgeContext(
      showBadge: shouldShow,
      badgeText: isPremiumCase ? 'Prioritário PRO' : 'PRO',
      badgeColor: isPremiumCase ? BadgeColor.amber : BadgeColor.green,
      priority: isPremiumCase ? 1 : 3,
    );
  }

  /// CONTEXTO DE ESCRITÓRIO PARCEIRO - Lógica para badges de escritório
  static List<BadgeContext> getPartnerFirmContexts(String? viewerRole, String? firmPlan, String? firmTier) {
    final contexts = <BadgeContext>[];
    
    // Badge PRO Plan
    if (firmPlan?.toUpperCase() == 'PRO') {
      contexts.add(BadgeContext(
        showBadge: shouldShowPartnerFirmBadge(viewerRole, firmPlan, firmTier),
        badgeText: 'PRO',
        badgeColor: BadgeColor.green,
        priority: 2,
      ));
    }
    
    // Badge Partnership Tier
    if (firmTier?.toUpperCase() != 'STANDARD') {
      contexts.add(BadgeContext(
        showBadge: shouldShowPartnerFirmBadge(viewerRole, firmPlan, firmTier),
        badgeText: firmTier?.toUpperCase() ?? '',
        badgeColor: _getTierColor(firmTier),
        priority: 1,
      ));
    }
    
    return contexts;
  }

  /// Retorna a cor baseada no tier de parceria
  static BadgeColor _getTierColor(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'SILVER':
        return BadgeColor.grey;
      case 'GOLD':
        return BadgeColor.orange;
      case 'PLATINUM':
        return BadgeColor.purple;
      default:
        return BadgeColor.blue;
    }
  }
}

/// Contexto de badge com informações de exibição
class BadgeContext {
  final bool showBadge;
  final String badgeText;
  final BadgeColor badgeColor;
  final int priority; // 1 = maior prioridade

  const BadgeContext({
    required this.showBadge,
    this.badgeText = '',
    this.badgeColor = BadgeColor.grey,
    this.priority = 99,
  });
}

/// Cores padronizadas para badges
enum BadgeColor {
  green,
  amber,
  indigo,
  grey,
  orange,
  purple,
  blue,
} 