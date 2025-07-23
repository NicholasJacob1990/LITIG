# -*- coding: utf-8 -*-
"""
Pipeline Completa de Enriquecimento para Algoritmo de Ranqueamento
================================================================
Enriquece automaticamente TODAS as features avaliadas pelo algoritmo:
- S: QUALIS de periódicos
- T: Titulação acadêmica  
- E: Experiência prática
- M: Multidisciplinaridade
- C: Casos complexos
- P: Faixa de honorários
- R: Reputação profissional
- Q: Qualificação geral (consolidada)
"""

import asyncio
import json
import logging
import os
import re
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime

# Imports locais
try:
    from academic_prompt_templates import AcademicPromptTemplates
    from algoritmo_match import Lawyer, KPI, ProfessionalMaturityData
except ImportError:
    # Fallback para execução standalone
    import sys
    sys.path.append('..')
    from academic_prompt_templates import AcademicPromptTemplates
    from algoritmo_match import Lawyer, KPI, ProfessionalMaturityData

# Logger específico para enriquecimento
ENRICHMENT_LOGGER = logging.getLogger("enrichment.pipeline")


@dataclass
class EnrichmentResult:
    """Resultado estruturado do enriquecimento."""
    lawyer_id: str
    source: str  # "openai_deep_research" ou "perplexity"
    raw_report: str
    extracted_data: Dict[str, Any]
    success: bool
    error_msg: Optional[str] = None
    processing_time_sec: float = 0.0


class AdvancedPromptTemplates:
    """Templates de prompts expandidos para todas as features do algoritmo."""
    
    @staticmethod
    def deep_research_complete_profile(nome: str, cpf: str, area_caso: str) -> Dict[str, Any]:
        """Prompt completo para OpenAI Deep Research cobrindo todas as features."""
        return {
            "model": "o3-deep-research",
            "background": True,
            "input": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": f"""Elabore um relatório técnico detalhado sobre o(a) advogado(a) {nome}, CPF {cpf}, 
com base em seu currículo Lattes (via Escavador), publicações, experiências profissionais e fontes públicas.

OBJETIVO: Enriquecer variáveis de ranqueamento jurídico para algoritmo de matching.

DADOS A IDENTIFICAR:

1. **PUBLICAÇÕES ACADÊMICAS E QUALIS (Feature S)**
   - Liste TODOS os periódicos onde publicou
   - Inclua: nome, ISSN, classificação QUALIS CAPES atual, área, data
   - Foque especialmente em periódicos de Direito

2. **TITULAÇÃO ACADÊMICA (Feature T)**
   - Nível mais alto: especialização, mestrado, doutorado, pós-doc
   - Instituição, área específica, ano de conclusão
   - Cursos em andamento ou recentes

3. **EXPERIÊNCIA PRÁTICA JURÍDICA (Feature E)**
   - Atuação prática comprovada na área {area_caso}
   - Casos relevantes, processos, pareceres, consultorias
   - Experiência em escritórios, órgãos públicos, tribunais
   - Anos de experiência efetiva na área específica

4. **ATUAÇÃO MULTIDISCIPLINAR (Feature M)**
   - Colaborações com profissionais não-jurídicos
   - Coautorias com engenheiros, médicos, psicólogos, economistas
   - Projetos interdisciplinares
   - Formação complementar em outras áreas

5. **CASOS JURÍDICOS COMPLEXOS (Feature C)**
   - Temas jurídicos sofisticados: arbitragem, compliance, M&A
   - Litígios de alta complexidade
   - Precedentes ou casos paradigmáticos
   - Expertise em legislação especializada

6. **FAIXA DE HONORÁRIOS (Feature P)**
   - Referências públicas a valores cobrados
   - Política de preços mencionada
   - Comparação com mercado da região
   - Modalidades: fixo, por hora, êxito

7. **REPUTAÇÃO PROFISSIONAL (Feature R)**
   - Cargos na OAB (diretoria, comissões)
   - Prêmios e reconhecimentos
   - Rankings jurídicos (Análise Advocacia, Chambers, Legal 500)
   - Participação em eventos de destaque
   - Citações em mídia jurídica (Migalhas, Conjur)

8. **DADOS DE MATURIDADE PROFISSIONAL (Feature M)**
   - Rede profissional (LinkedIn, conexões)
   - Responsividade em comunicação
   - Tempo de resposta médio
   - Sinais de reputação (recomendações, endorsements)

INSTRUÇÕES:
- Responda em português brasileiro
- Use estrutura numerada conforme itens acima
- SEMPRE inclua fontes: URL, título, data, trecho relevante
- Seja técnico e preciso
- Se não encontrar informação, declare explicitamente "Não encontrado"
- Priorize fontes confiáveis: Escavador, Qualis CAPES, Google Scholar, Scielo

FORMATO: Relatório estruturado, baseado em evidências, pronto para parsing automatizado.

FONTES RECOMENDADAS: Escavador, portal.capes.gov.br, Google Scholar, Scielo, 
Jusbrasil, LinkedIn, Migalhas, Conjur, sites de tribunais, OAB."""
                        }
                    ]
                }
            ],
            "tools": [
                {"type": "web_search", "search_context_size": "large"},
                {"type": "code_interpreter", "container": {"type": "auto"}}
            ],
            "reasoning": {"summary": "auto"},
            "response_format": {"type": "text"},  # Texto estruturado é melhor para parsing
            "max_tool_calls": 5,  # Mais calls para busca abrangente
            "store": False
        }
    
    @staticmethod
    def perplexity_complete_profile(nome: str, cpf: str, area_caso: str) -> str:
        """Prompt completo para Perplexity API cobrindo todas as features."""
        return f"""Pesquise e elabore um relatório técnico sobre o advogado {nome}, CPF {cpf}, 
com base em fontes públicas confiáveis. Objetivo: coletar dados para algoritmo de ranqueamento jurídico.

RESPONDA EM PORTUGUÊS BRASILEIRO e organize por seções numeradas:

1. **PUBLICAÇÕES E QUALIS**
   - Periódicos onde publicou (nome, ISSN, Qualis, data)
   - Foco em revistas jurídicas e áreas correlatas

2. **TITULAÇÃO ACADÊMICA**
   - Maior nível: especialização/mestrado/doutorado
   - Instituição, área, ano de conclusão

3. **EXPERIÊNCIA PRÁTICA EM {area_caso.upper()}**
   - Atuação comprovada na área específica
   - Casos, processos, pareceres relevantes
   - Anos de experiência efetiva

4. **ATUAÇÃO MULTIDISCIPLINAR**
   - Colaborações com outras áreas profissionais
   - Projetos interdisciplinares
   - Formação complementar

5. **CASOS JURÍDICOS COMPLEXOS**
   - Temas sofisticados tratados
   - Especialização em legislação específica
   - Precedentes ou casos paradigmáticos

6. **INFORMAÇÕES SOBRE HONORÁRIOS**
   - Faixa de valores praticados
   - Modalidades de cobrança
   - Referências públicas de preços

7. **REPUTAÇÃO PROFISSIONAL**
   - Cargos na OAB, prêmios, rankings
   - Citações em mídia jurídica
   - Reconhecimentos profissionais

8. **MATURIDADE PROFISSIONAL**
   - Rede profissional (LinkedIn)
   - Responsividade, tempo de resposta
   - Sinais de reputação

INSTRUÇÕES:
- Use fontes confiáveis: Escavador, Qualis CAPES, Google Scholar, Scielo, Jusbrasil
- Inclua URLs e citações sempre que possível
- Se não encontrar informação, declare "Não encontrado"
- Seja objetivo e técnico

Resposta em formato de relatório estruturado."""


class EnrichmentDataParser:
    """Parser para extrair dados estruturados dos relatórios de enriquecimento."""
    
    @staticmethod
    def parse_qualis_publications(text: str) -> List[Dict[str, Any]]:
        """Extrai publicações e seus QUALIS do relatório."""
        publications = []
        
        # Padrões para detectar publicações
        patterns = [
            r'periódico[:\s]*([^,\n]+).*?qualis[:\s]*([A-C][1-4]?|B[1-5])',
            r'revista[:\s]*([^,\n]+).*?qualis[:\s]*([A-C][1-4]?|B[1-5])',
            r'journal[:\s]*([^,\n]+).*?qualis[:\s]*([A-C][1-4]?|B[1-5])',
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, text.lower())
            for match in matches:
                journal_name = match.group(1).strip()
                qualis_score = match.group(2).upper()
                
                # Converter Qualis para score numérico
                qualis_to_score = {
                    'A1': 1.0, 'A2': 0.8, 'A3': 0.7, 'A4': 0.6,
                    'B1': 0.5, 'B2': 0.4, 'B3': 0.3, 'B4': 0.2, 'B5': 0.1,
                    'C': 0.2
                }
                
                publications.append({
                    'journal': journal_name,
                    'qualis_level': qualis_score,
                    'score': qualis_to_score.get(qualis_score, 0.0),
                    'method': 'QUALIS'
                })
        
        return publications
    
    @staticmethod
    def parse_academic_degree(text: str) -> Dict[str, Any]:
        """Extrai titulação acadêmica mais alta."""
        degree_hierarchy = {'doutorado': 4, 'doutor': 4, 'phd': 4,
                           'mestrado': 3, 'mestre': 3, 'master': 3,
                           'especialização': 2, 'especialista': 2, 'mba': 2,
                           'graduação': 1, 'bacharel': 1}
        
        found_degrees = []
        for degree, level in degree_hierarchy.items():
            if degree in text.lower():
                found_degrees.append((degree, level))
        
        if found_degrees:
            # Pegar o mais alto nível
            highest = max(found_degrees, key=lambda x: x[1])
            return {
                'level': highest[0],
                'numeric_level': highest[1],
                'has_advanced_degree': highest[1] >= 3
            }
        
        return {'level': 'graduação', 'numeric_level': 1, 'has_advanced_degree': False}
    
    @staticmethod
    def parse_practical_experience(text: str, area_caso: str) -> Dict[str, Any]:
        """Extrai experiência prática na área específica."""
        area_lower = area_caso.lower()
        
        # Buscar menções à área específica
        area_mentions = len(re.findall(rf'\b{re.escape(area_lower)}\b', text.lower()))
        
        # Buscar anos de experiência
        exp_patterns = [
            r'(\d+)\s*anos?\s*de\s*experiência',
            r'experiência\s*de\s*(\d+)\s*anos?',
            r'atuando\s*há\s*(\d+)\s*anos?'
        ]
        
        years_found = []
        for pattern in exp_patterns:
            matches = re.findall(pattern, text.lower())
            years_found.extend([int(m) for m in matches])
        
        max_years = max(years_found) if years_found else 0
        
        # Detectar tipos de experiência
        practical_signals = {
            'processos': len(re.findall(r'\bprocessos?\b', text.lower())),
            'pareceres': len(re.findall(r'\bpareceres?\b', text.lower())),
            'consultorias': len(re.findall(r'\bconsultorias?\b', text.lower())),
            'escritorio': len(re.findall(r'\bescritório\b', text.lower())),
            'tribunal': len(re.findall(r'\btribunal\b', text.lower()))
        }
        
        total_signals = sum(practical_signals.values())
        
        return {
            'area_mentions': area_mentions,
            'estimated_years': max_years,
            'practical_signals': practical_signals,
            'experience_score': min(1.0, (area_mentions * 0.2 + total_signals * 0.1) / 5),
            'has_relevant_experience': area_mentions > 0 and total_signals > 2
        }
    
    @staticmethod
    def parse_multidisciplinary_work(text: str) -> Dict[str, Any]:
        """Extrai sinais de atuação multidisciplinar."""
        other_areas = [
            'engenharia', 'medicina', 'psicologia', 'economia', 'administração',
            'contabilidade', 'arquitetura', 'tecnologia', 'ambiental', 'saúde'
        ]
        
        collaborations = {}
        for area in other_areas:
            mentions = len(re.findall(rf'\b{area}\b', text.lower()))
            if mentions > 0:
                collaborations[area] = mentions
        
        # Buscar coautorias
        coauthor_signals = len(re.findall(r'\bcoautor\b|\bcoautoria\b|\binterdisciplinar\b', text.lower()))
        
        return {
            'other_areas_mentioned': collaborations,
            'total_collaborations': sum(collaborations.values()),
            'coauthor_signals': coauthor_signals,
            'multidisciplinary_score': min(1.0, (sum(collaborations.values()) + coauthor_signals) / 10),
            'is_multidisciplinary': len(collaborations) >= 2 or coauthor_signals > 0
        }
    
    @staticmethod
    def parse_complex_cases(text: str) -> Dict[str, Any]:
        """Extrai sinais de casos jurídicos complexos."""
        complex_themes = [
            'arbitragem', 'compliance', 'due diligence', 'fusões', 'aquisições',
            'propriedade intelectual', 'regulatório', 'antitruste', 'concorrência',
            'tributário complexo', 'internacional', 'corporate', 'securitização'
        ]
        
        found_themes = {}
        for theme in complex_themes:
            mentions = len(re.findall(rf'\b{theme}\b', text.lower()))
            if mentions > 0:
                found_themes[theme] = mentions
        
        # Buscar sinais de complexidade
        complexity_signals = len(re.findall(
            r'\bcomplexo\b|\bsofisticado\b|\bprecedente\b|\bparadigma\b|\binovador\b', 
            text.lower()
        ))
        
        return {
            'complex_themes': found_themes,
            'complexity_signals': complexity_signals,
            'complexity_score': min(1.0, (sum(found_themes.values()) + complexity_signals) / 8),
            'handles_complex_cases': len(found_themes) >= 2 or complexity_signals >= 3
        }
    
    @staticmethod
    def parse_fee_information(text: str) -> Dict[str, Any]:
        """Extrai informações sobre honorários."""
        # Buscar valores monetários
        money_patterns = [
            r'R\$\s*[\d.,]+',
            r'reais?\s*[\d.,]+',
            r'valor\s*de\s*R\$\s*[\d.,]+'
        ]
        
        found_values = []
        for pattern in money_patterns:
            matches = re.findall(pattern, text)
            found_values.extend(matches)
        
        # Buscar modalidades de cobrança
        fee_types = {
            'hora': len(re.findall(r'\bpor\s*hora\b|\bhora\b.*\bcobrança\b', text.lower())),
            'fixo': len(re.findall(r'\bfixo\b|\bvalor\s*fixo\b', text.lower())),
            'êxito': len(re.findall(r'\bêxito\b|\bquota\s*litis\b|\bsucesso\b', text.lower())),
            'percentual': len(re.findall(r'\bpercentual\b|\b%\b|\bporcento\b', text.lower()))
        }
        
        return {
            'monetary_values_found': found_values,
            'fee_types_mentioned': fee_types,
            'has_fee_info': len(found_values) > 0 or sum(fee_types.values()) > 0,
            'preferred_fee_type': max(fee_types.items(), key=lambda x: x[1])[0] if any(fee_types.values()) else None
        }
    
    @staticmethod
    def parse_professional_reputation(text: str) -> Dict[str, Any]:
        """Extrai sinais de reputação profissional."""
        # Rankings e premiações
        prestige_signals = {
            'oab_positions': len(re.findall(r'\boab\b.*\b(diretor|presidente|conselheiro)\b', text.lower())),
            'awards': len(re.findall(r'\bprêmio\b|\breconhecimento\b|\bhomenagem\b', text.lower())),
            'rankings': len(re.findall(r'\branking\b|\bchambers\b|\blegal\s*500\b|\banálise\s*advocacia\b', text.lower())),
            'media_mentions': len(re.findall(r'\bmigalhas\b|\bconjur\b|\bvalor\b|\bestado\b', text.lower())),
            'events': len(re.findall(r'\bpalestrante\b|\bconferência\b|\bseminário\b', text.lower()))
        }
        
        total_signals = sum(prestige_signals.values())
        
        return {
            'reputation_signals': prestige_signals,
            'total_reputation_score': total_signals,
            'reputation_score_normalized': min(1.0, total_signals / 10),
            'has_strong_reputation': total_signals >= 5
        }
    
    @staticmethod
    def parse_professional_maturity(text: str) -> ProfessionalMaturityData:
        """Extrai dados de maturidade profissional."""
        # Buscar experiência em anos
        exp_patterns = [r'(\d+)\s*anos?\s*de\s*experiência', r'atuando\s*há\s*(\d+)\s*anos?']
        years_found = []
        for pattern in exp_patterns:
            matches = re.findall(pattern, text.lower())
            years_found.extend([int(m) for m in matches])
        
        experience_years = max(years_found) if years_found else 0
        
        # Buscar sinais de rede profissional
        network_signals = len(re.findall(r'\blinkedin\b|\bconexões\b|\brede\b|\bcontatos\b', text.lower()))
        
        # Buscar sinais de reputação
        reputation_signals = len(re.findall(
            r'\brecomendações?\b|\bendorsements?\b|\bavaliações?\b|\btestemunhos?\b', 
            text.lower()
        ))
        
        # Responsividade (assumir 24h se não especificado)
        responsiveness_hours = 24.0
        resp_patterns = [r'responde?\s*em\s*(\d+)\s*horas?', r'tempo\s*de\s*resposta\s*(\d+)\s*horas?']
        for pattern in resp_patterns:
            matches = re.findall(pattern, text.lower())
            if matches:
                responsiveness_hours = float(matches[0])
                break
        
        return ProfessionalMaturityData(
            experience_years=float(experience_years),
            network_strength=network_signals * 50,  # Estimativa
            reputation_signals=reputation_signals * 5,  # Estimativa
            responsiveness_hours=responsiveness_hours
        )


class LawyerEnrichmentPipeline:
    """Pipeline principal de enriquecimento de perfis de advogados."""
    
    def __init__(self):
        self.prompt_templates = AdvancedPromptTemplates()
        self.parser = EnrichmentDataParser()
        self.academic_enricher = None  # Será inicializado quando necessário
    
    async def _get_academic_enricher(self):
        """Lazy loading do AcademicEnricher."""
        if self.academic_enricher is None:
            # Importar dinamicamente para evitar dependências circulares
            try:
                from algoritmo_match import AcademicEnricher
                self.academic_enricher = AcademicEnricher()
            except ImportError:
                ENRICHMENT_LOGGER.warning("AcademicEnricher não disponível - usando fallback")
                self.academic_enricher = None
        return self.academic_enricher
    
    async def enrich_single_lawyer(
        self, 
        lawyer: Lawyer, 
        area_caso: str,
        use_openai: bool = True,
        use_perplexity: bool = True
    ) -> EnrichmentResult:
        """Enriquece um único advogado com dados de todas as features."""
        
        start_time = datetime.now()
        
        # Verificar se já tem dados suficientes
        if self._has_sufficient_data(lawyer):
            ENRICHMENT_LOGGER.info(f"Lawyer {lawyer.id} já possui dados suficientes, pulando enriquecimento")
            return EnrichmentResult(
                lawyer_id=lawyer.id,
                source="cache",
                raw_report="Dados já disponíveis",
                extracted_data={},
                success=True,
                processing_time_sec=0.0
            )
        
        # Tentar OpenAI Deep Research primeiro
        if use_openai:
            try:
                result = await self._enrich_via_openai(lawyer, area_caso)
                if result.success:
                    return result
            except Exception as e:
                ENRICHMENT_LOGGER.warning(f"OpenAI enriquecimento falhou para {lawyer.id}: {e}")
        
        # Fallback para Perplexity
        if use_perplexity:
            try:
                result = await self._enrich_via_perplexity(lawyer, area_caso)
                if result.success:
                    return result
            except Exception as e:
                ENRICHMENT_LOGGER.warning(f"Perplexity enriquecimento falhou para {lawyer.id}: {e}")
        
        # Se ambos falharam
        processing_time = (datetime.now() - start_time).total_seconds()
        return EnrichmentResult(
            lawyer_id=lawyer.id,
            source="none",
            raw_report="",
            extracted_data={},
            success=False,
            error_msg="Todas as APIs de enriquecimento falharam",
            processing_time_sec=processing_time
        )
    
    async def _enrich_via_openai(self, lawyer: Lawyer, area_caso: str) -> EnrichmentResult:
        """Enriquecimento via OpenAI Deep Research."""
        enricher = await self._get_academic_enricher()
        if not enricher:
            raise ValueError("AcademicEnricher não disponível")
        
        start_time = datetime.now()
        
        # Usar nome do advogado (CPF seria obtido de outro campo se disponível)
        prompt_data = self.prompt_templates.deep_research_complete_profile(
            nome=lawyer.nome,
            cpf="CONFIDENCIAL",  # Por questões de privacidade
            area_caso=area_caso
        )
        
        # Chamar Deep Research
        raw_report = await enricher._call_deep_research_api(prompt_data)
        
        processing_time = (datetime.now() - start_time).total_seconds()
        
        if raw_report:
            extracted_data = self._apply_all_parsers(raw_report, area_caso)
            self._update_lawyer_with_extracted_data(lawyer, extracted_data)
            
            return EnrichmentResult(
                lawyer_id=lawyer.id,
                source="openai_deep_research",
                raw_report=raw_report,
                extracted_data=extracted_data,
                success=True,
                processing_time_sec=processing_time
            )
        else:
            return EnrichmentResult(
                lawyer_id=lawyer.id,
                source="openai_deep_research",
                raw_report="",
                extracted_data={},
                success=False,
                error_msg="OpenAI Deep Research retornou resposta vazia",
                processing_time_sec=processing_time
            )
    
    async def _enrich_via_perplexity(self, lawyer: Lawyer, area_caso: str) -> EnrichmentResult:
        """Enriquecimento via Perplexity API."""
        enricher = await self._get_academic_enricher()
        if not enricher:
            raise ValueError("AcademicEnricher não disponível")
        
        start_time = datetime.now()
        
        prompt = self.prompt_templates.perplexity_complete_profile(
            nome=lawyer.nome,
            cpf="CONFIDENCIAL",
            area_caso=area_caso
        )
        
        # Chamar Perplexity
        raw_report = await enricher._call_perplexity_api(prompt)
        
        processing_time = (datetime.now() - start_time).total_seconds()
        
        if raw_report:
            extracted_data = self._apply_all_parsers(raw_report, area_caso)
            self._update_lawyer_with_extracted_data(lawyer, extracted_data)
            
            return EnrichmentResult(
                lawyer_id=lawyer.id,
                source="perplexity",
                raw_report=raw_report,
                extracted_data=extracted_data,
                success=True,
                processing_time_sec=processing_time
            )
        else:
            return EnrichmentResult(
                lawyer_id=lawyer.id,
                source="perplexity",
                raw_report="",
                extracted_data={},
                success=False,
                error_msg="Perplexity retornou resposta vazia",
                processing_time_sec=processing_time
            )
    
    def _apply_all_parsers(self, raw_report: str, area_caso: str) -> Dict[str, Any]:
        """Aplica todos os parsers no relatório e extrai dados estruturados."""
        extracted = {}
        
        try:
            # Feature S: QUALIS de publicações
            extracted['publications'] = self.parser.parse_qualis_publications(raw_report)
            
            # Feature T: Titulação acadêmica
            extracted['academic_degree'] = self.parser.parse_academic_degree(raw_report)
            
            # Feature E: Experiência prática
            extracted['practical_experience'] = self.parser.parse_practical_experience(raw_report, area_caso)
            
            # Feature M: Multidisciplinaridade
            extracted['multidisciplinary'] = self.parser.parse_multidisciplinary_work(raw_report)
            
            # Feature C: Casos complexos
            extracted['complex_cases'] = self.parser.parse_complex_cases(raw_report)
            
            # Feature P: Informações de preço
            extracted['fee_information'] = self.parser.parse_fee_information(raw_report)
            
            # Feature R: Reputação profissional
            extracted['reputation'] = self.parser.parse_professional_reputation(raw_report)
            
            # Maturidade profissional
            extracted['maturity'] = self.parser.parse_professional_maturity(raw_report)
            
        except Exception as e:
            ENRICHMENT_LOGGER.error(f"Erro ao aplicar parsers: {e}")
            extracted['parsing_error'] = str(e)
        
        return extracted
    
    def _update_lawyer_with_extracted_data(self, lawyer: Lawyer, extracted_data: Dict[str, Any]):
        """Atualiza o objeto Lawyer com os dados extraídos."""
        try:
            # Atualizar publicações (para Feature S)
            if 'publications' in extracted_data and extracted_data['publications']:
                if not hasattr(lawyer, 'academic_publications'):
                    lawyer.academic_publications = []
                lawyer.academic_publications.extend(extracted_data['publications'])
            
            # Atualizar experiência (para Feature E)
            if 'practical_experience' in extracted_data:
                exp_data = extracted_data['practical_experience']
                if exp_data.get('estimated_years', 0) > 0:
                    lawyer.curriculo_json['anos_experiencia'] = max(
                        lawyer.curriculo_json.get('anos_experiencia', 0),
                        exp_data['estimated_years']
                    )
            
            # Atualizar maturidade profissional (para Feature M)
            if 'maturity' in extracted_data:
                lawyer.maturity_data = extracted_data['maturity']
            
            # Atualizar informações de honorários (para Feature P)
            if 'fee_information' in extracted_data:
                fee_data = extracted_data['fee_information']
                if fee_data.get('preferred_fee_type') == 'hora' and not lawyer.avg_hourly_fee:
                    # Estimar taxa por hora baseada em experiência (fallback)
                    years = lawyer.curriculo_json.get('anos_experiencia', 5)
                    lawyer.avg_hourly_fee = min(200 + years * 10, 500)  # R$ 200-500/h
            
            # Marcar como enriquecido
            lawyer.scores = lawyer.scores or {}
            lawyer.scores['enriched'] = True
            lawyer.scores['enrichment_timestamp'] = datetime.now().isoformat()
            
        except Exception as e:
            ENRICHMENT_LOGGER.error(f"Erro ao atualizar lawyer {lawyer.id}: {e}")
    
    def _has_sufficient_data(self, lawyer: Lawyer) -> bool:
        """Verifica se o advogado já tem dados suficientes."""
        # Critérios básicos para considerar "suficiente"
        has_experience = lawyer.curriculo_json.get('anos_experiencia', 0) > 0
        has_qualifications = len(lawyer.curriculo_json.get('pos_graduacoes', [])) > 0
        has_maturity = lawyer.maturity_data is not None
        
        # Se já foi enriquecido recentemente (< 24h), pular
        if lawyer.scores and lawyer.scores.get('enriched'):
            enrichment_time = lawyer.scores.get('enrichment_timestamp')
            if enrichment_time:
                try:
                    last_enriched = datetime.fromisoformat(enrichment_time)
                    hours_since = (datetime.now() - last_enriched).total_seconds() / 3600
                    if hours_since < 24:  # Cache de 24h
                        return True
                except:
                    pass
        
        return has_experience and has_qualifications and has_maturity
    
    async def enrich_lawyer_batch(
        self, 
        lawyers: List[Lawyer], 
        area_caso: str,
        max_concurrent: int = 3,
        use_openai: bool = True,
        use_perplexity: bool = True
    ) -> List[EnrichmentResult]:
        """Enriquece um lote de advogados com controle de concorrência."""
        
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def enrich_with_semaphore(lawyer):
            async with semaphore:
                return await self.enrich_single_lawyer(
                    lawyer, area_caso, use_openai, use_perplexity
                )
        
        tasks = [enrich_with_semaphore(lawyer) for lawyer in lawyers]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Processar resultados e exceptions
        enrichment_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                enrichment_results.append(EnrichmentResult(
                    lawyer_id=lawyers[i].id,
                    source="error",
                    raw_report="",
                    extracted_data={},
                    success=False,
                    error_msg=str(result)
                ))
            else:
                enrichment_results.append(result)
        
        return enrichment_results


# Função principal de conveniência
async def preprocess_lawyers_for_ranking(
    lawyers: List[Lawyer],
    area_caso: str,
    max_concurrent: int = 3,
    use_openai: bool = True,
    use_perplexity: bool = True
) -> Tuple[List[Lawyer], List[EnrichmentResult]]:
    """
    Função principal: enriquece advogados antes do ranqueamento.
    
    Args:
        lawyers: Lista de advogados a serem enriquecidos
        area_caso: Área jurídica do caso para contexto
        max_concurrent: Máximo de chamadas simultâneas
        use_openai: Se deve usar OpenAI Deep Research
        use_perplexity: Se deve usar Perplexity como fallback
    
    Returns:
        Tuple com (advogados_enriquecidos, resultados_enriquecimento)
    """
    pipeline = LawyerEnrichmentPipeline()
    
    ENRICHMENT_LOGGER.info(f"Iniciando enriquecimento de {len(lawyers)} advogados para área {area_caso}")
    
    start_time = datetime.now()
    
    # Executar enriquecimento em lote
    results = await pipeline.enrich_lawyer_batch(
        lawyers, area_caso, max_concurrent, use_openai, use_perplexity
    )
    
    # Log de estatísticas
    successful = sum(1 for r in results if r.success)
    failed = len(results) - successful
    total_time = (datetime.now() - start_time).total_seconds()
    
    ENRICHMENT_LOGGER.info(f"Enriquecimento completo: {successful} sucessos, {failed} falhas, {total_time:.2f}s total")
    
    # Log detalhado por fonte
    sources = {}
    for result in results:
        sources[result.source] = sources.get(result.source, 0) + 1
    
    ENRICHMENT_LOGGER.info(f"Distribuição por fonte: {sources}")
    
    return lawyers, results


if __name__ == "__main__":
    # Teste de demonstração
    async def demo():
        from algoritmo_match import Lawyer, KPI
        
        # Criar advogado de teste
        lawyer = Lawyer(
            id="ADV_TEST",
            nome="Dr. João Silva",
            tags_expertise=["civil", "contrato"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={"anos_experiencia": 5},
            kpi=KPI(
                success_rate=0.8,
                cases_30d=10,
                avaliacao_media=4.0,
                tempo_resposta_h=24,
                active_cases=3
            )
        )
        
        # Executar enriquecimento
        enriched_lawyers, results = await preprocess_lawyers_for_ranking(
            [lawyer], 
            "Direito Civil",
            use_openai=False,  # Para demo sem API
            use_perplexity=False
        )
        
        print("✅ Pipeline de enriquecimento executada com sucesso!")
        print(f"Resultados: {len(results)} processados")
        
    import asyncio
    asyncio.run(demo()) 