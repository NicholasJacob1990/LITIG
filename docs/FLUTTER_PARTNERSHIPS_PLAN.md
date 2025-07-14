
# Plano de Implementação Flutter para Funcionalidade de Parcerias Jurídicas

Este documento descreve o plano completo de ação para desenvolver a interface do usuário em Flutter para o sistema de registro e parcerias jurídicas, incluindo navegação dinâmica, painel administrativo e dashboard de indicadores.

---

Após revisar o repositório [LITIG](https://github.com/NicholasJacob1990/LITIG), foram identificados os pontos que precisarão ser **alterados ou adicionados** para implementar o sistema completo de **parcerias jurídicas entre advogados**, com uso do **algoritmo de triagem e match já existente no app**.

Abaixo está a análise, dividida entre **backend (FastAPI)** e **frontend (Flutter)**, seguida pelo plano de implementação do backend.

---

# ✅ ALTERAÇÕES NECESSÁRIAS – REPOSITÓRIO LITIG

## 🧠 BACKEND (FastAPI / Supabase)

### 📁 Diretório de foco: `/backend/api/`

---

### 1. 🔧 MODELOS NOVOS E AJUSTADOS

#### 🆕 Modelo: `Partnership`

Criar um novo modelo `Partnership` em `/models/partnership.py`

Campos:

```python
class Partnership(Base):
    id: UUID
    creator_id: UUID  # quem propôs
    partner_id: UUID  # quem foi convidado
    case_id: Optional[UUID]
    type: str  # ENUM
    status: str  # ENUM
    honorarios: Optional[str]
    proposal_message: Optional[str]
    contract_url: Optional[str]
    contract_accepted_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
```

---

### 2. 🔧 ROTAS E CONTROLADORES

Criar novo módulo em `/routes/partnerships.py` com rotas:

* `POST /partnerships`: Criar proposta
* `PATCH /partnerships/{id}/accept`: Aceitar proposta
* `PATCH /partnerships/{id}/reject`: Recusar proposta
* `POST /partnerships/{id}/generate-contract`: Gerar contrato
* `PATCH /partnerships/{id}/accept-contract`: Aceitar contrato
* `GET /partnerships`: Listar parcerias do usuário logado

Incluir no arquivo principal de rotas (`/main.py`):

```python
app.include_router(partnerships_router, prefix="/partnerships")
```

---

### 3. 🧠 USAR TRIAGEM EXISTENTE

Reutilizar módulo de **IA de match** localizado em:

`/services/matching/` ou `/services/triage/`

Modificar a lógica para permitir busca de parceiros entre `lawyer_individual` e `lawyer_office`, **com base no mesmo embedding vetorial ou lógica semântica**.

---

### 4. 📄 TEMPLATE DE CONTRATO DINÂMICO

Criar pasta `/contracts/templates/contract_partnership.md`

Gerar HTML ou Markdown via Jinja2 ou Markdown renderizado com campos dinâmicos:

* `{{creator_name}}`, `{{partner_name}}`, `{{honorarios}}`, `{{tipo}}`, etc.

Salvar em storage (Supabase ou Firebase) e gravar URL em `contract_url`.

---

## 📱 FRONTEND (Flutter - `litig_app/lib/`)

### 🔍 1. NOVAS TELAS

Criar novas telas:

* `lawyer_search_screen.dart`: busca de parceiros
* `propose_partnership_screen.dart`: formulário da proposta
* `offers_screen.dart`: ofertas recebidas
* `partnerships_screen.dart`: parcerias em andamento
* `contract_screen.dart`: contrato gerado e botão "Aceitar e Assinar"

---

### 🧭 2. ABAS POR PERFIL (BottomNavigation)

Modificar navegação conforme perfil:

#### `lawyer_office` ou `lawyer_individual`:

```dart
BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Parceiros')
BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'Parcerias')
```

#### `lawyer_associated`:

```dart
BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Ofertas')
```

---

### 🔗 3. CHAMADAS À API

Atualizar serviços REST:

* `partnership_service.dart`

  * `createProposal()`
  * `acceptProposal()`
  * `generateContract()`
  * `acceptContract()`
  * `fetchPartnerships()`

---

# ✅ PARTE 1 – IMPLEMENTAÇÃO BACKEND (FastAPI)

Esta seção detalha a implementação prática do que foi mapeado. Começaremos pelo **backend (FastAPI)** com foco nos **modelos, rotas e lógica de contrato dinâmico**.

---

## 📦 1. Modelo `Partnership` (SQLAlchemy)

Crie o arquivo `models/partnership.py`:

```python
from sqlalchemy import Column, String, DateTime, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
import uuid
from .base import Base

class PartnershipStatus(enum.Enum):
    PENDENTE = "pendente"
    ACEITA = "aceita"
    REJEITADA = "rejeitada"
    CONTRATO_PENDENTE = "contrato_pendente"
    ATIVA = "ativa"
    FINALIZADA = "finalizada"

class Partnership(Base):
    __tablename__ = "partnerships"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    creator_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    partner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    case_id = Column(UUID(as_uuid=True), nullable=True)
    type = Column(String, nullable=False)
    status = Column(Enum(PartnershipStatus), default=PartnershipStatus.PENDENTE)
    honorarios = Column(String, nullable=True)
    proposal_message = Column(String, nullable=True)
    contract_url = Column(String, nullable=True)
    contract_accepted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    creator = relationship("User", foreign_keys=[creator_id])
    partner = relationship("User", foreign_keys=[partner_id])
```

---

## 🌐 2. Rotas (em `routes/partnerships.py`)

```python
from fastapi import APIRouter, Depends, HTTPException
from models import Partnership, PartnershipStatus
from schemas import PartnershipCreate, PartnershipOut
from database import get_db
from sqlalchemy.orm import Session

router = APIRouter()

@router.post("/", response_model=PartnershipOut)
def create_partnership(data: PartnershipCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    partnership = Partnership(
        creator_id=current_user.id,
        partner_id=data.partner_id,
        case_id=data.case_id,
        type=data.type,
        honorarios=data.honorarios,
        proposal_message=data.proposal_message,
    )
    db.add(partnership)
    db.commit()
    db.refresh(partnership)
    return partnership
```

*Rotas adicionais para `accept`, `reject`, `generate_contract`, `accept_contract` devem seguir um padrão similar.*

---

## 📄 3. Template de Contrato (`contracts/contract_partnership.md`)

```markdown
# CONTRATO DE PARCERIA JURÍDICA

**CONTRATANTE**: {{creator_name}}, OAB {{creator_oab}}

**CONTRATADO**: {{partner_name}}, OAB {{partner_oab}}

**Objeto**: Prestação de serviço jurídico do tipo "{{type}}" com referência ao caso {{case_reference}}

**Honorários**: {{honorarios}}

**Vigência**: A contar do aceite digital até encerramento formal

**Confidencialidade**: Ambas as partes assumem o dever de sigilo profissional.

**Aceite**: O presente contrato é aceito digitalmente em {{contract_accepted_at}}
```

---

## 🧠 4. Geração do contrato renderizado (exemplo com Jinja2)

```python
from jinja2 import Environment, FileSystemLoader
from datetime import datetime

def render_contract(data: dict):
    env = Environment(loader=FileSystemLoader('contracts'))
    template = env.get_template('contract_partnership.md')
    output = template.render(**data)
    return output
```

---

## 📁 5. Schema Pydantic (`schemas/partnership.py`)

```python
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class PartnershipCreate(BaseModel):
    partner_id: UUID
    case_id: Optional[UUID]
    type: str
    honorarios: Optional[str]
    proposal_message: Optional[str]

class PartnershipOut(BaseModel):
    id: UUID
    creator_id: UUID
    partner_id: UUID
    type: str
    status: str
    contract_url: Optional[str]
    contract_accepted_at: Optional[datetime]

    class Config:
        orm_mode = True
```

---

✅ **Resultado da Parte 1:**

* Modelo de dados completo para parcerias.
* API REST para criação de propostas.
* Template de contrato dinâmico configurado e renderizável.
* Estrutura preparada para integração com storage externo e frontend.

---

## 1. Estrutura de Pastas (Features-first) - EXPANDIDA

A estrutura seguirá o padrão `features-first` para garantir escalabilidade e organização.

```
lib/
├── src/
│   ├── core/                  # Lógica de negócio, core do app
│   │   ├── api/               # Serviços de API (client, interceptors)
│   │   ├── auth/              # Serviço de autenticação
│   │   └── models/            # Modelos de dados (User, Partnership, etc.)
│   │
│   ├── features/              # Funcionalidades do app
│   │   ├── auth/              # Telas de Login, Registro
│   │   │   ├── presentation/
│   │   │   │   ├── screens/   # login_screen.dart, register_screen.dart
│   │   │   │   └── widgets/   # register_form.dart
│   │   │   └── data/
│   │   │
│   │   ├── partnerships/      # Fluxo COMPLETO de parcerias
│   │   │   ├── presentation/
│   │   │   │   ├── screens/   
│   │   │   │   │   ├── lawyer_search_screen.dart      # Busca de parceiros
│   │   │   │   │   ├── propose_partnership_screen.dart # Envio de proposta
│   │   │   │   │   ├── offers_screen.dart             # Ofertas recebidas
│   │   │   │   │   ├── partnerships_screen.dart       # Lista de parcerias
│   │   │   │   │   ├── contract_screen.dart           # Visualização de contrato
│   │   │   │   │   ├── partnerships_dashboard_screen.dart # Dashboard administrativo
│   │   │   │   │   └── lawyer_history_screen.dart     # Histórico por advogado
│   │   │   │   └── widgets/   
│   │   │   │       ├── partnership_card.dart         # Card de parceria
│   │   │   │       ├── contract_viewer.dart          # Visualizador de contrato
│   │   │   │       ├── partnership_list.dart         # Lista reutilizável
│   │   │   │       ├── proposal_modal.dart           # Modal de proposta
│   │   │   │       └── partnership_filters.dart      # Filtros do dashboard
│   │   │   └── data/
│   │   │       └── partnership_service.dart          # Serviço REST completo
│   │   │
│   ├── navigation/        # Navegação dinâmica por perfil
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart              # Tela inicial
│   │   │   │   ├── dashboard_screen.dart         # Painel advogado associado
│   │   │   │   └── lawyer_home_screen.dart       # Home para contratantes
│   │   │   │   └── widgets/
│   │   │   │       └── dynamic_navigation_bar.dart   # Barra de navegação dinâmica
│   │   │   └── data/
│   │   │
│   ├── shared/                # Widgets e utilitários compartilhados
│   │   ├── widgets/           # CustomButton, LoadingIndicator, etc.
│   │   ├── constants/         # Constantes do app
│   │   └── utils/             # Utilitários gerais
│   │
│   └── router/                # Configuração do GoRouter
│       └── app_router.dart
│
└── main.dart
```

---

## 2. Navegação Dinâmica por Perfil de Usuário

### A. Configuração da Navegação Principal

```dart
// lib/src/features/navigation/presentation/widgets/dynamic_navigation_bar.dart

class DynamicNavigationBar extends StatelessWidget {
  final String userType;
  final int currentIndex;
  final Function(int) onTap;

  const DynamicNavigationBar({
    required this.userType,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabsForUserType(userType);
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: tabs.map((tab) => NavigationDestination(
        icon: Icon(tab.icon),
        label: tab.label,
      )).toList(),
    );
  }

  List<NavItem> _getTabsForUserType(String userType) {
    if (userType == 'lawyer_office' || userType == 'lawyer_individual') {
      return [
        NavItem(icon: Icons.home, label: 'Início'),
        NavItem(icon: Icons.search, label: 'Parceiros'),
        NavItem(icon: Icons.handshake, label: 'Parcerias'),
        NavItem(icon: Icons.chat, label: 'Mensagens'),
        NavItem(icon: Icons.person, label: 'Perfil'),
      ];
    } else if (userType == 'lawyer_associated') {
      return [
        NavItem(icon: Icons.dashboard, label: 'Painel'),
        NavItem(icon: Icons.folder, label: 'Casos'),
        NavItem(icon: Icons.event_note, label: 'Agenda'),
        NavItem(icon: Icons.inbox, label: 'Ofertas'),
        NavItem(icon: Icons.chat, label: 'Mensagens'),
        NavItem(icon: Icons.person, label: 'Perfil'),
      ];
    }
    // Fallback para clientes
    return [
      NavItem(icon: Icons.home, label: 'Início'),
      NavItem(icon: Icons.search, label: 'Buscar'),
      NavItem(icon: Icons.cases, label: 'Casos'),
      NavItem(icon: Icons.person, label: 'Perfil'),
    ];
  }
}

class NavItem {
  final IconData icon;
  final String label;
  
  NavItem({required this.icon, required this.label});
}
```

---

## 3. Implementação das Telas de Parcerias

### A. Tela de Busca de Parceiros

```dart
// lib/src/features/partnerships/presentation/screens/lawyer_search_screen.dart

class LawyerSearchScreen extends StatefulWidget {
  @override
  _LawyerSearchScreenState createState() => _LawyerSearchScreenState();
}

class _LawyerSearchScreenState extends State<LawyerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MatchedLawyer> matchedLawyers = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Parceiro Jurídico')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Descreva sua necessidade de parceria',
                    hintText: 'Ex: Preciso de apoio em Direito Ambiental...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _searchPartners,
                  child: isLoading 
                    ? CircularProgressIndicator()
                    : Text('Buscar Parceiros'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matchedLawyers.length,
              itemBuilder: (context, index) {
                final lawyer = matchedLawyers[index];
                return LawyerCard(
                  lawyer: lawyer,
                  onInvite: () => _showProposalModal(lawyer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchPartners() async {
    setState(() => isLoading = true);
    try {
      final results = await PartnershipService.findPartners(_searchController.text);
      setState(() => matchedLawyers = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar parceiros: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showProposalModal(MatchedLawyer lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProposePartnershipScreen(lawyer: lawyer),
    );
  }
}
```

### B. Tela de Proposta de Parceria

```dart
// lib/src/features/partnerships/presentation/screens/propose_partnership_screen.dart

class ProposePartnershipScreen extends StatefulWidget {
  final MatchedLawyer lawyer;

  const ProposePartnershipScreen({required this.lawyer});

  @override
  _ProposePartnershipScreenState createState() => _ProposePartnershipScreenState();
}

class _ProposePartnershipScreenState extends State<ProposePartnershipScreen> {
  final _formKey = GlobalKey<FormState>();
  String type = 'consultoria';
  String? honorarios;
  String? message;
  String? caseId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Propor Parceria com ${widget.lawyer.nome}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              items: [
                'consultoria',
                'redacao_tecnica', 
                'audiencia',
                'suporte_total',
                'parceria_recorrente'
              ].map((e) => DropdownMenuItem(
                value: e, 
                child: Text(e.replaceAll('_', ' ').toUpperCase())
              )).toList(),
              onChanged: (val) => setState(() => type = val!),
              decoration: InputDecoration(labelText: 'Tipo de Parceria'),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Honorários',
                hintText: 'Ex: R$ 1.500,00 ou A combinar',
              ),
              onChanged: (val) => honorarios = val,
              validator: (val) => val?.isEmpty == true ? 'Campo obrigatório' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Mensagem (opcional)',
                hintText: 'Descreva melhor a necessidade...',
              ),
              maxLines: 3,
              onChanged: (val) => message = val,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendProposal,
                    child: Text('Enviar Proposta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendProposal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await PartnershipService.sendProposal(
        partnerId: widget.lawyer.id,
        type: type,
        honorarios: honorarios!,
        message: message,
        caseId: caseId,
      );
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proposta enviada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar proposta: $e')),
      );
    }
  }
}
```

### C. Tela de Visualização de Contrato

```dart
// lib/src/features/partnerships/presentation/screens/contract_screen.dart

class ContractScreen extends StatefulWidget {
  final Partnership partnership;

  const ContractScreen({required this.partnership});

  @override
  _ContractScreenState createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrato de Parceria')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContractHeader(),
                  SizedBox(height: 20),
                  _buildContractContent(),
                ],
              ),
            ),
          ),
          if (_canAcceptContract())
            _buildAcceptButton(),
        ],
      ),
    );
  }

  Widget _buildContractHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contrato de Parceria Jurídica',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text('Tipo: ${widget.partnership.type}'),
            Text('Status: ${widget.partnership.status}'),
            Text('Honorários: ${widget.partnership.honorarios}'),
          ],
        ),
      ),
    );
  }

  Widget _buildContractContent() {
    // Aqui você pode usar um WebView ou Html widget para renderizar o contrato
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          widget.partnership.contractText ?? 'Contrato sendo gerado...',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  bool _canAcceptContract() {
    return widget.partnership.status == 'contrato_pendente';
  }

  Widget _buildAcceptButton() {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _acceptContract,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
          ? CircularProgressIndicator()
          : Text('Aceitar e Assinar Digitalmente'),
      ),
    );
  }

  Future<void> _acceptContract() async {
    setState(() => isLoading = true);
    try {
      await PartnershipService.acceptContract(widget.partnership.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contrato aceito com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar contrato: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
```

---

## 4. Painel Administrativo de Parcerias

### A. Tela Principal de Parcerias

```dart
// lib/src/features/partnerships/presentation/screens/partnerships_screen.dart

class PartnershipsScreen extends StatefulWidget {
  @override
  _PartnershipsScreenState createState() => _PartnershipsScreenState();
}

class _PartnershipsScreenState extends State<PartnershipsScreen> {
  List<Partnership> sent = [];
  List<Partnership> received = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPartnerships();
  }

  Future<void> loadPartnerships() async {
    setState(() => isLoading = true);
    try {
      final data = await PartnershipService.fetchMyPartnerships();
      setState(() {
        sent = data['sent'] ?? [];
        received = data['received'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar parcerias: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Minhas Parcerias')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Minhas Parcerias'),
          actions: [
            IconButton(
              icon: Icon(Icons.dashboard),
              onPressed: () => Navigator.pushNamed(context, '/partnerships/dashboard'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Enviadas (${sent.length})'),
              Tab(text: 'Recebidas (${received.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PartnershipList(partnerships: sent, isSender: true),
            PartnershipList(partnerships: received, isSender: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/partnerships/search'),
          child: Icon(Icons.add),
          tooltip: 'Buscar Parceiro',
        ),
      ),
    );
  }
}
```

### B. Widget de Lista de Parcerias

```dart
// lib/src/features/partnerships/presentation/widgets/partnership_list.dart

class PartnershipList extends StatelessWidget {
  final List<Partnership> partnerships;
  final bool isSender;

  const PartnershipList({
    required this.partnerships,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    if (partnerships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              isSender ? 'Nenhuma proposta enviada' : 'Nenhuma proposta recebida',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic here
      },
      child: ListView.builder(
        itemCount: partnerships.length,
        itemBuilder: (context, index) {
          final partnership = partnerships[index];
          return PartnershipCard(
            partnership: partnership,
            isSender: isSender,
            onTap: () => _showPartnershipDetails(context, partnership),
            onAction: (action) => _handleAction(context, partnership, action),
          );
        },
      ),
    );
  }

  void _showPartnershipDetails(BuildContext context, Partnership partnership) {
    Navigator.pushNamed(
      context, 
      '/partnerships/details',
      arguments: partnership,
    );
  }

  void _handleAction(BuildContext context, Partnership partnership, String action) {
    switch (action) {
      case 'accept':
        PartnershipService.acceptProposal(partnership.id);
        break;
      case 'reject':
        PartnershipService.rejectProposal(partnership.id);
        break;
      case 'view_contract':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractScreen(partnership: partnership),
          ),
        );
        break;
    }
  }
}
```

---

## 5. Dashboard de Parcerias com Filtros e Indicadores

### A. Tela do Dashboard

```dart
// lib/src/features/partnerships/presentation/screens/partnerships_dashboard_screen.dart

class PartnershipsDashboardScreen extends StatefulWidget {
  @override
  _PartnershipsDashboardScreenState createState() => _PartnershipsDashboardScreenState();
}

class _PartnershipsDashboardScreenState extends State<PartnershipsDashboardScreen> {
  List<Partnership> allPartnerships = [];
  String statusFilter = 'todas';
  String typeFilter = 'todas';
  DateTimeRange? dateRange;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllPartnerships();
  }

  Future<void> fetchAllPartnerships() async {
    setState(() => isLoading = true);
    try {
      final result = await PartnershipService.fetchAllPartnerships();
      setState(() => allPartnerships = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Partnership> get filteredPartnerships {
    return allPartnerships.where((p) {
      final matchStatus = statusFilter == 'todas' || p.status == statusFilter;
      final matchType = typeFilter == 'todas' || p.type == typeFilter;
      
      bool matchDate = true;
      if (dateRange != null) {
        final createdAt = DateTime.parse(p.createdAt);
        matchDate = createdAt.isAfter(dateRange!.start) && 
                   createdAt.isBefore(dateRange!.end);
      }
      
      return matchStatus && matchType && matchDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard de Parcerias')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = filteredPartnerships;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard de Parcerias'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAllPartnerships,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStats(filtered),
          _buildChart(filtered),
          Expanded(
            child: PartnershipList(partnerships: filtered, isSender: false),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: InputDecoration(labelText: 'Status'),
                    onChanged: (val) => setState(() => statusFilter = val!),
                    items: [
                      'todas',
                      'pendente',
                      'aceita', 
                      'contrato_pendente',
                      'ativa',
                      'finalizada',
                      'rejeitada'
                    ].map((s) => DropdownMenuItem(
                      value: s, 
                      child: Text(s.replaceAll('_', ' ').toUpperCase())
                    )).toList(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: typeFilter,
                    decoration: InputDecoration(labelText: 'Tipo'),
                    onChanged: (val) => setState(() => typeFilter = val!),
                    items: [
                      'todas',
                      'consultoria',
                      'redacao_tecnica',
                      'audiencia',
                      'suporte_total',
                      'parceria_recorrente'
                    ].map((s) => DropdownMenuItem(
                      value: s, 
                      child: Text(s.replaceAll('_', ' ').toUpperCase())
                    )).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.date_range),
                    label: Text(dateRange == null 
                      ? 'Filtrar por período' 
                      : '${dateRange!.start.day}/${dateRange!.start.month} - ${dateRange!.end.day}/${dateRange!.end.month}'),
                    onPressed: _selectDateRange,
                  ),
                ),
                if (dateRange != null) ...[
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() => dateRange = null),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<Partnership> filtered) {
    final ativas = filtered.where((p) => p.status == 'ativa').length;
    final pendentes = filtered.where((p) => p.status == 'pendente').length;
    final finalizadas = filtered.where((p) => p.status == 'finalizada').length;
    final rejeitadas = filtered.where((p) => p.status == 'rejeitada').length;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumo das Parcerias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Ativas', ativas, Colors.green),
                _buildStatCard('Pendentes', pendentes, Colors.orange),
                _buildStatCard('Finalizadas', finalizadas, Colors.blue),
                _buildStatCard('Rejeitadas', rejeitadas, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChart(List<Partnership> filtered) {
    // Aqui você pode implementar um gráfico usando fl_chart ou similar
    return Card(
      margin: EdgeInsets.all(8),
      child: Container(
        height: 200,
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Gráfico de Evolução das Parcerias\n(Implementar com fl_chart)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: dateRange,
    );
    
    if (picked != null) {
      setState(() => dateRange = picked);
    }
  }
}
```

---

## 6. Histórico de Atuação por Advogado

```dart
// lib/src/features/partnerships/presentation/screens/lawyer_history_screen.dart

class LawyerHistoryScreen extends StatelessWidget {
  final String lawyerId;
  final String lawyerName;

  const LawyerHistoryScreen({
    required this.lawyerId,
    required this.lawyerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico - $lawyerName'),
      ),
      body: FutureBuilder<List<Partnership>>(
        future: PartnershipService.getHistoryByLawyer(lawyerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erro ao carregar histórico'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Voltar'),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data ?? [];
          
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma parceria encontrada'),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryCard(history),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final partnership = history[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: _getStatusIcon(partnership.status),
                        title: Text(partnership.type.replaceAll('_', ' ').toUpperCase()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${partnership.status}'),
                            Text('Data: ${_formatDate(partnership.createdAt)}'),
                            if (partnership.honorarios.isNotEmpty)
                              Text('Honorários: ${partnership.honorarios}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/partnerships/details',
                            arguments: partnership,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<Partnership> history) {
    final total = history.length;
    final ativas = history.where((p) => p.status == 'ativa').length;
    final finalizadas = history.where((p) => p.status == 'finalizada').length;
    final successRate = total > 0 ? (finalizadas / total * 100).toStringAsFixed(1) : '0.0';

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumo de Parcerias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', total.toString()),
                _buildSummaryItem('Ativas', ativas.toString()),
                _buildSummaryItem('Finalizadas', finalizadas.toString()),
                _buildSummaryItem('Taxa Sucesso', '$successRate%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'ativa':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'pendente':
        return Icon(Icons.pending, color: Colors.orange);
      case 'finalizada':
        return Icon(Icons.done_all, color: Colors.blue);
      case 'rejeitada':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

---

## 7. Serviço REST Completo

```dart
// lib/src/features/partnerships/data/partnership_service.dart

class PartnershipService {
  static const String baseUrl = 'YOUR_API_BASE_URL';
  static late Dio _dio;

  static void initialize() {
    _dio = Dio();
    _dio.interceptors.add(AuthInterceptor()); // Adiciona token automaticamente
  }

  // Busca de parceiros usando algoritmo de match
  static Future<List<MatchedLawyer>> findPartners(String description) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/partners/find-matches',
        data: {'description': description},
      );
      
      return (response.data as List)
          .map((json) => MatchedLawyer.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar parceiros: $e');
    }
  }

  // Envio de proposta de parceria
  static Future<void> sendProposal({
    required String partnerId,
    required String type,
    required String honorarios,
    String? message,
    String? caseId,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/api/partnerships',
        data: {
          'partner_id': partnerId,
          'type': type,
          'honorarios': honorarios,
          'proposal_message': message,
          'case_id': caseId,
        },
      );
    } catch (e) {
      throw Exception('Erro ao enviar proposta: $e');
    }
  }

  // Buscar parcerias do usuário (enviadas e recebidas)
  static Future<Map<String, List<Partnership>>> fetchMyPartnerships() async {
    try {
      final response = await _dio.get('$baseUrl/api/partnerships');
      
      return {
        'sent': (response.data['sent'] as List?)
            ?.map((json) => Partnership.fromJson(json))
            .toList() ?? [],
        'received': (response.data['received'] as List?)
            ?.map((json) => Partnership.fromJson(json))
            .toList() ?? [],
      };
    } catch (e) {
      throw Exception('Erro ao buscar parcerias: $e');
    }
  }

  // Buscar todas as parcerias para dashboard
  static Future<List<Partnership>> fetchAllPartnerships() async {
    try {
      final response = await _dio.get('$baseUrl/api/partnerships?all=true');
      
      return (response.data as List)
          .map((json) => Partnership.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar todas as parcerias: $e');
    }
  }

  // Aceitar proposta de parceria
  static Future<void> acceptProposal(String partnershipId) async {
    try {
      await _dio.patch('$baseUrl/api/partnerships/$partnershipId/accept');
    } catch (e) {
      throw Exception('Erro ao aceitar proposta: $e');
    }
  }

  // Rejeitar proposta de parceria
  static Future<void> rejectProposal(String partnershipId) async {
    try {
      await _dio.patch('$baseUrl/api/partnerships/$partnershipId/reject');
    } catch (e) {
      throw Exception('Erro ao rejeitar proposta: $e');
    }
  }

  // Aceitar contrato digital
  static Future<void> acceptContract(String partnershipId) async {
    try {
      await _dio.patch('$baseUrl/api/partnerships/$partnershipId/accept-contract');
    } catch (e) {
      throw Exception('Erro ao aceitar contrato: $e');
    }
  }

  // Buscar histórico de parcerias por advogado
  static Future<List<Partnership>> getHistoryByLawyer(String lawyerId) async {
    try {
      final response = await _dio.get('$baseUrl/api/partnerships/history/$lawyerId');
      
      return (response.data as List)
          .map((json) => Partnership.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar histórico: $e');
    }
  }
}
```

---

## 8. Gerenciamento de Estado com Riverpod

```dart
// lib/src/features/partnerships/data/partnerships_provider.dart

final partnershipsProvider = StateNotifierProvider<PartnershipsNotifier, PartnershipsState>((ref) {
  return PartnershipsNotifier();
});

class PartnershipsState {
  final List<Partnership> sent;
  final List<Partnership> received;
  final bool isLoading;
  final String? error;

  PartnershipsState({
    this.sent = const [],
    this.received = const [],
    this.isLoading = false,
    this.error,
  });

  PartnershipsState copyWith({
    List<Partnership>? sent,
    List<Partnership>? received,
    bool? isLoading,
    String? error,
  }) {
    return PartnershipsState(
      sent: sent ?? this.sent,
      received: received ?? this.received,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PartnershipsNotifier extends StateNotifier<PartnershipsState> {
  PartnershipsNotifier() : super(PartnershipsState());

  Future<void> loadPartnerships() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await PartnershipService.fetchMyPartnerships();
      state = state.copyWith(
        sent: data['sent'] ?? [],
        received: data['received'] ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> acceptProposal(String partnershipId) async {
    try {
      await PartnershipService.acceptProposal(partnershipId);
      await loadPartnerships(); // Recarregar lista
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectProposal(String partnershipId) async {
    try {
      await PartnershipService.rejectProposal(partnershipId);
      await loadPartnerships(); // Recarregar lista
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
```

---

## ✅ Recursos Administrativos Completos Incluídos:

| Recurso                           | Implementação                                          |
| --------------------------------- | ----------------------------------------------------- |
| **Navegação por perfil**          | Abas dinâmicas baseadas no `user_type`               |
| **Busca de parceiros**            | Integração com algoritmo de match existente          |
| **Envio de propostas**            | Modal/tela com formulário completo                   |
| **Painel de parcerias**           | Abas separadas para enviadas/recebidas               |
| **Visualização de contratos**     | Tela dedicada com aceite digital                     |
| **Dashboard administrativo**      | Filtros por status, tipo e período                   |
| **Indicadores visuais**           | Cards com totais e gráficos                          |
| **Histórico por advogado**        | Tela dedicada com estatísticas                       |
| **Gerenciamento de estado**       | Riverpod para estado reativo                         |
| **Serviço REST completo**         | Todas as chamadas para o backend                     |

---

## ✅ Próximos Passos de Implementação:

1. **Estrutura base**: Criar pastas e arquivos conforme organização
2. **Modelos de dados**: Implementar classes `Partnership`, `MatchedLawyer`, etc.
3. **Navegação dinâmica**: Configurar `GoRouter` e navegação por perfil
4. **Telas principais**: Implementar busca, propostas e listagem
5. **Dashboard**: Desenvolver filtros e indicadores
6. **Integração**: Conectar com backend de parcerias
7. **Testes**: Criar testes unitários e de widget
8. **Polimento**: Adicionar animações e melhorias de UX

Este plano fornece uma implementação completa e escalável para o sistema de parcerias jurídicas no Flutter, com todas as funcionalidades administrativas necessárias. 