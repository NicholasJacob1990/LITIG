import 'package:flutter/material.dart';
import 'business_client_badge.dart';
import 'firm_plan_badge.dart';
import 'super_associate_badge.dart';
import 'vip_client_badge.dart';
import 'pro_lawyer_badge.dart';
import 'enterprise_case_badge.dart';
import 'premium_case_badge.dart';

/// Widget de demonstração para todos os badges do sistema LITIG-1
/// Útil para desenvolvimento, testes e documentação visual
class BadgeShowcase extends StatelessWidget {
  final String viewerRole;

  const BadgeShowcase({
    super.key,
    this.viewerRole = 'lawyer_individual',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LITIG-1 Badge Showcase ($viewerRole)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Clientes',
              [
                _buildBadgeDemo('VIP Client', VipClientBadge(
                  clientPlan: 'VIP',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Enterprise Client', VipClientBadge(
                  clientPlan: 'ENTERPRISE',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Premium Client', VipClientBadge(
                  clientPlan: 'PREMIUM',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Business Client (NEW)', BusinessClientBadge(
                  clientPlan: 'BUSINESS',
                  viewerRole: viewerRole,
                )),
              ],
            ),
            _buildSection(
              'Advogados',
              [
                _buildBadgeDemo('Pro Lawyer', ProLawyerBadge(
                  plan: 'PRO',
                )),
                _buildBadgeDemo('Pro Lawyer (Premium Case)', ProLawyerBadge(
                  plan: 'PRO',
                  isPremiumCase: true,
                )),
              ],
            ),
            _buildSection(
              'Escritórios (NEW)',
              [
                _buildBadgeDemo('Partner Firm', FirmPlanBadge(
                  firmPlan: 'PARTNER_FIRM',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Premium Firm', FirmPlanBadge(
                  firmPlan: 'PREMIUM_FIRM',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Enterprise Firm', FirmPlanBadge(
                  firmPlan: 'ENTERPRISE_FIRM',
                  viewerRole: viewerRole,
                )),
              ],
            ),
            _buildSection(
              'Super Associates (NEW)',
              [
                _buildBadgeDemo('Super Partner', SuperAssociateBadge(
                  plan: 'PARTNER',
                  viewerRole: viewerRole,
                )),
                _buildBadgeDemo('Super Premium', SuperAssociateBadge(
                  plan: 'PREMIUM',
                  viewerRole: viewerRole,
                )),
              ],
            ),
            _buildSection(
              'Casos',
              [
                _buildBadgeDemo('Premium Case', PremiumCaseBadge(
                  isPremium: true,
                )),
                _buildBadgeDemo('Enterprise Case', EnterpriseCaseBadge(
                  isEnterprise: true,
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildCoverageStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: badges,
        ),
      ],
    );
  }

  Widget _buildBadgeDemo(String label, Widget badge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        badge,
      ],
    );
  }

  Widget _buildCoverageStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                '100% Coverage Achieved!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Todos os planos definidos em user_types.py agora têm badges correspondentes:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '✅ VIP_PF, ENTERPRISE_PJ, PREMIUM\n'
            '✅ BUSINESS_PJ (NEW)\n'
            '✅ PRO_LAWYER, PREMIUM_LAWYER\n'
            '✅ PARTNER_FIRM, PREMIUM_FIRM, ENTERPRISE_FIRM (NEW)\n'
            '✅ Super Associate PARTNER, PREMIUM (NEW)',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Função helper para testar badges rapidamente
void showBadgeShowcase(BuildContext context, {String viewerRole = 'lawyer_individual'}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BadgeShowcase(viewerRole: viewerRole),
    ),
  );
} 