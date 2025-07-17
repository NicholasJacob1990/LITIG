# 📋 **PLANO DE AÇÃO DETALHADO - SISTEMA JURÍDICO**

## 🎯 **Resumo Executivo**

Este plano de ação foi elaborado com base na análise precisa do código fonte existente e foca em **completar funcionalidades críticas** ao invés de reconstruir arquitetura. O sistema está mais funcional do que inicialmente identificado, necessitando principalmente de integrações e melhorias de UX.

**Status Atual Validado:**
- ✅ Fluxo triage → recomendações **FUNCIONA** (`/advogados?case_highlight=caseId`)
- ✅ Integração ofertas ↔ parcerias **EXISTE** no backend (`allocation_type`)
- ✅ Sistema de notificações **COMPLETO** (Firebase + Expo Push)
- ❌ **Lacuna Real**: Falta `LawyerHiringModal` (existe apenas `FirmHiringModal`)

---

## 🚨 **FASE 1: CORREÇÕES CRÍTICAS** (1-2 semanas)

### **Sprint 1.1: Implementar LawyerHiringModal** (3 dias)

#### **Problema Identificado:**
- ✅ Existe: `FirmHiringModal` para contratar escritórios
- ❌ Falta: `LawyerHiringModal` para contratar advogados individuais

#### **Implementação Frontend:**

```dart
// /lib/src/features/lawyers/presentation/widgets/lawyer_hiring_modal.dart
class LawyerHiringModal extends StatefulWidget {
  const LawyerHiringModal({
    super.key,
    required this.lawyer,
    required this.caseId,
    required this.clientId,
  });

  final Lawyer lawyer;
  final String caseId;
  final String clientId;

  @override
  State<LawyerHiringModal> createState() => _LawyerHiringModalState();
}

class _LawyerHiringModalState extends State<LawyerHiringModal> {
  String _selectedContractType = 'hourly';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LawyerHiringBloc>(),
      child: Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildLawyerInfo(),
              const SizedBox(height: 24),
              _buildContractOptions(),
              const SizedBox(height: 16),
              _buildBudgetInput(),
              const SizedBox(height: 16),
              _buildNotesInput(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.gavel, size: 32, color: Colors.blue),
        const SizedBox(width: 12),
        const Text(
          'Contratar Advogado',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildLawyerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.lawyer.avatarUrl != null
                ? NetworkImage(widget.lawyer.avatarUrl!)
                : null,
            child: widget.lawyer.avatarUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lawyer.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('OAB: ${widget.lawyer.oabNumber}'),
                Text('${widget.lawyer.expertise.join(', ')}'),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${widget.lawyer.rating.toStringAsFixed(1)}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16),
                    Text(' ${widget.lawyer.distance.toStringAsFixed(1)} km'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Contrato',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('Por Hora'),
          subtitle: const Text('Pagamento por hora trabalhada'),
          value: 'hourly',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
        RadioListTile<String>(
          title: const Text('Valor Fixo'),
          subtitle: const Text('Valor fixo para todo o caso'),
          value: 'fixed',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
        RadioListTile<String>(
          title: const Text('Êxito'),
          subtitle: const Text('Pagamento apenas em caso de sucesso'),
          value: 'success',
          groupValue: _selectedContractType,
          onChanged: (value) => setState(() => _selectedContractType = value!),
        ),
      ],
    );
  }

  Widget _buildBudgetInput() {
    return TextField(
      controller: _budgetController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: _selectedContractType == 'hourly' 
            ? 'Valor por Hora (R$)'
            : 'Orçamento Total (R$)',
        prefixText: 'R$ ',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildNotesInput() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Observações (opcional)',
        hintText: 'Informações adicionais sobre o caso...',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActions() {
    return BlocConsumer<LawyerHiringBloc, LawyerHiringState>(
      listener: (context, state) {
        if (state is LawyerHiringSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proposta enviada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is LawyerHiringError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LawyerHiringLoading;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isLoading ? null : _sendHiringProposal,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar Proposta'),
            ),
          ],
        );
      },
    );
  }

  void _sendHiringProposal() {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o valor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.replaceAll(',', '.'));
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valor inválido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<LawyerHiringBloc>().add(
      SendHiringProposal(
        lawyerId: widget.lawyer.id,
        caseId: widget.caseId,
        clientId: widget.clientId,
        contractType: _selectedContractType,
        budget: budget,
        notes: _notesController.text,
      ),
    );
  }
}
```

#### **Backend Implementation:**

```python
# /packages/backend/routes/lawyers.py
@router.post("/hire")
async def hire_lawyer(
    request: HireLawyerRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Envia proposta de contratação para advogado
    """
    try:
        # Criar proposta na tabela hiring_proposals
        proposal = await create_hiring_proposal(
            client_id=current_user.id,
            lawyer_id=request.lawyer_id,
            case_id=request.case_id,
            contract_type=request.contract_type,
            budget=request.budget,
            notes=request.notes
        )
        
        # Enviar notificação para o advogado
        await notify_service.send_notification(
            user_id=request.lawyer_id,
            notification_type="hiring_proposal",
            title="Nova Proposta de Contratação",
            message=f"Você recebeu uma proposta de contratação para o caso {request.case_id}",
            data={
                "proposal_id": proposal.id,
                "case_id": request.case_id,
                "client_name": current_user.name,
                "budget": request.budget
            }
        )
        
        return {
            "success": True,
            "proposal_id": proposal.id,
            "message": "Proposta enviada com sucesso"
        }
        
    except Exception as e:
        logger.error(f"Erro ao enviar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

class HireLawyerRequest(BaseModel):
    lawyer_id: str
    case_id: str
    contract_type: str  # 'hourly', 'fixed', 'success'
    budget: float
    notes: Optional[str] = None
```

#### **Database Schema:**

```sql
-- Tabela para propostas de contratação
CREATE TABLE hiring_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('hourly', 'fixed', 'success')),
    budget DECIMAL(10,2) NOT NULL,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    created_at TIMESTAMP DEFAULT NOW(),
    responded_at TIMESTAMP,
    response_message TEXT,
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days')
);

-- Índices para performance
CREATE INDEX idx_hiring_proposals_lawyer_id ON hiring_proposals(lawyer_id);
CREATE INDEX idx_hiring_proposals_client_id ON hiring_proposals(client_id);
CREATE INDEX idx_hiring_proposals_case_id ON hiring_proposals(case_id);
CREATE INDEX idx_hiring_proposals_status ON hiring_proposals(status);
```

#### **Integração com LawyerCard:**

```dart
// Atualizar LawyerCard para incluir botão de contratação
class LawyerCard extends StatelessWidget {
  final Lawyer lawyer;
  final String? caseId;
  final String? clientId;

  const LawyerCard({
    super.key,
    required this.lawyer,
    this.caseId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do advogado (existente)
            _buildLawyerInfo(),
            
            const SizedBox(height: 16),
            
            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showLawyerProfile(context),
                    child: const Text('Ver Perfil'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: caseId != null && clientId != null
                        ? () => _showHiringModal(context)
                        : null,
                    child: const Text('Contratar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHiringModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LawyerHiringModal(
        lawyer: lawyer,
        caseId: caseId!,
        clientId: clientId!,
      ),
    );
  }

  void _showLawyerProfile(BuildContext context) {
    // Implementar navegação para perfil do advogado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawyerProfileScreen(lawyer: lawyer),
      ),
    );
  }
}
```

#### **Acceptance Criteria Sprint 1.1:**
- [ ] LawyerHiringModal funciona igual ao FirmHiringModal
- [ ] Cliente pode enviar proposta de contratação para advogado
- [ ] Advogado recebe notificação push da proposta
- [ ] Proposta é salva no banco de dados
- [ ] Botão "Contratar" aparece em LawyerCard
- [ ] Testes unitários para todo o fluxo

---

### **Sprint 1.2: Tela de Gerenciamento de Propostas para Advogados** (4 dias)

#### **Problema:**
Advogados precisam de uma tela para gerenciar propostas de contratação recebidas.

#### **Implementação:**

```dart
// /lib/src/features/lawyers/presentation/screens/hiring_proposals_screen.dart
class HiringProposalsScreen extends StatefulWidget {
  @override
  _HiringProposalsScreenState createState() => _HiringProposalsScreenState();
}

class _HiringProposalsScreenState extends State<HiringProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HiringProposalsBloc>()
        ..add(LoadHiringProposals()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Propostas de Contratação'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pendentes'),
              Tab(text: 'Aceitas'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProposalsTab('pending'),
            _buildProposalsTab('accepted'),
            _buildProposalsTab('history'),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalsTab(String filter) {
    return BlocBuilder<HiringProposalsBloc, HiringProposalsState>(
      builder: (context, state) {
        if (state is HiringProposalsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is HiringProposalsLoaded) {
          final filteredProposals = _filterProposals(state.proposals, filter);
          
          if (filteredProposals.isEmpty) {
            return _buildEmptyState(filter);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProposals.length,
            itemBuilder: (context, index) {
              return HiringProposalCard(
                proposal: filteredProposals[index],
                onAccept: filter == 'pending' ? (proposal) {
                  context.read<HiringProposalsBloc>().add(
                    AcceptHiringProposal(proposal.id),
                  );
                } : null,
                onReject: filter == 'pending' ? (proposal) {
                  _showRejectDialog(context, proposal);
                } : null,
              );
            },
          );
        }
        
        if (state is HiringProposalsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<HiringProposalsBloc>().add(LoadHiringProposals());
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }
        
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  List<HiringProposal> _filterProposals(List<HiringProposal> proposals, String filter) {
    switch (filter) {
      case 'pending':
        return proposals.where((p) => p.status == 'pending').toList();
      case 'accepted':
        return proposals.where((p) => p.status == 'accepted').toList();
      case 'history':
        return proposals.where((p) => p.status == 'rejected' || p.status == 'expired').toList();
      default:
        return proposals;
    }
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'pending':
        message = 'Nenhuma proposta pendente';
        icon = Icons.inbox;
        break;
      case 'accepted':
        message = 'Nenhuma proposta aceita';
        icon = Icons.check_circle_outline;
        break;
      case 'history':
        message = 'Nenhuma proposta no histórico';
        icon = Icons.history;
        break;
      default:
        message = 'Nenhuma proposta encontrada';
        icon = Icons.folder_open;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, HiringProposal proposal) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Proposta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o motivo da rejeição:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motivo da rejeição...',
                border: OutlineInputBorder(),
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
              context.read<HiringProposalsBloc>().add(
                RejectHiringProposal(proposal.id, reasonController.text),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }
}
```

#### **Backend para Gerenciamento de Propostas:**

```python
# /packages/backend/routes/hiring_proposals.py
@router.get("/")
async def get_hiring_proposals(
    current_user: User = Depends(get_current_user)
):
    """
    Retorna propostas de contratação para o advogado logado
    """
    try:
        # Buscar propostas para este advogado
        result = supabase.table("hiring_proposals") \
            .select("*, clients:client_id(name, created_at), cases:case_id(title, description)") \
            .eq("lawyer_id", current_user.id) \
            .order("created_at", desc=True) \
            .execute()
        
        proposals = []
        for row in result.data:
            proposal = {
                "id": row["id"],
                "client_id": row["client_id"],
                "case_id": row["case_id"],
                "contract_type": row["contract_type"],
                "budget": row["budget"],
                "notes": row["notes"] or "",
                "status": row["status"],
                "created_at": row["created_at"],
                "responded_at": row["responded_at"],
                "expires_at": row["expires_at"],
                "client_name": row["clients"]["name"],
                "client_since": row["clients"]["created_at"],
                "case_title": row["cases"]["title"],
                "case_description": row["cases"]["description"],
            }
            proposals.append(proposal)
        
        return {
            "success": True,
            "proposals": proposals
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar propostas: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.patch("/{proposal_id}/accept")
async def accept_hiring_proposal(
    proposal_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Aceita proposta de contratação
    """
    try:
        # Verificar se a proposta existe e pertence ao advogado
        proposal_result = supabase.table("hiring_proposals") \
            .select("*") \
            .eq("id", proposal_id) \
            .eq("lawyer_id", current_user.id) \
            .eq("status", "pending") \
            .execute()
        
        if not proposal_result.data:
            raise HTTPException(
                status_code=404,
                detail="Proposta não encontrada ou já respondida"
            )
        
        proposal = proposal_result.data[0]
        
        # Atualizar status da proposta
        update_result = supabase.table("hiring_proposals") \
            .update({
                "status": "accepted",
                "responded_at": datetime.utcnow().isoformat()
            }) \
            .eq("id", proposal_id) \
            .execute()
        
        if not update_result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao atualizar proposta"
            )
        
        # Criar contrato
        contract_id = await create_contract(proposal)
        
        # Notificar cliente
        await notify_service.send_notification(
            user_id=proposal["client_id"],
            notification_type="proposal_accepted",
            title="Proposta Aceita",
            message=f"Sua proposta de contratação foi aceita por {current_user.name}",
            data={
                "proposal_id": proposal_id,
                "contract_id": contract_id,
                "lawyer_name": current_user.name
            }
        )
        
        return {
            "success": True,
            "message": "Proposta aceita com sucesso",
            "contract_id": contract_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao aceitar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.patch("/{proposal_id}/reject")
async def reject_hiring_proposal(
    proposal_id: str,
    request: RejectProposalRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Rejeita proposta de contratação
    """
    try:
        # Verificar se a proposta existe e pertence ao advogado
        proposal_result = supabase.table("hiring_proposals") \
            .select("*") \
            .eq("id", proposal_id) \
            .eq("lawyer_id", current_user.id) \
            .eq("status", "pending") \
            .execute()
        
        if not proposal_result.data:
            raise HTTPException(
                status_code=404,
                detail="Proposta não encontrada ou já respondida"
            )
        
        proposal = proposal_result.data[0]
        
        # Atualizar status da proposta
        update_result = supabase.table("hiring_proposals") \
            .update({
                "status": "rejected",
                "responded_at": datetime.utcnow().isoformat(),
                "response_message": request.reason
            }) \
            .eq("id", proposal_id) \
            .execute()
        
        if not update_result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao atualizar proposta"
            )
        
        # Notificar cliente
        await notify_service.send_notification(
            user_id=proposal["client_id"],
            notification_type="proposal_rejected",
            title="Proposta Rejeitada",
            message=f"Sua proposta de contratação foi rejeitada por {current_user.name}",
            data={
                "proposal_id": proposal_id,
                "lawyer_name": current_user.name,
                "reason": request.reason
            }
        )
        
        return {
            "success": True,
            "message": "Proposta rejeitada"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao rejeitar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

class RejectProposalRequest(BaseModel):
    reason: str

async def create_contract(proposal: dict) -> str:
    """
    Cria contrato após aceitação da proposta
    """
    contract_data = {
        "proposal_id": proposal["id"],
        "client_id": proposal["client_id"],
        "lawyer_id": proposal["lawyer_id"],
        "case_id": proposal["case_id"],
        "contract_type": proposal["contract_type"],
        "budget": proposal["budget"],
        "status": "active",
        "created_at": datetime.utcnow().isoformat()
    }
    
    result = supabase.table("contracts").insert(contract_data).execute()
    
    if result.data:
        return result.data[0]["id"]
    else:
        raise Exception("Erro ao criar contrato")
```

#### **Acceptance Criteria Sprint 1.2:**
- [ ] Advogado pode ver todas as propostas recebidas
- [ ] Propostas são organizadas por status (pendente, aceita, histórico)
- [ ] Advogado pode aceitar propostas
- [ ] Advogado pode rejeitar propostas com motivo
- [ ] Cliente recebe notificação sobre resposta
- [ ] Contrato é criado automaticamente após aceitação
- [ ] Interface responsiva e intuitiva

---

### **Sprint 1.3: Otimizar Fluxo Case Highlight** (2 dias)

#### **Problema:**
O fluxo `case_highlight` funciona mas pode ser otimizado para melhor UX.

#### **Melhorias:**

```dart
// Atualizar partners_screen.dart para melhor UX
class _HybridRecommendationsTabViewState extends State<HybridRecommendationsTabView> {
  // ... código existente ...
  
  // ✅ MELHORIAS: Adicionar animações e feedback visual
  void _checkForCaseParameters() {
    final route = ModalRoute.of(context);
    if (route != null) {
      final uri = Uri.parse(route.settings.name ?? '');
      final caseHighlight = uri.queryParameters['case_highlight'];
      final caseId = uri.queryParameters['case_id'];
      
      if (caseHighlight != null || caseId != null) {
        setState(() {
          _highlightedCaseId = caseHighlight ?? caseId;
          _isHighlightingCase = true;
          _hasPerformedSearch = true;
        });
        
        // ✅ NOVO: Animação de entrada
        _animateIntroduction();
        
        // ✅ NOVO: Buscar detalhes do caso
        _loadCaseDetails(_highlightedCaseId!);
        
        _loadMatchesForCase(_highlightedCaseId!);
      }
    }
  }
  
  // ✅ NOVO: Animação de introdução
  void _animateIntroduction() {
    // Adicionar animação suave para o banner
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Scroll para o banner se necessário
        _scrollToTopIfNeeded();
      }
    });
  }
  
  // ✅ NOVO: Buscar detalhes do caso para melhor contexto
  void _loadCaseDetails(String caseId) {
    // Integrar com CaseBloc para buscar detalhes
    context.read<CaseBloc>().add(LoadCaseDetails(caseId));
  }
  
  // ✅ MELHORADO: Banner com mais informações
  Widget _buildCaseHighlightBanner() {
    return BlocBuilder<CaseBloc, CaseState>(
      builder: (context, caseState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.target,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recomendações para seu caso',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (caseState is CaseDetailsLoaded) ...[
                          Text(
                            caseState.caseDetail.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Text(
                            'Caso #${_highlightedCaseId!.substring(0, 8)}...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearHighlight,
                    icon: Icon(
                      LucideIcons.x,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    tooltip: 'Limpar filtro',
                  ),
                ],
              ),
              
              // ✅ NOVO: Estatísticas do matching
              if (caseState is CaseDetailsLoaded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStatItem('Área', caseState.caseDetail.legalArea),
                      const SizedBox(width: 16),
                      _buildStatItem('Complexidade', caseState.caseDetail.complexity),
                      const SizedBox(width: 16),
                      _buildStatItem('Prazo', caseState.caseDetail.urgency),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  void _clearHighlight() {
    setState(() {
      _isHighlightingCase = false;
      _highlightedCaseId = null;
      _hasPerformedSearch = false;
    });
    
    // Limpar URL parameters
    context.go('/advogados');
    
    // Limpar busca
    context.read<SearchBloc>().add(SearchCleared());
  }
  
  // ✅ NOVO: Scroll para o topo se necessário
  void _scrollToTopIfNeeded() {
    if (_scrollController.hasClients && _scrollController.offset > 100) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}
```

#### **Melhorias no ChatTriageScreen:**

```dart
// Atualizar chat_triage_screen.dart para melhor transição
void _showTriageCompletedNotification(BuildContext context, String caseId) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Triagem concluída com sucesso!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Encontramos os melhores advogados para seu caso.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green[600],
      action: SnackBarAction(
        label: 'Ver Recomendações',
        textColor: Colors.white,
        onPressed: () => _navigateToRecommendations(context, caseId),
      ),
      duration: const Duration(seconds: 10),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}

void _navigateToRecommendations(BuildContext context, String caseId) {
  // ✅ MELHORADO: Navegação com loading state
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Preparando recomendações...'),
        ],
      ),
    ),
  );
  
  // Simular carregamento
  Future.delayed(const Duration(milliseconds: 1500), () {
    Navigator.of(context).pop(); // Fechar dialog
    context.go('/advogados?case_highlight=$caseId&tab=recomendacoes');
  });
}
```

#### **Acceptance Criteria Sprint 1.3:**
- [ ] Banner de case highlight com animações suaves
- [ ] Exibição de detalhes do caso no banner
- [ ] Estatísticas de matching contextuais
- [ ] Transição melhorada do triage para recomendações
- [ ] Feedback visual durante navegação
- [ ] Possibilidade de limpar filtro facilmente

---

## ⚡ **FASE 2: MELHORIAS DE EXPERIÊNCIA** (2-3 semanas)

### **Sprint 2.1: Dashboard Unificado para Advogados** (1 semana)

#### **Objetivo:**
Criar dashboard que unifique ofertas, parcerias e propostas de contratação.

#### **Implementação:**

```dart
// /lib/src/features/dashboard/presentation/screens/unified_lawyer_dashboard.dart
class UnifiedLawyerDashboard extends StatefulWidget {
  @override
  _UnifiedLawyerDashboardState createState() => _UnifiedLawyerDashboardState();
}

class _UnifiedLawyerDashboardState extends State<UnifiedLawyerDashboard> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<DashboardBloc>()..add(LoadDashboard())),
        BlocProvider(create: (context) => getIt<OffersBloc>()..add(LoadPendingOffers())),
        BlocProvider(create: (context) => getIt<HiringProposalsBloc>()..add(LoadHiringProposals())),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshDashboard,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildKPICards(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(height: 24),
                _buildOpportunities(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${authState.user.name}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getWelcomeMessage(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTodayStats(),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTodayStats() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          return Row(
            children: [
              _buildStatChip('Ofertas Hoje', state.todayOffers.toString()),
              const SizedBox(width: 12),
              _buildStatChip('Propostas', state.pendingProposals.toString()),
              const SizedBox(width: 12),
              _buildStatChip('Parcerias', state.activePartnerships.toString()),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildKPICard(
                'Taxa de Aceitação',
                '${(state.acceptanceRate * 100).toInt()}%',
                Icons.trending_up,
                state.acceptanceRate > 0.5 ? Colors.green : Colors.orange,
                state.acceptanceTrend,
              ),
              _buildKPICard(
                'Tempo de Resposta',
                state.avgResponseTime,
                Icons.timer,
                Colors.blue,
                state.responseTrend,
              ),
              _buildKPICard(
                'Casos Ativos',
                state.activeCases.toString(),
                Icons.folder_open,
                Colors.purple,
                state.casesTrend,
              ),
              _buildKPICard(
                'Receita Mensal',
                'R\$ ${state.monthlyRevenue.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
                state.revenueTrend,
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, double trend) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  trend > 0 ? Icons.trending_up : Icons.trending_down,
                  color: trend > 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              'Ofertas',
              Icons.inbox,
              Colors.blue,
              () => _navigateToOffers(),
            ),
            _buildQuickActionCard(
              'Propostas',
              Icons.file_present,
              Colors.green,
              () => _navigateToProposals(),
            ),
            _buildQuickActionCard(
              'Parcerias',
              Icons.people,
              Colors.purple,
              () => _navigateToPartnerships(),
            ),
            _buildQuickActionCard(
              'Buscar Parceiros',
              Icons.search,
              Colors.orange,
              () => _navigateToPartnerSearch(),
            ),
            _buildQuickActionCard(
              'Meus Casos',
              Icons.folder,
              Colors.teal,
              () => _navigateToCases(),
            ),
            _buildQuickActionCard(
              'Configurações',
              Icons.settings,
              Colors.grey,
              () => _navigateToSettings(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia! Pronto para um novo dia de trabalho?';
    if (hour < 18) return 'Boa tarde! Como está o seu dia?';
    return 'Boa noite! Vamos encerrar o dia com chave de ouro?';
  }

  Future<void> _refreshDashboard() async {
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<OffersBloc>().add(LoadPendingOffers());
    context.read<HiringProposalsBloc>().add(LoadHiringProposals());
  }

  // Navegação
  void _navigateToOffers() => context.go('/offers');
  void _navigateToProposals() => context.go('/hiring-proposals');
  void _navigateToPartnerships() => context.go('/partnerships');
  void _navigateToPartnerSearch() => context.go('/partners');
  void _navigateToCases() => context.go('/cases');
  void _navigateToSettings() => context.go('/profile/settings');
}
```

### **Sprint 2.2: Sistema de Busca Avançada** (1 semana)

#### **Objetivo:**
Melhorar sistema de busca com filtros avançados e AI-powered suggestions.

#### **Implementação:**

```dart
// /lib/src/features/search/presentation/widgets/advanced_search_filters.dart
class AdvancedSearchFilters extends StatefulWidget {
  final SearchParams initialParams;
  final Function(SearchParams) onFiltersChanged;

  const AdvancedSearchFilters({
    super.key,
    required this.initialParams,
    required this.onFiltersChanged,
  });

  @override
  _AdvancedSearchFiltersState createState() => _AdvancedSearchFiltersState();
}

class _AdvancedSearchFiltersState extends State<AdvancedSearchFilters> {
  late SearchParams _currentParams;
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentParams = widget.initialParams;
    _locationController.text = _currentParams.location ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSpecialtyFilter(),
          const SizedBox(height: 20),
          _buildLocationFilter(),
          const SizedBox(height: 20),
          _buildRatingFilter(),
          const SizedBox(height: 20),
          _buildPriceFilter(),
          const SizedBox(height: 20),
          _buildAvailabilityFilter(),
          const SizedBox(height: 20),
          _buildExperienceFilter(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Filtros Avançados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Limpar'),
        ),
      ],
    );
  }

  Widget _buildSpecialtyFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidade',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Direito Civil',
            'Direito Penal',
            'Direito Trabalhista',
            'Direito Empresarial',
            'Direito Tributário',
            'Direito Família',
            'Direito Imobiliário',
            'Direito Consumidor',
          ].map((specialty) => FilterChip(
            label: Text(specialty),
            selected: _currentParams.specialties.contains(specialty),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _currentParams = _currentParams.copyWith(
                    specialties: [..._currentParams.specialties, specialty],
                  );
                } else {
                  _currentParams = _currentParams.copyWith(
                    specialties: _currentParams.specialties.where((s) => s != specialty).toList(),
                  );
                }
              });
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'Ex: São Paulo, SP',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _currentParams = _currentParams.copyWith(location: value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Raio: '),
            Expanded(
              child: Slider(
                value: _currentParams.maxDistance.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_currentParams.maxDistance} km',
                onChanged: (value) {
                  setState(() {
                    _currentParams = _currentParams.copyWith(maxDistance: value.toInt());
                  });
                },
              ),
            ),
            Text('${_currentParams.maxDistance} km'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avaliação Mínima',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentParams.minRating,
                min: 1,
                max: 5,
                divisions: 8,
                label: _currentParams.minRating.toString(),
                onChanged: (value) {
                  setState(() {
                    _currentParams = _currentParams.copyWith(minRating: value);
                  });
                },
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _currentParams.minRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faixa de Preço (R\$/hora)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(_currentParams.minPrice, _currentParams.maxPrice),
          min: 50,
          max: 1000,
          divisions: 19,
          labels: RangeLabels(
            'R\$ ${_currentParams.minPrice.toInt()}',
            'R\$ ${_currentParams.maxPrice.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _currentParams = _currentParams.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('R\$ ${_currentParams.minPrice.toInt()}'),
            Text('R\$ ${_currentParams.maxPrice.toInt()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidade',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Disponível imediatamente'),
          value: _currentParams.availableNow,
          onChanged: (value) {
            setState(() {
              _currentParams = _currentParams.copyWith(availableNow: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Aceita consultas online'),
          value: _currentParams.onlineConsultation,
          onChanged: (value) {
            setState(() {
              _currentParams = _currentParams.copyWith(onlineConsultation: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildExperienceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Experiência Mínima',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentParams.minExperience.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                label: '${_currentParams.minExperience} anos',
                onChanged: (value) {
                  setState(() {
                    _currentParams = _currentParams.copyWith(minExperience: value.toInt());
                  });
                },
              ),
            ),
            Text('${_currentParams.minExperience} anos'),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Limpar Filtros'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onFiltersChanged(_currentParams);
            },
            child: const Text('Aplicar Filtros'),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _currentParams = SearchParams.empty();
      _locationController.clear();
    });
    widget.onFiltersChanged(_currentParams);
  }
}
```

### **Sprint 2.3: Notificações Inteligentes** (1 semana)

#### **Objetivo:**
Implementar sistema de notificações inteligentes com preferências personalizáveis.

#### **Implementação:**

```dart
// /lib/src/features/notifications/presentation/screens/notification_settings_screen.dart
class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NotificationSettingsBloc>()..add(LoadNotificationSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações de Notificação'),
        ),
        body: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
          builder: (context, state) {
            if (state is NotificationSettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is NotificationSettingsLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(
                    'Ofertas de Casos',
                    'Receba notificações quando novos casos forem oferecidos',
                    [
                      _buildNotificationToggle(
                        'Novas ofertas',
                        'Notificar quando receber novas ofertas de casos',
                        state.settings.newOffers,
                        (value) => _updateSetting('newOffers', value),
                      ),
                      _buildNotificationToggle(
                        'Ofertas urgentes',
                        'Notificar apenas ofertas marcadas como urgentes',
                        state.settings.urgentOffers,
                        (value) => _updateSetting('urgentOffers', value),
                      ),
                      _buildNotificationToggle(
                        'Ofertas da minha especialidade',
                        'Filtrar ofertas por especialidade',
                        state.settings.specialtyOffers,
                        (value) => _updateSetting('specialtyOffers', value),
                      ),
                    ],
                  ),
                  _buildSection(
                    'Propostas de Contratação',
                    'Notificações sobre propostas de clientes',
                    [
                      _buildNotificationToggle(
                        'Novas propostas',
                        'Notificar quando receber propostas de contratação',
                        state.settings.newProposals,
                        (value) => _updateSetting('newProposals', value),
                      ),
                      _buildNotificationToggle(
                        'Propostas expiradas',
                        'Lembrar quando propostas estão prestes a expirar',
                        state.settings.proposalExpiry,
                        (value) => _updateSetting('proposalExpiry', value),
                      ),
                    ],
                  ),
                  _buildSection(
                    'Parcerias',
                    'Notificações sobre parcerias profissionais',
                    [
                      _buildNotificationToggle(
                        'Novas parcerias',
                        'Notificar quando receber convites de parceria',
                        state.settings.newPartnerships,
                        (value) => _updateSetting('newPartnerships', value),
                      ),
                      _buildNotificationToggle(
                        'Sugestões de parceiros',
                        'Receber sugestões de parceiros compatíveis',
                        state.settings.partnerSuggestions,
                        (value) => _updateSetting('partnerSuggestions', value),
                      ),
                    ],
                  ),
                  _buildSection(
                    'Casos e Atualizações',
                    'Notificações sobre andamento de casos',
                    [
                      _buildNotificationToggle(
                        'Atualizações de casos',
                        'Notificar sobre atualizações nos casos',
                        state.settings.caseUpdates,
                        (value) => _updateSetting('caseUpdates', value),
                      ),
                      _buildNotificationToggle(
                        'Mensagens',
                        'Notificar quando receber mensagens',
                        state.settings.messages,
                        (value) => _updateSetting('messages', value),
                      ),
                    ],
                  ),
                  _buildSection(
                    'Configurações Gerais',
                    'Configurações gerais de notificação',
                    [
                      _buildNotificationToggle(
                        'Notificações push',
                        'Receber notificações push no dispositivo',
                        state.settings.pushNotifications,
                        (value) => _updateSetting('pushNotifications', value),
                      ),
                      _buildNotificationToggle(
                        'Notificações por email',
                        'Receber notificações por email',
                        state.settings.emailNotifications,
                        (value) => _updateSetting('emailNotifications', value),
                      ),
                      _buildNotificationToggle(
                        'Modo silencioso',
                        'Ativar entre 22h e 7h',
                        state.settings.quietHours,
                        (value) => _updateSetting('quietHours', value),
                      ),
                    ],
                  ),
                ],
              );
            }
            
            return const Center(child: Text('Erro ao carregar configurações'));
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _updateSetting(String key, bool value) {
    context.read<NotificationSettingsBloc>().add(
      UpdateNotificationSetting(key, value),
    );
  }
}
```

---

## 🚀 **FASE 3: FUNCIONALIDADES AVANÇADAS** (3-4 semanas)

### **Sprint 3.1: Sistema de Avaliações e Feedback** (2 semanas)

#### **Objetivo:**
Implementar sistema completo de avaliações para casos finalizados.

#### **Implementação:**

```dart
// /lib/src/features/ratings/presentation/screens/case_rating_screen.dart
class CaseRatingScreen extends StatefulWidget {
  final String caseId;
  final String lawyerId;
  final String clientId;
  final String userType; // 'client' ou 'lawyer'

  const CaseRatingScreen({
    super.key,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.userType,
  });

  @override
  _CaseRatingScreenState createState() => _CaseRatingScreenState();
}

class _CaseRatingScreenState extends State<CaseRatingScreen> {
  double _overallRating = 0;
  double _communicationRating = 0;
  double _expertiseRating = 0;
  double _responsivenessRating = 0;
  double _valueRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RatingBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          centerTitle: true,
        ),
        body: BlocConsumer<RatingBloc, RatingState>(
          listener: (context, state) {
            if (state is RatingSubmitted) {
              _showSuccessDialog();
            } else if (state is RatingError) {
              _showErrorDialog(state.message);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildOverallRating(),
                  const SizedBox(height: 32),
                  _buildDetailedRatings(),
                  const SizedBox(height: 32),
                  _buildTagsSection(),
                  const SizedBox(height: 32),
                  _buildCommentSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            _getHeaderTitle(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getHeaderSubtitle(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliação Geral',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _overallRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _overallRating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(_overallRating),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getRatingColor(_overallRating),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliação Detalhada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Comunicação',
              'Clareza e frequência da comunicação',
              _communicationRating,
              (rating) => setState(() => _communicationRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Expertise',
              'Conhecimento técnico e experiência',
              _expertiseRating,
              (rating) => setState(() => _expertiseRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Responsividade',
              'Tempo de resposta e disponibilidade',
              _responsivenessRating,
              (rating) => setState(() => _responsivenessRating = rating),
            ),
            const SizedBox(height: 16),
            _buildRatingRow(
              'Custo-Benefício',
              'Valor do serviço em relação ao preço',
              _valueRating,
              (rating) => setState(() => _valueRating = rating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String title, String description, double rating, Function(double) onRatingUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 24,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: onRatingUpdate,
            ),
            const SizedBox(width: 12),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '0.0',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final availableTags = _getAvailableTags();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pontos Destacados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione os aspectos que mais se destacaram:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comentário (Opcional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compartilhe sua experiência detalhada:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Descreva sua experiência, pontos positivos e sugestões de melhoria...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  '${_commentController.text.length}/500',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(RatingState state) {
    final isLoading = state is RatingSubmitting;
    final canSubmit = _overallRating > 0 && _canSubmitRating();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit && !isLoading ? _submitRating : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Enviar Avaliação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getTitle() {
    return widget.userType == 'client' ? 'Avaliar Advogado' : 'Avaliar Cliente';
  }

  String _getHeaderTitle() {
    return widget.userType == 'client' 
        ? 'Como foi sua experiência?' 
        : 'Como foi trabalhar com este cliente?';
  }

  String _getHeaderSubtitle() {
    return widget.userType == 'client'
        ? 'Sua avaliação ajuda outros clientes a encontrar bons advogados'
        : 'Sua avaliação ajuda outros advogados a conhecer este cliente';
  }

  List<String> _getAvailableTags() {
    if (widget.userType == 'client') {
      return [
        'Muito profissional',
        'Excelente comunicação',
        'Resposta rápida',
        'Conhecimento técnico',
        'Prestativo',
        'Pontual',
        'Estratégico',
        'Transparente',
        'Dedicado',
        'Resultado excelente',
      ];
    } else {
      return [
        'Cliente organizado',
        'Comunicação clara',
        'Pagamento pontual',
        'Colaborativo',
        'Respeitoso',
        'Documentos em ordem',
        'Expectativas realistas',
        'Comprometido',
        'Flexível',
        'Recomendaria',
      ];
    }
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excelente';
    if (rating >= 3.5) return 'Muito Bom';
    if (rating >= 2.5) return 'Bom';
    if (rating >= 1.5) return 'Regular';
    if (rating >= 1) return 'Ruim';
    return 'Selecione uma avaliação';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    if (rating >= 2) return Colors.red;
    return Colors.grey;
  }

  bool _canSubmitRating() {
    return _overallRating > 0 && 
           _communicationRating > 0 && 
           _expertiseRating > 0 && 
           _responsivenessRating > 0 && 
           _valueRating > 0;
  }

  void _submitRating() {
    final rating = CaseRating(
      caseId: widget.caseId,
      lawyerId: widget.lawyerId,
      clientId: widget.clientId,
      raterType: widget.userType,
      overallRating: _overallRating,
      communicationRating: _communicationRating,
      expertiseRating: _expertiseRating,
      responsivenessRating: _responsivenessRating,
      valueRating: _valueRating,
      comment: _commentController.text,
      tags: _selectedTags,
    );

    context.read<RatingBloc>().add(SubmitRating(rating));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Avaliação Enviada!'),
          ],
        ),
        content: const Text('Obrigado pelo seu feedback. Sua avaliação foi registrada com sucesso.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

#### **Backend para Sistema de Avaliações:**

```python
# /packages/backend/routes/ratings.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import logging

router = APIRouter(prefix="/ratings", tags=["ratings"])
logger = logging.getLogger(__name__)

class RatingRequest(BaseModel):
    case_id: str
    lawyer_id: str
    client_id: str
    rater_type: str  # 'client' ou 'lawyer'
    overall_rating: float
    communication_rating: float
    expertise_rating: float
    responsiveness_rating: float
    value_rating: float
    comment: Optional[str] = None
    tags: List[str] = []

@router.post("/", response_model=dict)
async def create_rating(
    rating_request: RatingRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Cria uma nova avaliação para um caso finalizado
    """
    try:
        # Verificar se o usuário tem permissão para avaliar este caso
        if not await can_rate_case(current_user.id, rating_request.case_id, rating_request.rater_type):
            raise HTTPException(
                status_code=403,
                detail="Você não tem permissão para avaliar este caso"
            )
        
        # Verificar se já existe avaliação
        existing_rating = await get_existing_rating(
            rating_request.case_id,
            current_user.id,
            rating_request.rater_type
        )
        
        if existing_rating:
            raise HTTPException(
                status_code=400,
                detail="Você já avaliou este caso"
            )
        
        # Criar avaliação
        rating_data = {
            "case_id": rating_request.case_id,
            "lawyer_id": rating_request.lawyer_id,
            "client_id": rating_request.client_id,
            "rater_id": current_user.id,
            "rater_type": rating_request.rater_type,
            "overall_rating": rating_request.overall_rating,
            "communication_rating": rating_request.communication_rating,
            "expertise_rating": rating_request.expertise_rating,
            "responsiveness_rating": rating_request.responsiveness_rating,
            "value_rating": rating_request.value_rating,
            "comment": rating_request.comment,
            "tags": rating_request.tags,
            "created_at": datetime.utcnow().isoformat(),
            "is_verified": True  # Pode ser verificado posteriormente
        }
        
        result = supabase.table("ratings").insert(rating_data).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao criar avaliação"
            )
        
        rating_id = result.data[0]["id"]
        
        # Atualizar estatísticas do advogado
        await update_lawyer_statistics(rating_request.lawyer_id)
        
        # Enviar notificação para o avaliado
        await send_rating_notification(rating_request, current_user)
        
        return {
            "success": True,
            "rating_id": rating_id,
            "message": "Avaliação criada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar avaliação: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

@router.get("/lawyer/{lawyer_id}")
async def get_lawyer_ratings(
    lawyer_id: str,
    page: int = 1,
    limit: int = 10
):
    """
    Retorna avaliações de um advogado específico
    """
    try:
        offset = (page - 1) * limit
        
        # Buscar avaliações
        result = supabase.table("ratings") \
            .select("*, cases(title), clients:client_id(name)") \
            .eq("lawyer_id", lawyer_id) \
            .eq("rater_type", "client") \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()
        
        ratings = []
        for row in result.data:
            rating = {
                "id": row["id"],
                "case_id": row["case_id"],
                "case_title": row["cases"]["title"],
                "client_name": row["clients"]["name"],
                "overall_rating": row["overall_rating"],
                "communication_rating": row["communication_rating"],
                "expertise_rating": row["expertise_rating"],
                "responsiveness_rating": row["responsiveness_rating"],
                "value_rating": row["value_rating"],
                "comment": row["comment"],
                "tags": row["tags"],
                "created_at": row["created_at"],
                "is_verified": row["is_verified"]
            }
            ratings.append(rating)
        
        # Buscar estatísticas
        stats = await get_lawyer_rating_stats(lawyer_id)
        
        return {
            "success": True,
            "ratings": ratings,
            "statistics": stats,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": len(result.data)
            }
        }
        
    except Exception as e:
        logger.error(f"Erro ao buscar avaliações: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno do servidor"
        )

async def can_rate_case(user_id: str, case_id: str, rater_type: str) -> bool:
    """
    Verifica se o usuário pode avaliar este caso
    """
    try:
        # Verificar se o caso existe e está finalizado
        case_result = supabase.table("cases") \
            .select("*") \
            .eq("id", case_id) \
            .eq("status", "completed") \
            .execute()
        
        if not case_result.data:
            return False
        
        case = case_result.data[0]
        
        # Verificar se o usuário está relacionado ao caso
        if rater_type == "client":
            return case["client_id"] == user_id
        elif rater_type == "lawyer":
            return case["lawyer_id"] == user_id
        
        return False
        
    except Exception as e:
        logger.error(f"Erro ao verificar permissão: {e}")
        return False

async def update_lawyer_statistics(lawyer_id: str):
    """
    Atualiza estatísticas do advogado após nova avaliação
    """
    try:
        # Calcular novas estatísticas
        stats = await calculate_lawyer_stats(lawyer_id)
        
        # Atualizar tabela de advogados
        supabase.table("lawyers") \
            .update({
                "overall_rating": stats["overall_rating"],
                "total_ratings": stats["total_ratings"],
                "rating_breakdown": stats["rating_breakdown"]
            }) \
            .eq("id", lawyer_id) \
            .execute()
        
    except Exception as e:
        logger.error(f"Erro ao atualizar estatísticas: {e}")

async def calculate_lawyer_stats(lawyer_id: str) -> dict:
    """
    Calcula estatísticas de avaliação do advogado
    """
    try:
        result = supabase.table("ratings") \
            .select("*") \
            .eq("lawyer_id", lawyer_id) \
            .eq("rater_type", "client") \
            .execute()
        
        if not result.data:
            return {
                "overall_rating": 0,
                "total_ratings": 0,
                "rating_breakdown": {}
            }
        
        ratings = result.data
        total_ratings = len(ratings)
        
        # Calcular médias
        avg_overall = sum(r["overall_rating"] for r in ratings) / total_ratings
        avg_communication = sum(r["communication_rating"] for r in ratings) / total_ratings
        avg_expertise = sum(r["expertise_rating"] for r in ratings) / total_ratings
        avg_responsiveness = sum(r["responsiveness_rating"] for r in ratings) / total_ratings
        avg_value = sum(r["value_rating"] for r in ratings) / total_ratings
        
        # Distribuição de estrelas
        star_distribution = {str(i): 0 for i in range(1, 6)}
        for rating in ratings:
            star = str(int(rating["overall_rating"]))
            star_distribution[star] += 1
        
        return {
            "overall_rating": round(avg_overall, 2),
            "total_ratings": total_ratings,
            "rating_breakdown": {
                "communication": round(avg_communication, 2),
                "expertise": round(avg_expertise, 2),
                "responsiveness": round(avg_responsiveness, 2),
                "value": round(avg_value, 2),
                "star_distribution": star_distribution
            }
        }
        
    except Exception as e:
        logger.error(f"Erro ao calcular estatísticas: {e}")
        return {
            "overall_rating": 0,
            "total_ratings": 0,
            "rating_breakdown": {}
        }
```

#### **Database Schema para Avaliações:**

```sql
-- Tabela principal de avaliações
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rater_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rater_type VARCHAR(10) NOT NULL CHECK (rater_type IN ('client', 'lawyer')),
    overall_rating DECIMAL(2,1) NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
    communication_rating DECIMAL(2,1) NOT NULL CHECK (communication_rating >= 1 AND communication_rating <= 5),
    expertise_rating DECIMAL(2,1) NOT NULL CHECK (expertise_rating >= 1 AND expertise_rating <= 5),
    responsiveness_rating DECIMAL(2,1) NOT NULL CHECK (responsiveness_rating >= 1 AND responsiveness_rating <= 5),
    value_rating DECIMAL(2,1) NOT NULL CHECK (value_rating >= 1 AND value_rating <= 5),
    comment TEXT,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    helpful_votes INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela para estatísticas agregadas dos advogados
CREATE TABLE lawyer_rating_stats (
    lawyer_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    overall_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    communication_avg DECIMAL(3,2) DEFAULT 0,
    expertise_avg DECIMAL(3,2) DEFAULT 0,
    responsiveness_avg DECIMAL(3,2) DEFAULT 0,
    value_avg DECIMAL(3,2) DEFAULT 0,
    star_distribution JSONB DEFAULT '{}',
    last_updated TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_ratings_lawyer_id ON ratings(lawyer_id);
CREATE INDEX idx_ratings_client_id ON ratings(client_id);
CREATE INDEX idx_ratings_case_id ON ratings(case_id);
CREATE INDEX idx_ratings_rater_type ON ratings(rater_type);
CREATE INDEX idx_ratings_overall_rating ON ratings(overall_rating);
CREATE INDEX idx_ratings_created_at ON ratings(created_at);
```

### **Sprint 3.2: Analytics e Relatórios** (1 semana)

#### **Objetivo:**
Implementar dashboard de analytics detalhado para advogados.

#### **Implementação:**

```dart
// /lib/src/features/analytics/presentation/screens/analytics_screen.dart
class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AnalyticsBloc>()
        ..add(LoadAnalytics(period: _selectedPeriod)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          actions: [
            _buildPeriodSelector(),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportReport,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Visão Geral'),
              Tab(text: 'Ofertas'),
              Tab(text: 'Casos'),
              Tab(text: 'Financeiro'),
            ],
          ),
        ),
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is AnalyticsLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(state.overview),
                  _buildOffersTab(state.offers),
                  _buildCasesTab(state.cases),
                  _buildFinancialTab(state.financial),
                ],
              );
            }
            
            return const Center(child: Text('Erro ao carregar dados'));
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedPeriod,
      onSelected: (value) {
        setState(() {
          _selectedPeriod = value;
        });
        context.read<AnalyticsBloc>().add(LoadAnalytics(period: value));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: '7d', child: Text('7 dias')),
        const PopupMenuItem(value: '30d', child: Text('30 dias')),
        const PopupMenuItem(value: '90d', child: Text('90 dias')),
        const PopupMenuItem(value: '1y', child: Text('1 ano')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getPeriodText(_selectedPeriod)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  String _getPeriodText(String period) {
    switch (period) {
      case '7d':
        return 'Últimos 7 dias';
      case '30d':
        return 'Últimos 30 dias';
      case '90d':
        return 'Últimos 90 dias';
      case '1y':
        return 'Último ano';
      default:
        return 'Período';
    }
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Relatório'),
        content: const Text('Escolha o formato do relatório:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToExcel();
            },
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    context.read<AnalyticsBloc>().add(ExportReport(format: 'pdf'));
  }

  void _exportToExcel() {
    context.read<AnalyticsBloc>().add(ExportReport(format: 'excel'));
  }
}
```

### **Sprint 3.3: Integrações Externas** (1 semana)

#### **Objetivo:**
Implementar integrações com APIs externas (OAB, Tribunais, etc.).

#### **Implementação:**

```python
# /packages/backend/services/external_integrations/oab_service.py
import aiohttp
import asyncio
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

class OABIntegrationService:
    """
    Serviço para integração com APIs da OAB
    """
    
    def __init__(self):
        self.base_url = "https://api.oab.org.br/v1"
        self.timeout = 30
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=self.timeout)
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    async def verify_lawyer_registration(
        self, 
        oab_number: str, 
        state: str
    ) -> Dict[str, Any]:
        """
        Verifica se o advogado está registrado na OAB
        """
        try:
            if not self.session:
                raise Exception("Sessão não inicializada")
            
            url = f"{self.base_url}/lawyers/verify"
            params = {
                "oab_number": oab_number,
                "state": state
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "valid": True,
                        "lawyer_data": {
                            "name": data.get("name"),
                            "oab_number": data.get("oab_number"),
                            "state": data.get("state"),
                            "status": data.get("status"),
                            "registration_date": data.get("registration_date"),
                            "specializations": data.get("specializations", []),
                            "disciplinary_record": data.get("disciplinary_record", {})
                        }
                    }
                elif response.status == 404:
                    return {
                        "valid": False,
                        "message": "Advogado não encontrado na OAB"
                    }
                else:
                    return {
                        "valid": False,
                        "message": "Erro ao verificar registro na OAB"
                    }
                    
        except asyncio.TimeoutError:
            logger.error(f"Timeout na verificação OAB: {oab_number}")
            return {
                "valid": False,
                "message": "Timeout na verificação"
            }
        except Exception as e:
            logger.error(f"Erro na verificação OAB: {e}")
            return {
                "valid": False,
                "message": "Erro interno na verificação"
            }
```

---

## 📊 **CRONOGRAMA E MÉTRICAS**

### **Cronograma Detalhado:**

| **Fase** | **Sprint** | **Duração** | **Entregáveis** |
|----------|------------|-------------|-----------------|
| **Fase 1** | 1.1 | 3 dias | LawyerHiringModal completo |
| | 1.2 | 4 dias | Tela de propostas para advogados |
| | 1.3 | 2 dias | Otimização case highlight |
| **Fase 2** | 2.1 | 5 dias | Dashboard unificado |
| | 2.2 | 5 dias | Sistema de busca avançada |
| | 2.3 | 5 dias | Notificações inteligentes |
| **Fase 3** | 3.1 | 10 dias | Sistema de avaliações |
| | 3.2 | 5 dias | Analytics e relatórios |
| | 3.3 | 5 dias | Integrações externas |

### **Recursos Necessários:**

| **Perfil** | **Fase 1** | **Fase 2** | **Fase 3** |
|------------|------------|------------|------------|
| **Backend Dev** | 2 | 2 | 3 |
| **Frontend Dev** | 2 | 3 | 2 |
| **DevOps** | 1 | 1 | 1 |
| **QA** | 1 | 1 | 2 |
| **ML Engineer** | 0 | 0 | 1 |

### **Métricas de Sucesso:**

#### **Fase 1 - Métricas Críticas:**
- Taxa de conversão triage → contratação: **> 20%**
- Tempo médio de resposta a propostas: **< 4 horas**
- Satisfação com fluxo de contratação: **> 4.5/5**
- Bugs críticos: **0**
- Uptime do sistema: **> 99.5%**

#### **Fase 2 - Métricas de Experiência:**
- Engagement com dashboard: **> 80%**
- Uso de filtros avançados: **> 60%**
- Taxa de abertura de notificações: **> 70%**
- Tempo médio de busca: **< 30 segundos**
- Satisfação com UX: **> 4.3/5**

#### **Fase 3 - Métricas Avançadas:**
- Casos com avaliação: **> 95%**
- Advogados usando analytics: **> 85%**
- Integrações funcionando: **99.9% uptime**
- Precisão da verificação OAB: **> 98%**
- Satisfação com relatórios: **> 4.4/5**

### **Orçamento Estimado:**

#### **Custo de Desenvolvimento:**
- **Fase 1**: R$ 120.000 (40 person-days × R$ 3.000/day)
- **Fase 2**: R$ 360.000 (120 person-days × R$ 3.000/day)
- **Fase 3**: R$ 600.000 (200 person-days × R$ 3.000/day)
- **Total**: R$ 1.080.000

#### **Custos de Infraestrutura:**
- **Servidores**: R$ 5.000/mês
- **Banco de dados**: R$ 2.000/mês
- **APIs externas**: R$ 3.000/mês
- **Monitoramento**: R$ 1.000/mês
- **Total mensal**: R$ 11.000

---

## 🚨 **RISCOS E MITIGAÇÕES**

### **Riscos Técnicos:**
- **Integração complexa**: Implementar em etapas menores
- **Performance issues**: Load testing contínuo
- **Data migration**: Backup e rollback strategy

### **Riscos de Negócio:**
- **Adoção lenta**: Programa de onboarding
- **Resistência a mudanças**: Treinamento e suporte
- **Concorrência**: Foco em diferenciais únicos

### **Riscos de Cronograma:**
- **Dependências externas**: Alternativas pré-definidas
- **Complexidade subestimada**: Buffer de 20% no cronograma
- **Recursos indisponíveis**: Plano de contingência

---

## 🎯 **PRÓXIMOS PASSOS IMEDIATOS**

### **Semana 1:**
1. **Segunda**: Aprovação do plano e alocação de recursos
2. **Terça**: Setup do ambiente de desenvolvimento
3. **Quarta**: Início do Sprint 1.1 - LawyerHiringModal
4. **Quinta**: Desenvolvimento do modal e backend
5. **Sexta**: Testes e ajustes

### **Semana 2:**
1. **Segunda**: Finalização do LawyerHiringModal
2. **Terça**: Início do Sprint 1.2 - Tela de propostas
3. **Quarta-Quinta**: Desenvolvimento da tela
4. **Sexta**: Testes e Sprint Review

### **Validação Contínua:**
- **Daily standup** às 9h
- **Sprint review** toda sexta
- **Demo** para stakeholders quinzenalmente
- **Retrospectiva** ao final de cada sprint
- **Métricas** atualizadas diariamente

---

## 📋 **CONCLUSÃO**

Este plano de ação foi baseado na análise correta do código fonte e foca em:

1. **Completar funcionalidades críticas** que estão realmente faltando
2. **Otimizar fluxos** que já funcionam
3. **Integrar sistemas** backend existentes
4. **Melhorar experiência** do usuário progressivamente
5. **Implementar funcionalidades avançadas** para diferenciação

O sistema está **mais funcional** do que inicialmente avaliado, necessitando principalmente de **integrações pontuais** e **melhorias de UX** ao invés de reconstrução completa.

**Principais lacunas identificadas:**
- ❌ Falta `LawyerHiringModal` (lacuna real)
- ❌ Tela de gestão de propostas para advogados
- ❌ Otimizações de UX nos fluxos existentes

**Funcionalidades que já funcionam:**
- ✅ Fluxo triage → recomendações
- ✅ Sistema de ofertas completo
- ✅ Sistema de parcerias funcional
- ✅ Integração ofertas ↔ parcerias no backend
- ✅ Sistema de notificações completo

O plano é **executável**, **mensurável** e **baseado em evidências concretas**, garantindo que os esforços sejam direcionados onde realmente agregam valor.