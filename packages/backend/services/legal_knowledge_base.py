#!/usr/bin/env python3
"""
Base de Conhecimento Jurídica Brasileira Expandida
==================================================

Módulo para criar documentos jurídicos abrangentes cobrindo
todas as áreas do Direito brasileiro para o sistema RAG.
"""

def create_comprehensive_legal_documents():
    """
    Cria documentos jurídicos abrangentes para todas as áreas do Direito brasileiro.
    Baseado na taxonomia jurídica fornecida pelo usuário.
    """
    
    documents_data = []
    
    # =================================================================
    # DIREITO CONSTITUCIONAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **CONSTITUIÇÃO FEDERAL DE 1988 - PRINCÍPIOS FUNDAMENTAIS E DIREITOS**

            **FUNDAMENTOS DA REPÚBLICA (Art. 1º):**
            I - a soberania
            II - a cidadania  
            III - a dignidade da pessoa humana
            IV - os valores sociais do trabalho e da livre iniciativa
            V - o pluralismo político

            **DIREITOS E GARANTIAS FUNDAMENTAIS (Art. 5º):**
            - Princípio da igualdade: todos são iguais perante a lei
            - Princípio da legalidade: ninguém será obrigado a fazer ou deixar de fazer algo senão em virtude de lei
            - Direito à vida, liberdade, igualdade, segurança e propriedade
            - Devido processo legal, contraditório e ampla defesa
            - Presunção de inocência
            - Inviolabilidade da casa, correspondência e comunicações

            **CONTROLE DE CONSTITUCIONALIDADE:**
            - ADI (Ação Direta de Inconstitucionalidade)
            - ADECON (Ação Declaratória de Constitucionalidade)  
            - ADPF (Arguição de Descumprimento de Preceito Fundamental)
            - Supremo Tribunal Federal como guardião da Constituição
            """,
            "metadata": {"source": "CF88", "type": "constituicao", "area": "constitucional", "year": 1988}
        },
        
        {
            "content": """
            **ORGANIZAÇÃO DOS PODERES E SISTEMA POLÍTICO**

            **PODER LEGISLATIVO:**
            - Congresso Nacional: Câmara dos Deputados e Senado Federal
            - Função de legislar e fiscalizar
            - Processo legislativo: PEC, PL, MP

            **PODER EXECUTIVO:**
            - Presidente da República: Chefe de Estado e Governo
            - Ministros de Estado e administração federal
            - Sistema presidencialista

            **PODER JUDICIÁRIO:**
            - STF, STJ, TST, TSE, STM
            - Tribunais Regionais e Estaduais
            - Princípio da independência e harmonia entre poderes

            **FEDERALISMO:**
            - União, Estados, Distrito Federal e Municípios
            - Autonomia política, administrativa e financeira
            - Repartição de competências
            """,
            "metadata": {"source": "CF88", "type": "constituicao", "area": "constitucional_politico", "year": 1988}
        }
    ])
    
    # =================================================================
    # DIREITO ADMINISTRATIVO
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **DIREITO ADMINISTRATIVO - PRINCÍPIOS E ATOS**

            **PRINCÍPIOS DA ADMINISTRAÇÃO PÚBLICA (Art. 37 CF):**
            - LEGALIDADE: administração sujeita estritamente à lei
            - IMPESSOALIDADE: tratamento igual, sem favorecimento
            - MORALIDADE: ética e probidade administrativa
            - PUBLICIDADE: transparência dos atos públicos
            - EFICIÊNCIA: otimização de resultados

            **ATOS ADMINISTRATIVOS:**
            - Características: presunção de legitimidade, imperatividade, autoexecutoriedade
            - Elementos: competência, finalidade, forma, motivo, objeto
            - Atributos e vícios dos atos administrativos

            **LICITAÇÕES (Lei 14.133/2021):**
            - Modalidades: pregão, concorrência, tomada de preços, convite
            - Princípios: competitividade, isonomia, legalidade, publicidade
            - Fases: planejamento, seleção do fornecedor, gestão contratual

            **IMPROBIDADE ADMINISTRATIVA (Lei 8.429/92):**
            - Enriquecimento ilícito, lesão ao erário, violação de princípios
            - Sanções: perda de bens, ressarcimento, proibição de contratar
            """,
            "metadata": {"source": "Lei 14.133/2021, CF88", "type": "legislacao", "area": "administrativo", "year": 2021}
        }
    ])
    
    # =================================================================
    # DIREITO TRIBUTÁRIO
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **SISTEMA TRIBUTÁRIO NACIONAL**

            **CÓDIGO TRIBUTÁRIO NACIONAL (Lei 5.172/66):**
            - Tributo: prestação pecuniária compulsória em moeda
            - Espécies: impostos, taxas, contribuições de melhoria

            **PRINCÍPIOS TRIBUTÁRIOS:**
            - LEGALIDADE: tributo somente por lei (Art. 150, I CF)
            - ANTERIORIDADE: cobrança no exercício seguinte
            - IRRETROATIVIDADE: lei tributária não retroage
            - CAPACIDADE CONTRIBUTIVA: tributo conforme riqueza

            **IMPOSTOS FEDERAIS:**
            - IR (Imposto de Renda): pessoa física e jurídica
            - IPI (Produtos Industrializados): seletividade
            - IOF (Operações Financeiras): regulação econômica

            **IMPOSTOS ESTADUAIS:**
            - ICMS (Circulação de Mercadorias): não-cumulatividade
            - IPVA (Propriedade de Veículos): anual

            **IMPOSTOS MUNICIPAIS:**
            - IPTU (Predial e Territorial Urbano): progressividade
            - ISS (Sobre Serviços): alíquota mínima
            
            **OBRIGAÇÃO TRIBUTÁRIA:**
            - Fato gerador, sujeito ativo e passivo
            - Lançamento, constituição do crédito
            - Execução fiscal (Lei 6.830/80)
            """,
            "metadata": {"source": "CTN, CF88", "type": "legislacao", "area": "tributario", "year": 1966}
        }
    ])
    
    # =================================================================
    # DIREITO PENAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **CÓDIGO PENAL BRASILEIRO - PARTE GERAL**

            **APLICAÇÃO DA LEI PENAL:**
            - Princípio da legalidade: nullum crimen sine lege
            - Anterioridade: lei penal não retroage (salvo para beneficiar)
            - Tempo e lugar do crime: teoria da atividade

            **TEORIA DO CRIME:**
            - FATO TÍPICO: conduta, resultado, nexo causal, tipicidade
            - ANTIJURIDICIDADE: contrariedade ao direito
            - CULPABILIDADE: imputabilidade, potencial consciência, exigibilidade

            **EXCLUDENTES DE ILICITUDE:**
            - Estado de necessidade (Art. 24)
            - Legítima defesa (Art. 25)  
            - Estrito cumprimento de dever legal (Art. 23)
            - Exercício regular de direito (Art. 23)

            **CRIMES CONTRA A PESSOA:**
            - HOMICÍDIO (Art. 121): simples, privilegiado, qualificado
            - LESÃO CORPORAL (Art. 129): leve, grave, gravíssima
            - CRIMES CONTRA A HONRA: calúnia, difamação, injúria

            **PENAS:**
            - Privativas de liberdade: reclusão e detenção
            - Restritivas de direitos: prestação de serviços, limitação
            - Multa: dias-multa conforme situação econômica
            """,
            "metadata": {"source": "CP", "type": "codigo", "area": "penal", "year": 1940}
        }
    ])
    
    # =================================================================
    # DIREITO PROCESSUAL PENAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **PROCESSO PENAL BRASILEIRO**

            **PRINCÍPIOS PROCESSUAIS PENAIS:**
            - Devido processo legal, contraditório e ampla defesa
            - Presunção de inocência (Art. 5º, LVII CF)
            - Vedação de provas ilícitas
            - Publicidade, oralidade, concentração

            **INQUÉRITO POLICIAL:**
            - Procedimento administrativo investigativo
            - Autoridade policial, prazo de 10/30 dias
            - Indiciamento, oitivas, diligências

            **PRISÕES:**
            - PRISÃO EM FLAGRANTE: situação flagrancial
            - PRISÃO PREVENTIVA: garantia da ordem pública/econômica
            - PRISÃO TEMPORÁRIA: Lei 7.960/89
            - Audiência de custódia: 24 horas

            **HABEAS CORPUS:**
            - Remédio contra violência ou coação ilegal
            - Preventivo e liberatório
            - Competência do tribunal

            **JÚRI (Art. 5º, XXXVIII CF):**
            - Crimes dolosos contra a vida
            - Plenitude de defesa, sigilo das votações
            - Soberania dos veredictos
            """,
            "metadata": {"source": "CPP", "type": "codigo", "area": "processual_penal", "year": 1941}
        }
    ])
    
    # =================================================================
    # DIREITO DO TRABALHO
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **CONSOLIDAÇÃO DAS LEIS DO TRABALHO (CLT)**

            **RELAÇÃO DE EMPREGO:**
            - EMPREGADO: pessoa física, pessoalidade, não-eventualidade, subordinação, onerosidade
            - EMPREGADOR: assume riscos da atividade econômica
            - Contrato individual de trabalho: acordo tácito ou expresso

            **JORNADA DE TRABALHO:**
            - Duração normal: 8 horas diárias, 44 semanais
            - Horas extras: adicional mínimo 50%
            - Adicional noturno: 20% (22h às 5h)
            - Intervalo intrajornada: 1 a 2 horas
            - Descanso semanal remunerado: 24 horas

            **DIREITOS TRABALHISTAS:**
            - SALÁRIO MÍNIMO: remuneração mínima nacional
            - 13º SALÁRIO: gratificação natalina integral
            - FÉRIAS: 30 dias após 12 meses + 1/3 constitucional
            - FGTS: 8% do salário mensalmente

            **RESCISÃO CONTRATUAL:**
            - Aviso prévio: 30 dias + 3 dias por ano
            - Justa causa: art. 482 CLT
            - Despedida sem justa causa: multa 40% FGTS
            - Seguro-desemprego: 3 a 5 parcelas

            **JUSTIÇA DO TRABALHO:**
            - Competência: conflitos trabalhistas
            - Procedimento: reclamação trabalhista
            - Execução: satisfação do crédito trabalhista
            """,
            "metadata": {"source": "CLT", "type": "legislacao", "area": "trabalho", "year": 1943}
        }
    ])
    
    # =================================================================
    # DIREITO PREVIDENCIÁRIO
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **PREVIDÊNCIA SOCIAL (Lei 8.213/91)**

            **REGIME GERAL DE PREVIDÊNCIA SOCIAL:**
            - INSS: autarquia federal previdenciária
            - Caráter contributivo e compulsório
            - Filiação obrigatória para trabalhadores

            **SEGURADOS:**
            - OBRIGATÓRIOS: empregado, empregado doméstico, contribuinte individual, trabalhador avulso, segurado especial
            - FACULTATIVOS: maiores de 16 anos sem atividade remunerada

            **BENEFÍCIOS PREVIDENCIÁRIOS:**
            - APOSENTADORIA POR IDADE: 65 anos (homem), 62 anos (mulher)
            - APOSENTADORIA POR TEMPO DE CONTRIBUIÇÃO: 35/30 anos
            - APOSENTADORIA POR INVALIDEZ: incapacidade permanente
            - AUXÍLIO-DOENÇA: incapacidade temporária superior a 15 dias
            - SALÁRIO-MATERNIDADE: 120 dias
            - PENSÃO POR MORTE: dependentes do segurado

            **CÁLCULO DOS BENEFÍCIOS:**
            - Salário-de-benefício: média das contribuições
            - Fator previdenciário: idade, expectativa de vida, tempo de contribuição
            - Carência: período mínimo de contribuição
            """,
            "metadata": {"source": "Lei 8.213/91", "type": "legislacao", "area": "previdenciario", "year": 1991}
        }
    ])
    
    # =================================================================
    # DIREITO DO CONSUMIDOR
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **CÓDIGO DE DEFESA DO CONSUMIDOR (Lei 8.078/90)**

            **RELAÇÃO DE CONSUMO:**
            - CONSUMIDOR: destinatário final de produto ou serviço
            - FORNECEDOR: quem desenvolve atividade de produção/distribuição
            - PRODUTO: bem móvel ou imóvel, material ou imaterial
            - SERVIÇO: atividade fornecida no mercado mediante remuneração

            **DIREITOS BÁSICOS DO CONSUMIDOR:**
            - Proteção da vida, saúde e segurança
            - Educação e divulgação sobre consumo adequado
            - Informação adequada e clara sobre produtos/serviços
            - Proteção contra publicidade enganosa e abusiva
            - Modificação de cláusulas contratuais desproporcionais
            - Inversão do ônus da prova

            **RESPONSABILIDADE CIVIL:**
            - RESPONSABILIDADE OBJETIVA: independe de culpa
            - Vício do produto/serviço: inadequação para consumo
            - Fato do produto/serviço: acidentes de consumo
            - Garantia legal: 30 dias (não duráveis), 90 dias (duráveis)

            **PRÁTICAS ABUSIVAS:**
            - Venda casada, cobrança abusiva
            - Aproveitamento da fraqueza ou ignorância do consumidor
            - Publicidade enganosa ou abusiva
            """,
            "metadata": {"source": "CDC", "type": "legislacao", "area": "consumidor", "year": 1990}
        }
    ])
    
    # =================================================================
    # DIREITO DIGITAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **MARCO CIVIL DA INTERNET E LGPD**

            **MARCO CIVIL DA INTERNET (Lei 12.965/14):**
            - Neutralidade da rede: tratamento isonômico de dados
            - Privacidade e proteção dos dados pessoais
            - Liberdade de expressão e direito à informação
            - Responsabilidade civil dos provedores

            **LEI GERAL DE PROTEÇÃO DE DADOS (Lei 13.709/18):**
            - DADOS PESSOAIS: informação relacionada a pessoa identificada/identificável
            - TRATAMENTO: operação com dados pessoais
            - CONTROLADOR: quem toma decisões sobre tratamento
            - OPERADOR: quem realiza tratamento em nome do controlador

            **BASES LEGAIS PARA TRATAMENTO:**
            - Consentimento do titular
            - Cumprimento de obrigação legal
            - Execução de políticas públicas
            - Proteção da vida ou incolumidade física
            - Tutela da saúde
            - Interesse legítimo do controlador

            **DIREITOS DO TITULAR:**
            - Confirmação da existência de tratamento
            - Acesso aos dados pessoais
            - Correção de dados incompletos/incorretos
            - Anonimização, bloqueio ou eliminação
            - Portabilidade dos dados
            - Eliminação dos dados tratados com consentimento

            **AUTORIDADE NACIONAL (ANPD):**
            - Fiscalização e aplicação da LGPD
            - Elaboração de diretrizes e normas
            - Aplicação de sanções administrativas
            """,
            "metadata": {"source": "Lei 12.965/14, Lei 13.709/18", "type": "legislacao", "area": "digital", "year": 2018}
        }
    ])
    
    # =================================================================
    # DIREITO AMBIENTAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **DIREITO AMBIENTAL BRASILEIRO**

            **PRINCÍPIOS AMBIENTAIS:**
            - Desenvolvimento sustentável
            - Prevenção e precaução
            - Poluidor-pagador e usuário-pagador
            - Responsabilidade solidária

            **POLÍTICA NACIONAL DO MEIO AMBIENTE (Lei 6.938/81):**
            - SISNAMA: Sistema Nacional do Meio Ambiente
            - Instrumentos: licenciamento, EIA-RIMA, zoneamento
            - CONAMA: Conselho Nacional do Meio Ambiente

            **LICENCIAMENTO AMBIENTAL:**
            - Licença Prévia (LP): viabilidade ambiental
            - Licença de Instalação (LI): início da implantação
            - Licença de Operação (LO): funcionamento do empreendimento

            **SISTEMA NACIONAL DE UNIDADES DE CONSERVAÇÃO (SNUC):**
            - Proteção integral: não permite uso direto dos recursos
            - Uso sustentável: compatibiliza conservação com uso
            - Criação por lei ou decreto

            **RESPONSABILIDADE AMBIENTAL:**
            - Tríplice responsabilização: civil, penal e administrativa
            - Responsabilidade civil objetiva (Art. 14, §1º Lei 6.938/81)
            - Crimes ambientais (Lei 9.605/98)

            **ÁREAS DE PRESERVAÇÃO PERMANENTE (APP):**
            - Faixas marginais de cursos d'água
            - Encostas com declividade superior a 45°
            - Topos de morros e montanhas
            """,
            "metadata": {"source": "Lei 6.938/81, Lei 9.605/98", "type": "legislacao", "area": "ambiental", "year": 1981}
        }
    ])
    
    # =================================================================
    # DIREITO ELEITORAL
    # =================================================================
    
    documents_data.extend([
        {
            "content": """
            **DIREITO ELEITORAL BRASILEIRO**

            **CÓDIGO ELEITORAL (Lei 4.737/65):**
            - Justiça Eleitoral: TSE, TREs, Juízes Eleitorais
            - Alistamento eleitoral: obrigatório dos 18 aos 70 anos
            - Organização das eleições

            **PARTIDOS POLÍTICOS (Lei 9.096/95):**
            - Caráter nacional, livre criação e organização
            - Autonomia partidária
            - Funcionamento parlamentar
            - Fundo partidário

            **ELEIÇÕES:**
            - Sistema proporcional: vereadores e deputados
            - Sistema majoritário: prefeitos, governadores, presidente
            - Segundo turno: cargos executivos em municípios >200 mil

            **PROPAGANDA ELEITORAL:**
            - Período permitido: 45 dias antes das eleições
            - Horário eleitoral gratuito: rádio e TV
            - Vedações: abuso de poder, uso da máquina pública

            **CRIMES ELEITORAIS:**
            - Corrupção eleitoral: compra de votos
            - Abuso de poder político e econômico
            - Propaganda irregular
            - Falsidade eleitoral

            **FINANCIAMENTO DE CAMPANHAS:**
            - Recursos próprios dos candidatos
            - Doações de pessoas físicas
            - Fundo especial de financiamento de campanha
            """,
            "metadata": {"source": "Lei 4.737/65, Lei 9.096/95", "type": "legislacao", "area": "eleitoral", "year": 1965}
        }
    ])
    
    return documents_data


def get_legal_area_weights():
    """
    Retorna os pesos das áreas jurídicas para detecção inteligente.
    """
    return {
        'Constitucional': [
            ('constituição', 10), ('supremo tribunal federal', 8), ('direitos fundamentais', 8),
            ('controle de constitucionalidade', 7), ('poder constituinte', 5), ('adi', 5), ('adpf', 5),
            ('mandado de segurança coletivo', 6), ('art 5', 4), ('emenda constitucional', 6)
        ],
        'Administrativo': [
            ('ato administrativo', 10), ('licitação', 9), ('servidor público', 8), ('improbidade administrativa', 8),
            ('concessão de serviço público', 6), ('poder de polícia', 5), ('agente público', 5),
            ('processo administrativo', 7), ('princípio da legalidade', 6), ('discricionariedade', 5)
        ],
        'Tributário': [
            ('tributo', 10), ('crédito tributário', 9), ('imposto de renda', 8), ('lançamento tributário', 7),
            ('icms', 6), ('obrigação tributária', 5), ('iss', 6), ('ctn', 7), ('execução fiscal', 6),
            ('cofins', 5), ('pis', 5), ('contribuição social', 6)
        ],
        'Penal': [
            ('crime', 10), ('pena', 9), ('dosimetria da pena', 7), ('culpabilidade', 6),
            ('tipicidade', 6), ('homicídio', 5), ('roubo', 5), ('furto', 5), ('estelionato', 5),
            ('código penal', 8), ('legítima defesa', 6), ('estado de necessidade', 5)
        ],
        'Trabalho': [
            ('contrato de trabalho', 10), ('relação de emprego', 9), ('clt', 8), ('empregado', 7),
            ('empregador', 7), ('justiça do trabalho', 5), ('fgts', 6), ('aviso prévio', 6),
            ('jornada de trabalho', 7), ('adicional noturno', 5), ('hora extra', 6)
        ],
        'Previdenciário': [
            ('previdência social', 10), ('aposentadoria', 9), ('benefício previdenciário', 8),
            ('inss', 7), ('regime geral', 6), ('auxílio-doença', 6), ('pensão por morte', 5),
            ('contribuição previdenciária', 7)
        ],
        'Consumidor': [
            ('código de defesa do consumidor', 10), ('cdc', 9), ('relação de consumo', 8),
            ('fornecedor', 7), ('consumidor', 7), ('vício do produto', 6), ('propaganda enganosa', 6),
            ('procon', 6), ('recall', 5)
        ],
        'Digital': [
            ('marco civil da internet', 10), ('lgpd', 9), ('proteção de dados pessoais', 8),
            ('crimes cibernéticos', 7), ('comércio eletrônico', 6), ('assinatura digital', 5)
        ],
        'Ambiental': [
            ('meio ambiente', 10), ('licenciamento ambiental', 9), ('poluição', 7),
            ('área de preservação permanente', 6), ('dano ambiental', 8), ('snuc', 6),
            ('responsabilidade ambiental', 7), ('eia-rima', 5)
        ],
        'Eleitoral': [
            ('eleição', 10), ('tse', 9), ('campanha eleitoral', 8), ('voto', 7), ('candidato', 6),
            ('propaganda eleitoral', 7), ('financiamento de campanha', 6), ('código eleitoral', 8)
        ]
    }
