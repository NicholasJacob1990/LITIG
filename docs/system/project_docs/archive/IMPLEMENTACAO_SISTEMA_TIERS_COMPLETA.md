# Sistema de Tiers de Advogados - Implementação Completa

## Visão Geral

Implementamos um **Sistema de Tiers Híbrido** que combina valores padronizados por nível de experiência com flexibilidade para ajustes por caso específico.

## Arquitetura Implementada

### 1. Banco de Dados

#### Tabela `lawyer_tiers`
```sql
- id: UUID (PK)
- tier_name: VARCHAR(50) UNIQUE ('junior', 'pleno', 'senior', 'especialista')
- display_name: VARCHAR(100) ('Advogado Júnior', etc.)
- description: TEXT
- consultation_fee: DECIMAL(10,2)
- hourly_rate: DECIMAL(10,2)
- min_experience_years: INTEGER
- max_experience_years: INTEGER (nullable)
```

#### Atualização na tabela `lawyers`
```sql
- tier_id: UUID (FK para lawyer_tiers)
```

### 2. Tiers Padrão Criados

| Tier | Display Name | Consulta | Hora | Experiência |
|------|-------------|----------|------|-------------|
| `junior` | Advogado Júnior | R$ 150 | R$ 200 | 0-3 anos |
| `pleno` | Advogado Pleno | R$ 300 | R$ 400 | 4-10 anos |
| `senior` | Advogado Sênior | R$ 500 | R$ 600 | 11+ anos |
| `especialista` | Advogado Especialista | R$ 800 | R$ 1000 | 8+ anos* |

*Especialistas podem ter menos tempo mas alta especialização

### 3. Funcionalidades do Sistema

#### Atribuição Automática de Tier
- Trigger automático baseado na experiência do advogado
- Função `update_lawyer_tier_by_experience()`

#### Busca por Tier
- Função `get_lawyers_by_tier(p_tier_names TEXT[])`
- Permite filtrar advogados por múltiplos tiers

#### Valores Padrão
- Função `get_tier_default_fees(p_tier_id UUID)`
- Retorna valores padrão para pré-preenchimento

## Frontend Implementado

### 1. Tela de Advogados (`advogados.tsx`)

#### Filtros por Tier
- Substituiu os filtros por valor monetário
- Interface com cards visuais para cada tier
- Mostra faixa de preços e descrição de cada nível
- Seleção múltipla de tiers

```typescript
// Estados para filtros por tier
const [selectedTiers, setSelectedTiers] = useState<string[]>([]);

// Integração com hook useLawyers
const { data: fetchedLawyers } = useLawyers({
  // ... outros filtros
  tiers: selectedTiers,
});
```

### 2. Tela de Ajuste de Honorários (`AdjustFees.tsx`)

#### Modelo Híbrido Implementado
- **Valores pré-preenchidos** com base no tier do advogado
- **Editáveis** para personalização por caso
- **Indicação visual** dos valores padrão do tier
- **Botão de reset** para voltar aos valores padrão

#### Funcionalidades
```typescript
// Carrega tier do advogado e valores padrão
const loadCaseAndTierData = async () => {
  const tier = await getLawyerTier(caseData.lawyer_id);
  const defaults = await getTierDefaultFees(tier.id);
  
  // Pré-preenche com valores padrão se não existirem valores customizados
  if (!caseData.consultation_fee) {
    setConsultationFee(String(defaults.consultation_fee));
  }
};

// Permite reset para valores padrão
const resetToTierDefaults = () => {
  setConsultationFee(String(tierDefaults.consultation_fee));
  setHourlyRate(String(tierDefaults.hourly_rate));
  // ...
};
```

### 3. Serviços e Hooks

#### Serviço de Tiers (`lib/services/tiers.ts`)
- `getAllTiers()`: Busca todos os tiers
- `getTierDefaultFees()`: Valores padrão de um tier
- `getLawyersByTiers()`: Advogados por tier
- `getLawyerTier()`: Tier de um advogado específico
- `updateLawyerTier()`: Atualiza tier de um advogado

#### Hook de Tiers (`lib/hooks/useTiers.ts`)
- `useTiers()`: Lista todos os tiers
- `useLawyerTier()`: Tier de um advogado
- `useTierDefaults()`: Valores padrão de um tier
- `useLawyerTierInfo()`: Informações completas (tier + defaults)

#### Atualização do Hook de Advogados (`lib/hooks/useLawyers.ts`)
```typescript
interface LawyerFilters {
  // ... outros filtros
  tiers?: string[]; // Novo filtro por tiers
}
```

## Fluxo de Uso

### 1. Para o Cliente (Busca de Advogados)
1. **Acessa tela "Advogados"**
2. **Aplica filtros** incluindo seleção de tiers desejados
3. **Visualiza advogados** filtrados por nível e outros critérios
4. **Vê informações** de tier e faixa de preços de cada advogado

### 2. Para o Advogado (Ajuste de Honorários)
1. **Acessa caso atribuído**
2. **Vai para "Ajustar Honorários"**
3. **Vê valores pré-preenchidos** baseados no seu tier
4. **Pode editar valores** para personalizar proposta
5. **Pode resetar** para valores padrão do tier a qualquer momento

### 3. Atribuição Automática de Tier
1. **Advogado se cadastra** ou atualiza experiência
2. **Sistema calcula tier automaticamente** via trigger
3. **Tier pode ser ajustado manualmente** se necessário

## Benefícios do Sistema

### 1. **Padronização**
- Valores consistentes por nível de experiência
- Expectativas claras para clientes
- Estrutura organizada de preços

### 2. **Flexibilidade**
- Advogados podem ajustar valores por caso
- Permite propostas personalizadas
- Mantém autonomia profissional

### 3. **Transparência**
- Clientes sabem faixa de preços por nível
- Critérios claros para cada tier
- Interface intuitiva para seleção

### 4. **Escalabilidade**
- Fácil adição de novos tiers
- Ajuste de valores padrão centralizado
- Sistema preparado para crescimento

## Próximos Passos Sugeridos

### 1. **Backend**
- [ ] Implementar endpoint para filtro por tiers
- [ ] Adicionar validações de tier no algoritmo de matching
- [ ] Criar relatórios de distribuição por tier

### 2. **Frontend**
- [ ] Adicionar indicador de tier nos cards de advogado
- [ ] Implementar tela de gerenciamento de tiers (admin)
- [ ] Adicionar estatísticas por tier no dashboard

### 3. **Melhorias**
- [ ] Sistema de promoção automática de tier
- [ ] Métricas de performance por tier
- [ ] Integração com sistema de reviews

## Estrutura de Arquivos

```
├── supabase/migrations/
│   └── 20250105000001_create_lawyer_tiers_table.sql
├── lib/
│   ├── services/
│   │   └── tiers.ts
│   └── hooks/
│       ├── useTiers.ts
│       └── useLawyers.ts (atualizado)
├── app/(tabs)/
│   ├── advogados.tsx (atualizado)
│   └── cases/
│       └── AdjustFees.tsx (atualizado)
└── IMPLEMENTACAO_SISTEMA_TIERS_COMPLETA.md
```

## Conclusão

O Sistema de Tiers foi implementado com sucesso, oferecendo:

✅ **Padronização** de valores por nível de experiência  
✅ **Flexibilidade** para ajustes por caso  
✅ **Interface intuitiva** para clientes e advogados  
✅ **Escalabilidade** para futuras expansões  
✅ **Transparência** nos critérios e preços  

O sistema está pronto para uso e pode ser facilmente expandido conforme as necessidades do negócio evoluem. 