# backend/services/catalog_mock.py
"""
Módulo de mock para fornecer o catálogo de áreas e subáreas jurídicas
em ambientes de teste ou quando o banco de dados não está acessível.
Isso desacopla a lógica de triagem da dependência direta do banco de dados
durante o desenvolvimento e teste dos prompts.
"""

def get_mock_catalog():
    """
    Retorna um dicionário estruturado representando o catálogo completo
    de áreas e subáreas jurídicas do sistema LITIG-1.
    Este mock deve ser mantido em sincronia com a migração:
    20250119000000_add_area_juridica_enum.sql
    """
    return {
        "Trabalhista": [
            "Rescisão", "Justa Causa", "Verbas Rescisórias", "Assédio Moral",
            "Acidente de Trabalho", "Horas Extras"
        ],
        "Criminal": [
            "Crimes Patrimoniais", "Crimes contra a Vida", "Crimes de Trânsito",
            "Tráfico", "Crimes Digitais"
        ],
        "Civil": [
            "Contratos", "Responsabilidade Civil", "Obrigações", "Sucessões",
            "Direitos Reais", "Arbitragem Cível e Contratual", 
            "Mediação e Conciliação Cível", "Execução de Sentença Arbitral",
            "Dispute Boards em Contratos"
        ],
        "Família": [
            "Divórcio", "Alimentos", "Guarda", "Adoção", "União Estável"
        ],
        "Empresarial": [
            "Societário", "Contratos Comerciais", "Títulos de Crédito",
            "Falência e Recuperação", "Arbitragem Societária e M&A",
            "Mediação Empresarial", "Comitês de Resolução de Disputas"
        ],
        "Tributário": [
            "Planejamento Tributário", "Contencioso Fiscal", "Tributos em Espécie",
            "Transação Tributária", "Arbitragem Tributária", "Mediação Fiscal"
        ],
        "Administrativo": [
            "Servidor Público", "Licitações e Contratos Públicos", "Improbidade Administrativa",
            "Arbitragem com a Administração Pública", "Mediação em Conflitos Públicos",
            "Câmaras de Resolução de Conflitos"
        ],
        "Regulatório": [
            "Setor Elétrico", "Telecomunicações", "Saúde Suplementar",
            "Arbitragem Setorial", "Painéis de Resolução de Disputas",
            "Mediação com Agências Reguladoras"
        ],
        "Consumidor": [
            "Garantia", "Cobrança Indevida", "Vício do Produto", "Vício do Serviço",
            "Propaganda Enganosa", "Propaganda Abusiva", "Banco de Dados",
            "Planos de Saúde", "Telecomunicações", "Serviços Bancários",
            "Superendividamento", "E-commerce Consumidor", "Serviços Públicos",
            "Seguro", "Transporte", "Alimentação", "Educação", "Turismo",
            "Automóveis", "Imóveis", "Cartões de Crédito", "Financiamentos",
            "Erro Médico", "Serviços Médicos", "Tratamentos Estéticos"
        ],
        "Digital": [
            "LGPD", "Crimes Digitais", "E-commerce", "Redes Sociais", "Propriedade Digital",
            "Marco Civil da Internet", "Direito de Imagem Digital", "Contratos Digitais",
            "Cibersegurança", "Criptomoedas", "Direito ao Esquecimento", "Fake News",
            "Cyberbullying", "Pirataria Digital", "Jogos Online"
        ],
        "Startups": [
            "Investimentos e Venture Capital", "Estruturação Societária",
            "Contratos de Investment", "Equity e Stock Options", "Propriedade Intelectual Tech",
            "Marco Legal das Startups", "Compliance e Regulatório", "Contratos de Aceleração",
            "Due Diligence Tech", "Crowdfunding", "Parcerias Estratégicas", "Tributário Startups",
            "Trabalhista Tech", "Contratos Tecnológicos", "Exit Strategy", "Corporate Governance",
            "ESG e Sustentabilidade", "International Expansion", "Fintech Regulation", "Healthtech Regulation"
        ],
        # Adicione outras áreas principais aqui conforme o enum
        "Imobiliário": ["Locação", "Compra e Venda", "Usucapião", "Condomínio"],
        "Ambiental": ["Licenciamento", "Crimes Ambientais", "Resíduos Sólidos"],
        "Bancário": ["Juros Abusivos", "Negativação Indevida", "Contratos Bancários"],
        "Saúde": ["Plano de Saúde", "Erro Médico", "SUS", "Medicamentos"],
        "Propriedade Intelectual": ["Marcas", "Patentes", "Direito Autoral"]
    } 
 