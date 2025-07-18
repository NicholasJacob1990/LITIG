# Recomendações de Layout para Cartões - Interface de Busca de Advogados

## 📋 Visão Geral

Este documento estabelece as recomendações de layout para cartões de advogados e escritórios, otimizadas por contexto de uso e necessidades específicas de cada aba da interface.

**Data:** Janeiro 2025  
**Escopo:** Otimização de UX para `LawyersScreen`  
**Base:** Análise da especificação do vídeo + código atual

---

## 🎯 **Estratégia por Contexto**

### **1. 📱 Aba "Buscar Advogado" → Cartões COMPACTOS**

#### **Justificativa Estratégica**
- **Performance:** Renderização de 20-100+ resultados
- **Escaneabilidade:** Comparação rápida entre opções
- **Mobile-First:** Máximo aproveitamento do viewport
- **Foco na Filtragem:** Informações essenciais para decisão inicial

#### **Layout Recomendado: `CompactSearchCard`**

```dart
// Dimensões alvo
height: 140-160px (ajustado para incluir todos os elementos)
padding: 12px (vs 16px atual)
margins: 8px vertical (vs 8px atual)

// Layout completo baseado na especificação
┌─────────────────────────────────────────────────────┐
│ [AVATAR] Dr. João Silva                             │ ← Avatar + Nome bold
│ [ICON] Direito Civil                                │ ← Área em azul claro
│ [🏆] {badges_dinamicos}                            │ ← Badges dourados (fonte mista)
│ 🔍 Por que este advogado? ▼                        │ ← Link colapsável azul-escuro
│ [SELECIONAR 70%]  [Ver Perfil Completo]            │ ← Botões de ação
└─────────────────────────────────────────────────────┘
```

#### **Elementos Incluídos (Especificação Completa)**
- ✅ **Avatar circular** (placeholder se necessário)
- ✅ **Nome completo** em branco, fonte sem-serifa bold
- ✅ **Área de atuação** em azul claro
- ✅ **Badges dourados** (pílulas): Prêmios/certificações dinâmicas (auto-declaradas + APIs)
- ✅ **Link colapsável** "Por que este advogado?" em azul-claro mais escuro
- ✅ **Botão "Selecionar"** azul (~70% largura)
- ✅ **Link "Ver Perfil Completo"** (azul sublinhado)

#### **Elementos Removidos (Exclusivos das Recomendações)**
- ❌ **Score de compatibilidade** (89%, 87%, 92%) - só nas recomendações
- ❌ **Métricas essenciais individuais** (⭐📍✅) - informações básicas no link expansível
- ❌ **Métricas expandidas** (5 colunas completas)
- ❌ **Análise de compatibilidade** detalhada
- ❌ **Botões Chat e Vídeo** - só após seleção/nas recomendações

---

### **2. ⭐ Aba "Recomendações" → Cartões COMPLETOS**

#### **Justificativa Estratégica**
- **Algoritmo Inteligente:** Sistema já fez pré-seleção
- **Decisão Informada:** Usuário precisa entender o "porquê"
- **Conversão Otimizada:** Mais informações = melhor decisão
- **Diferenciação:** Destaque para fatores únicos

#### **Layout Atual: `LawyerMatchCard` (Manter)**

```dart
// Dimensões atuais (manter)
height: 280-350px (dinâmico)
padding: 16px
margins: 8px vertical

// Estrutura completa (preservar)
┌─────────────────────────────────────────────────┐
│ [AVATAR] Dr. João Silva              [89%]      │ ← Header completo
│ [BRIEFCASE] 15 anos • [Ver Currículo]          │ ← Experiência
│ [AWARD] Top Lawyer 2023 • OAB Destaque 2022    │ ← Prêmios
│ ⚖️ Autoridade no Assunto                       │ ← Badge especial
│                                                 │
│ [⭐] [✅] [🕐] [🧠] [👥]                        │ ← 5 métricas
│ 4.8   85%  2h   90   47                       │
│                                                 │
│ 🔍 Analisar Compatibilidade ▼                  │ ← Expansível
│                                                 │
│ [CONTRATAR] [CHAT] [VÍDEO]                     │ ← Ações
└─────────────────────────────────────────────────┘
```

#### **Benefícios do Layout Completo**
- ✅ **Score explicado** ("Por que este advogado?")
- ✅ **Contexto rico** (experiência, prêmios, autoridade)
- ✅ **Ações imediatas** (contratar, chat, vídeo)
- ✅ **Confiança** (mais dados = mais segurança)

---

## 🏆 **Sistema de Badges Dinâmicos**

### **📊 Fontes de Prêmios/Certificações**

| Fonte | Tipo | Exemplos | Validação |
|---|---|---|---|
| **Auto-Declaração** | Perfil do usuário | "Especialista em Direito Civil", "15 anos experiência" | Moderação manual |
| **APIs Externas** | Integração automática | "OAB Destaque 2023", "Selo Procon" | Validação API |
| **Plataforma** | Sistema interno | "Top Rated", "Resposta Rápida" | Algoritmo interno |
| **Certificações** | Upload de documentos | "Pós-graduação USP", "Certificado OAB" | Verificação documental |

### **🎨 Tratamento Visual dos Badges**

```dart
// Renderização dinâmica seguindo o sistema de cores do app
Widget _buildDynamicBadges(List<Badge> badges) {
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    children: badges.take(3).map((badge) => Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getBadgeColor(badge.source), // Cor por fonte
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBadgeBorderColor(badge.source),
          width: 1,
        ),
      ),
      child: Text(
        badge.title,
        style: TextStyle(
          color: _getBadgeTextColor(badge.source),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    )).toList(),
  );
}

// Cores por fonte seguindo AppColors
Color _getBadgeColor(BadgeSource source) {
  switch (source) {
    case BadgeSource.api: 
      return AppColors.warning.withOpacity(0.15);        // APIs externas - dourado
    case BadgeSource.platform: 
      return AppColors.primaryBlue.withOpacity(0.15);    // Sistema interno - azul  
    case BadgeSource.certified: 
      return AppColors.success.withOpacity(0.15);        // Certificado - verde
    case BadgeSource.declared: 
      return AppColors.lightTextSecondary.withOpacity(0.15); // Auto-declarado - cinza
  }
}

Color _getBadgeBorderColor(BadgeSource source) {
  switch (source) {
    case BadgeSource.api: return AppColors.warning.withOpacity(0.3);
    case BadgeSource.platform: return AppColors.primaryBlue.withOpacity(0.3);
    case BadgeSource.certified: return AppColors.success.withOpacity(0.3);
    case BadgeSource.declared: return AppColors.lightTextSecondary.withOpacity(0.3);
  }
}

Color _getBadgeTextColor(BadgeSource source) {
  switch (source) {
    case BadgeSource.api: return AppColors.warning;
    case BadgeSource.platform: return AppColors.primaryBlue;
    case BadgeSource.certified: return AppColors.success;
    case BadgeSource.declared: return AppColors.lightText2;
  }
}
```

### **⚡ Exemplos Dinâmicos**

#### **Advogados:**
- **APIs:** "OAB Destaque 2023", "Selo Procon Qualidade"
- **Plataforma:** "Top Rated 4.9★", "Resposta em 1h"  
- **Auto-declarado:** "Especialista Trabalhista", "Mediador Certificado"
- **Certificações:** "Pós-graduação FGV", "LLM Direito Digital"

#### **Escritórios:**
- **APIs:** "Selo OAB-SP Excelência", "Prêmio Análise Advocacia"
- **Plataforma:** "Escritório Destaque", "100% Aprovação"
- **Auto-declarado:** "Boutique Tributário", "Departamento Compliance"
- **Certificações:** "ISO 9001", "Certificação LGPD"

---

## 🏢 **Estratégia para Escritórios: Abordagem Híbrida**

### **Contexto de Uso Diferenciado**

```
📊 ANÁLISE DE CONTEXTO:

Aba "Buscar" (Diretório)      vs.     Aba "Recomendações" (IA)
├── Exploração livre                  ├── Seleção pré-filtrada  
├── Comparação massiva                ├── Análise detalhada
├── Filtros manuais                   ├── Contexto do caso
└── Performance crítica               └── Conversão otimizada
```

### **1. 🏢 Escritórios na Busca → Layout Compacto Equivalente**

```dart
FirmCard(
  layout: CardLayout.compact,
  height: 140-160px, // Paridade com advogados compactos
  
  // Layout equivalente aos advogados
  ┌─────────────────────────────────────────────────────┐
  │ [LOGO] Silva & Associados                           │ ← Logo + Nome bold
  │ [ICON] Direito Civil • Trabalhista                  │ ← Áreas principais
  │ [🏆] Selo OAB-SP • Prêmio Excelência 2023          │ ← Badges dourados
  │ 🔍 Por que este escritório? ▼                      │ ← Link colapsável azul-escuro
  │ [SELECIONAR 70%]  [Ver Escritório Completo]        │ ← Botões de ação
  └─────────────────────────────────────────────────────┘
)

// Elementos específicos para escritórios:
elements: [
  'logo_escritorio',        // Avatar equivalente
  'nome_completo',          // Nome bold como advogados
  'areas_principais',       // 2-3 áreas em azul claro
  'badges_dinamicos',       // Badges dourados (auto-declarados + APIs)
  'link_expansivel',        // "Por que este escritório?" azul-escuro
  'botao_selecionar',       // 70% largura azul
  'link_ver_completo'       // "Ver Escritório Completo"
]
```

### **2. 🏢 Escritórios nas Recomendações → Layout Completo**

```dart
FirmCard(
  layout: CardLayout.complete,
  height: 200-250px, // Paridade com LawyerMatchCard
  elements: [
    'logo_branding',
    'nome_historia_anos',
    'equipe_preview', // Top 3 advogados
    'compatibility_score', // Score agregado da equipe
    'kpis_expandidos', // 5 métricas como advogados
    'certificacoes_premios',
    'link_ver_equipe_completa', // ⭐ NOVO ELEMENTO CRÍTICO
    'botoes_acao_contextuais' // Diferenciados por contexto (busca vs recomendações)
  ]
)
```

---

## 🎬 **Estratégia de Botões por Contexto**

### **📱 Cartões Compactos (Aba "Buscar")**
**Filosofia:** Foco na **seleção e exploração** inicial

```dart
// Advogados - Busca
Row(
  children: [
    Expanded(
      flex: 7,
      child: ElevatedButton(
        onPressed: () => _selectLawyer(),
        child: Text('Selecionar'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      flex: 3,
      child: TextButton(
        onPressed: () => _viewFullProfile(),
        child: Text('Ver Perfil'),
      ),
    ),
  ],
)

// Escritórios - Busca
Row(
  children: [
    Expanded(
      flex: 7,
      child: ElevatedButton(
        onPressed: () => _selectFirm(),
        child: Text('Selecionar'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      flex: 3,
      child: TextButton(
        onPressed: () => _viewFirmDetails(),
        child: Text('Ver Escritório'),
      ),
    ),
  ],
)
```

### **⭐ Cartões Completos (Aba "Recomendações")**
**Filosofia:** Foco na **contratação** e **análise detalhada**

```dart
// Advogados - Recomendações
Row(
  children: [
    Expanded(
      flex: 7,
      child: ElevatedButton.icon(
        onPressed: () => _hireLawyer(),
        icon: Icon(LucideIcons.fileSignature),
        label: Text('Contratar'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      flex: 3,
      child: TextButton(
        onPressed: () => _viewFullProfile(),
        child: Text('Ver Perfil'),
      ),
    ),
  ],
)

// Escritórios - Recomendações
Row(
  children: [
    Expanded(
      flex: 7,
      child: ElevatedButton.icon(
        onPressed: () => _hireFirm(),
        icon: Icon(LucideIcons.building),
        label: Text('Contratar'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      flex: 3,
      child: TextButton(
        onPressed: () => _viewFirmDetails(),
        child: Text('Ver Escritório'),
      ),
    ),
  ],
)

// ❌ CHAT E VÍDEO REMOVIDOS - Disponíveis apenas APÓS contratação
```

### **🎯 Justificativa da Estratégia Unificada**

| Contexto | Botões | Justificativa |
|---|---|---|
| **Busca** | Selecionar + Ver Perfil | Usuário está **explorando opções**, comparando múltiplas alternativas |
| **Recomendações** | Contratar + Ver Perfil | Sistema **pré-selecionou**, mas usuário ainda precisa **decidir contratar** |
| **Pós-Contratação** | Chat + Vídeo + Documentos | Funcionalidades de **relacionamento** só após compromisso firmado |

### **💡 Princípio Fundamental**
**Chat e Vídeo são ferramentas de relacionamento profissional** que só fazem sentido **após a contratação**, quando existe um compromisso formal entre as partes.

---

## 📊 **Métricas de Performance Esperadas**

### **Aba "Buscar" (Cartões Compactos)**
- 📈 **+40% itens visíveis** por tela (140-160px vs 280+ atuais)
- 📈 **+35% scroll performance** (renderização otimizada)
- 📈 **+60% engagement** com badges visuais e link expansível
- 📈 **+45% exploração** de informações ("Por que este?")
- 📉 **-25% tempo decisão** inicial (layout limpo e focado)

### **Aba "Recomendações" (Cartões Completos)**
- 📈 **+50% conversão** (mais contexto)
- 📈 **+35% tempo sessão** (análise detalhada)
- 📈 **+80% uso** do botão "Por que?"
- 📉 **-20% abandono** (decisão mais informada)

### **Escritórios (Híbrido)**
- 📈 **+45% visualização** da equipe completa
- 📈 **+60% contratações** institucionais
- 📈 **+30% retenção** (transparência da equipe)

---

## 🚀 **Plano de Implementação**

### **Fase 1: Cartões Compactos para Busca (4-5 dias)**
1. **Criar `CompactSearchCard`** e `CompactFirmCard` widgets
2. **Implementar sistema de badges dinâmicos:**
   - Estrutura `Badge` (title, source, validation_status)
   - Renderização com cores por fonte (API, plataforma, certificado, declarado)
   - Limite de 3 badges visíveis + "mais X"
3. **Desenvolver link colapsável** "Por que este advogado/escritório?" em azul-escuro
4. **Implementar conteúdo expansível** com informações básicas (avaliação, distância, disponibilidade)
5. **Desenvolver botões de pré-contratação:**
   - **Busca:** "Selecionar" (70%) + "Ver Perfil Completo" (30%)
   - **Recomendações:** "Contratar" (70%) + "Ver Perfil" (30%)
   - **⚠️ Chat e Vídeo:** Apenas APÓS contratação (fora do escopo dos cartões)
6. **Configurar toggle** layout por contexto (busca vs recomendações)
7. **Testes A/B** compacto vs atual

### **Fase 2: Expansão Escritórios (3-4 dias)**
1. **Implementar paridade** de elementos (scores, métricas)
2. **Criar "Ver Equipe Completa"** navegação
3. **Desenvolver FirmLawyersScreen** com cartões individuais
4. **Integrar sistema** de contratação institucional

### **Fase 3: Refinamentos (1-2 dias)**
1. **Ajustar animações** de transição
2. **Otimizar cores** e tipografia
3. **Validar acessibilidade**
4. **Documentar padrões** de uso

---

## 🎨 **Especificações Visuais**

### **Cores por Contexto (Baseadas no Sistema AppColors)**
```dart
// Tema Claro
surface: AppColors.lightCard (#FFFFFF)
background: AppColors.lightBackground (#F8FAFC)
primary: AppColors.primaryBlue (#2563EB)
text: AppColors.lightText (#1E293B)
textSecondary: AppColors.lightText2 (#64748B)

// Tema Escuro  
surface: AppColors.darkCard (#1E293B)
background: AppColors.darkBackground (#0F172A)
primary: AppColors.primaryBlue (#2563EB) // Consistente entre temas
text: AppColors.darkText (#F1F5F9)
textSecondary: AppColors.darkText2 (#CBD5E1)

// Cores de Status (Consistentes entre temas)
success: AppColors.success (#10B981) // Disponibilidade
warning: AppColors.warning (#F59E0B) // Badges dourados
error: AppColors.error (#EF4444) // Indisponível
info: AppColors.info (#3B82F6) // Informações
```

### **Tipografia (Usando Google Fonts Inter do Sistema)**
```dart
// Cartões Compactos (Busca)
title: Theme.of(context).textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.w600, // Semibold
  fontSize: 16,
)
subtitle: Theme.of(context).textTheme.bodyMedium?.copyWith(
  fontSize: 13,
  color: Theme.of(context).brightness == Brightness.dark 
    ? AppColors.darkText2 
    : AppColors.lightText2,
)

// Cartões Completos (Recomendações - manter atual)
title: Theme.of(context).textTheme.titleLarge?.copyWith(
  fontWeight: FontWeight.bold, // Bold
  fontSize: 18,
)
subtitle: Theme.of(context).textTheme.bodyMedium?.copyWith(
  fontSize: 14,
)
```

---

## ✅ **Resultados Esperados**

### **Experiência do Usuário**
- **Busca Eficiente:** Comparação rápida de múltiplas opções
- **Decisão Informada:** Contexto rico para recomendações
- **Paridade Institucional:** Escritórios com mesmo nível de detalhe
- **Fluxo Coeso:** Transição natural entre exploração e contratação

### **Métricas de Negócio**
- **+40% conversão** geral na busca de advogados
- **+50% engajamento** com escritórios
- **+25% satisfação** (NPS) na interface
- **+60% uso** de funcionalidades avançadas

### **Technical Performance**
- **+35% FPS** na renderização de listas
- **-50% tempo** de carregamento inicial
- **+20% responsividade** em dispositivos variados

---

**Próxima Revisão:** Após implementação da Fase 1  
**Responsável:** Equipe Frontend Flutter  
**Prioridade:** Alta (impacto direto na conversão) 