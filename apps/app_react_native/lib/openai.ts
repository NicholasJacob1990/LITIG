const API_KEY = process.env.EXPO_PUBLIC_OPENAI_API_KEY;

// Tipos para as mensagens do ChatGPT
export interface ChatGPTMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

// Tipos para a resposta da IA
export type InteractionResponse = {
  isComplete: false;
  nextQuestion: string;
};

export type AnalysisResponse = {
  isComplete: true;
  analysis: any; // O schema JSON completo
};

type TriageResponse = InteractionResponse | AnalysisResponse;

// Tipos para análise de currículo
export interface CVAnalysisResult {
  personalInfo: {
    name: string;
    email?: string;
    phone?: string;
    address?: string;
    linkedin?: string;
    website?: string;
  };
  professionalSummary: string;
  education: Array<{
    degree: string;
    institution: string;
    year?: number;
    location?: string;
  }>;
  experience: Array<{
    position: string;
    company: string;
    startDate: string;
    endDate?: string;
    description: string;
    achievements?: string[];
  }>;
  skills: string[];
  certifications: Array<{
    name: string;
    issuer: string;
    year?: number;
  }>;
  languages: string[];
  practiceAreas: string[];
  oabNumber?: string;
  barAssociations: string[];
  awards: string[];
  publications: string[];
  totalExperience: number;
  specializationYears: Record<string, number>;
  consultationFee?: number;
  hourlyRate?: number;
  availabilitySchedule?: string;
  emergencyAvailability?: boolean;
  consultationMethods: string[];
}

export async function analyzeLawyerCV(cvText: string): Promise<CVAnalysisResult> {
  if (!API_KEY) {
    throw new Error("API key da OpenAI não configurada");
  }

  const systemMessage: ChatGPTMessage = {
    role: 'system',
    content: `
# PERSONA
Você é um especialista em análise de currículos jurídicos brasileiros, com conhecimento profundo sobre a carreira advocatícia no Brasil.

# TAREFA
Analisar o currículo fornecido e extrair informações estruturadas sobre o advogado para criar um perfil profissional completo.

# INSTRUÇÕES
1. Extraia todas as informações relevantes do currículo
2. Identifique áreas de especialização e anos de experiência em cada uma
3. Calcule o tempo total de experiência profissional
4. Identifique competências técnicas e soft skills
5. Extraia informações sobre formação acadêmica e certificações
6. Identifique publicações, prêmios e reconhecimentos
7. Determine métodos de consulta preferidos (se mencionado)
8. Estime valores de consulta baseado na experiência (se não informado)

# FORMATO DE RESPOSTA
Retorne APENAS um JSON válido seguindo exatamente esta estrutura:

{
  "personalInfo": {
    "name": "Nome completo extraído",
    "email": "email@exemplo.com ou null",
    "phone": "telefone ou null",
    "address": "endereço ou null", 
    "linkedin": "perfil linkedin ou null",
    "website": "site pessoal ou null"
  },
  "professionalSummary": "Resumo profissional em 2-3 frases",
  "education": [
    {
      "degree": "Título do curso",
      "institution": "Nome da instituição",
      "year": 2020,
      "location": "Cidade, UF"
    }
  ],
  "experience": [
    {
      "position": "Cargo",
      "company": "Nome da empresa/escritório",
      "startDate": "MM/YYYY",
      "endDate": "MM/YYYY ou null se atual",
      "description": "Descrição das atividades",
      "achievements": ["Conquista 1", "Conquista 2"]
    }
  ],
  "skills": ["Habilidade 1", "Habilidade 2"],
  "certifications": [
    {
      "name": "Nome da certificação",
      "issuer": "Instituição emissora",
      "year": 2021
    }
  ],
  "languages": ["Português", "Inglês"],
  "practiceAreas": ["Direito Civil", "Direito Trabalhista"],
  "oabNumber": "OAB/UF 123456 ou null",
  "barAssociations": ["OAB/SP", "IAB"],
  "awards": ["Prêmio 1", "Prêmio 2"],
  "publications": ["Artigo 1", "Livro 1"],
  "totalExperience": 8,
  "specializationYears": {
    "Direito Civil": 5,
    "Direito Trabalhista": 3
  },
  "consultationFee": 200,
  "hourlyRate": 400,
  "availabilitySchedule": "Segunda a sexta, 9h às 18h",
  "emergencyAvailability": false,
  "consultationMethods": ["presencial", "online", "telefone"]
}

# REGRAS IMPORTANTES
- Se uma informação não estiver disponível, use null
- Anos de experiência devem ser calculados com base nas datas
- Áreas de prática devem usar terminologia jurídica brasileira padrão
- Valores de consulta devem ser estimados baseado na experiência se não informados
- Sempre retorne JSON válido
- Não inclua comentários ou texto adicional
`
  };

  const userMessage: ChatGPTMessage = {
    role: 'user',
    content: `Analise este currículo e extraia as informações estruturadas:\n\n${cvText}`
  };

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [systemMessage, userMessage],
        temperature: 0.3,
        max_tokens: 4096,
        response_format: { type: "json_object" }
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    const responseText = data.choices[0].message.content;
    const analysisResult: CVAnalysisResult = JSON.parse(responseText);

    return analysisResult;
    
  } catch (error) {
    console.error("❌ ERRO na análise de CV:", error);
    throw new Error("Erro ao analisar currículo. Tente novamente.");
  }
}

export async function generateTriageAnalysis(
  history: ChatGPTMessage[]
): Promise<TriageResponse> {
  if (!API_KEY) {
    return {
      isComplete: false,
      nextQuestion: "A funcionalidade de IA está desativada. Por favor, contate o suporte.",
    };
  }

  const systemMessage: ChatGPTMessage = {
    role: 'system',
    content: `
# PERSONA
Você é o "LEX-9000", um assistente jurídico especializado em Direito Brasileiro. Sua função é conduzir uma triagem jurídica profissional para coletar informações essenciais sobre casos jurídicos e fornecer uma análise preliminar estruturada.

# ESPECIALIZAÇÃO
- Conhecimento profundo do ordenamento jurídico brasileiro
- Experiência em todas as áreas do direito (civil, trabalhista, criminal, administrativo, etc.)
- Capacidade de identificar urgência, complexidade e viabilidade processual
- Foco em aspectos práticos e estratégicos

# METODOLOGIA DE TRIAGEM
## FASE 1 - IDENTIFICAÇÃO INICIAL (1-2 perguntas)
- Área jurídica principal
- Natureza do problema (preventivo vs contencioso)
- Urgência temporal

## FASE 2 - DETALHAMENTO FACTUAL (2-6 perguntas)
- Partes envolvidas e suas qualificações
- Cronologia dos fatos relevantes
- Documentação disponível
- Valores envolvidos (quando aplicável)
- Tentativas de solução extrajudicial

## FASE 3 - ASPECTOS TÉCNICOS (0-4 perguntas)
- Prazos legais e prescrição
- Jurisdição competente
- Complexidade probatória
- Precedentes ou jurisprudência conhecida

**TOTAL: 3 a 10 perguntas adaptadas à complexidade do caso**

# PERGUNTAS INTELIGENTES
- Seja específico conforme a área identificada
- Adapte as perguntas ao tipo de caso (ex: trabalhista vs civil)
- Priorize informações que impactam viabilidade e estratégia
- Considere aspectos econômicos e temporais

# CRITÉRIOS PARA FINALIZAÇÃO
Termine a entrevista quando tiver informações suficientes sobre:
✅ Área jurídica e instituto específico
✅ Fatos essenciais e cronologia
✅ Partes e suas qualificações
✅ Urgência e prazos
✅ Viabilidade preliminar do caso
✅ Documentação disponível

# FORMATO DE RESPOSTA
- **DURANTE ENTREVISTA**: \`{ "isComplete": false, "nextQuestion": "Pergunta específica e direcionada" }\`
- **ANÁLISE FINAL**: \`{ "isComplete": true, "analysis": { ...schema_completo... } }\`

# SCHEMA DA ANÁLISE FINAL
\`\`\`json
{
  "classificacao": {
    "area_principal": "Ex: Direito Trabalhista",
    "assunto_principal": "Ex: Rescisão Indireta",
    "subarea": "Ex: Verbas Rescisórias",
    "natureza": "Preventivo|Contencioso"
  },
  "dados_extraidos": {
    "partes": [
      {
        "nome": "Nome da parte",
        "tipo": "Requerente|Requerido|Terceiro",
        "qualificacao": "Pessoa física/jurídica, profissão, etc."
      }
    ],
    "fatos_principais": [
      "Fato 1 em ordem cronológica",
      "Fato 2 em ordem cronológica"
    ],
    "pedidos": [
      "Pedido principal",
      "Pedidos secundários"
    ],
    "valor_causa": "R$ X.XXX,XX ou Inestimável",
    "documentos_mencionados": [
      "Documento 1",
      "Documento 2"
    ],
    "cronologia": "YYYY-MM-DD do fato inicial até hoje"
  },
  "analise_viabilidade": {
    "classificacao": "Viável|Parcialmente Viável|Inviável",
    "pontos_fortes": [
      "Ponto forte 1",
      "Ponto forte 2"
    ],
    "pontos_fracos": [
      "Ponto fraco 1",
      "Ponto fraco 2"
    ],
    "probabilidade_exito": "Alta|Média|Baixa",
    "justificativa": "Análise fundamentada da viabilidade",
    "complexidade": "Baixa|Média|Alta",
    "custos_estimados": "Baixo|Médio|Alto"
  },
  "urgencia": {
    "nivel": "Crítica|Alta|Média|Baixa",
    "motivo": "Justificativa da urgência",
    "prazo_limite": "Data limite ou N/A",
    "acoes_imediatas": [
      "Ação 1",
      "Ação 2"
    ]
  },
  "aspectos_tecnicos": {
    "legislacao_aplicavel": [
      "Lei X, art. Y",
      "Código Z, art. W"
    ],
    "jurisprudencia_relevante": [
      "STF/STJ Tema X",
      "Súmula Y"
    ],
    "competencia": "Justiça Federal/Estadual/Trabalhista",
    "foro": "Comarca/Seção específica",
    "alertas": [
      "Alerta sobre prescrição",
      "Alerta sobre documentação"
    ]
  },
  "recomendacoes": {
    "estrategia_sugerida": "Judicial|Extrajudicial|Negociação",
    "proximos_passos": [
      "Passo 1",
      "Passo 2"
    ],
    "documentos_necessarios": [
      "Documento essencial 1",
      "Documento essencial 2"
    ],
    "observacoes": "Observações importantes para o advogado"
  }
}
\`\`\`

# IMPORTANTE
- Mantenha linguagem profissional mas acessível
- Seja objetivo e prático nas perguntas
- Considere sempre o contexto brasileiro
- Faça de 3 a 10 perguntas conforme complexidade do caso
- Adapte perguntas conforme área jurídica identificada
`
  };

  try {
    const messages = [systemMessage, ...history];

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.7,
        max_tokens: 4096,
        response_format: { type: "json_object" }
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    const responseText = data.choices[0].message.content;
    const parsedResponse: TriageResponse = JSON.parse(responseText);

    return parsedResponse;
    
  } catch (error) {
    console.error("❌ ERRO DETALHADO DO OPENAI:", error);
    // Em caso de erro, retorna uma pergunta genérica para não quebrar o fluxo
    return {
      isComplete: false,
      nextQuestion: "Desculpe, tive um problema para processar. Pode reformular sua última resposta?"
    };
  }
}

/**
 * Nova função para integrar com o Pipeline de Triagem Híbrida do backend
 * Envia transcrição completa para análise usando a estratégia apropriada
 */
export async function runHybridTriageAnalysis(
  transcription: string,
  userId: string
): Promise<{
  success: boolean;
  caseId?: string;
  error?: string;
  strategy?: 'simple' | 'failover' | 'ensemble';
}> {
  try {
    const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8080';
    
    const response = await fetch(`${API_BASE_URL}/triage/full-flow`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        transcription,
        user_id: userId
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || `HTTP ${response.status}`);
    }

    const result = await response.json();
    
    return {
      success: true,
      caseId: result.case_id,
      strategy: result.strategy_used
    };
    
  } catch (error) {
    console.error("❌ ERRO na análise híbrida:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : "Erro desconhecido"
    };
  }
}

/**
 * Função para verificar status de processamento de triagem
 */
export async function checkTriageStatus(caseId: string): Promise<{
  status: 'processing' | 'completed' | 'failed';
  progress?: number;
  result?: any;
}> {
  try {
    const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8080';
    
    const response = await fetch(`${API_BASE_URL}/triage/status/${caseId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    return await response.json();
    
  } catch (error) {
    console.error("❌ ERRO ao verificar status:", error);
    return {
      status: 'failed'
    };
  }
}

/**
 * Gera um vetor de embedding para um texto usando a API da OpenAI.
 *
 * @param text - O texto a ser transformado em embedding.
 * @returns Um array de números representando o vetor de embedding.
 */
export async function createEmbedding(text: string): Promise<number[]> {
  if (!API_KEY) {
    throw new Error("API key da OpenAI não configurada");
  }

  try {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small', // Modelo recomendado para custo/benefício
        input: text.replace(/\\n/g, ' '), // Limpa o texto
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error('OpenAI Embedding API error:', errorData);
      throw new Error(`OpenAI API error: ${response.status} - ${errorData.error?.message}`);
    }

    const data = await response.json();
    if (data.data && data.data.length > 0) {
      return data.data[0].embedding;
    } else {
      throw new Error('Nenhum embedding retornado pela API da OpenAI.');
    }
  } catch (error) {
    console.error("❌ ERRO ao gerar embedding:", error);
    throw new Error("Erro ao gerar embedding. Tente novamente.");
  }
} 