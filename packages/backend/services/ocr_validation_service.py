#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/ocr_validation_service.py

Serviço de OCR e validação de documentos para o backend.
Complementa o OCR do frontend com processamento server-side e validações avançadas.
"""

import logging
import os
import re
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime
import base64
import io

# Dependências opcionais para OCR
try:
    import pytesseract
    from PIL import Image, ImageEnhance, ImageFilter
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    # Mock para quando PIL não está disponível
    class MockImage:
        class Image:
            pass
    Image = MockImage
    print("Aviso: Tesseract OCR não disponível. Para instalar: pip install pytesseract pillow")

# OCR Engines Avançados (opcionais)
try:
    from surya import OCRModel
    SURYA_AVAILABLE = True
except ImportError:
    SURYA_AVAILABLE = False

try:
    import easyocr
    EASYOCR_AVAILABLE = True
except ImportError:
    EASYOCR_AVAILABLE = False

try:
    from doctr.io import DocumentFile
    from doctr.models import ocr_predictor
    DOCTR_AVAILABLE = True
except ImportError:
    DOCTR_AVAILABLE = False

try:
    from transformers import TrOCRProcessor, VisionEncoderDecoderModel
    import torch
    TROCR_AVAILABLE = True
except ImportError:
    TROCR_AVAILABLE = False

# Validação de documentos brasileiros
try:
    from validate_docbr import CPF, CNPJ
    DOCBR_AVAILABLE = True
except ImportError:
    DOCBR_AVAILABLE = False
    print("Aviso: validate-docbr não disponível. Para instalar: pip install validate-docbr")

# Cliente OpenAI para extração avançada
try:
    import openai
    from openai import AsyncOpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

# Configuração
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
TESSERACT_CMD = os.getenv("TESSERACT_CMD", "/usr/bin/tesseract")  # Caminho do Tesseract

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class OCREngine:
    """Enum para engines de OCR disponíveis"""
    TESSERACT = "tesseract"
    SURYA = "surya"
    EASYOCR = "easyocr"
    DOCTR = "doctr"
    TROCR = "trocr"


class DocumentType:
    """Enum para tipos de documentos"""
    CPF = "cpf"
    CNPJ = "cnpj"
    RG = "rg"
    OAB = "oab"
    CONTRATO_TRABALHO = "contrato_trabalho"
    HOLERITE = "holerite"
    COMPROVANTE_PAGAMENTO = "comprovante_pagamento"
    COMPROVANTE_RESIDENCIA = "comprovante_residencia"
    PROCURACAO = "procuracao"
    PETICAO = "peticao"
    OUTROS = "outros"


class OCRValidationService:
    """
    Serviço completo de OCR e validação de documentos no backend.
    Complementa o processamento do frontend com validações server-side.
    Suporta múltiplos engines OCR para maior precisão.
    """

    def __init__(self):
        self.available_engines = []
        self.models = {}
        
        # Configurar Tesseract se disponível
        if TESSERACT_AVAILABLE:
            try:
                pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD
                self.available_engines.append(OCREngine.TESSERACT)
                logger.info("Tesseract OCR inicializado")
            except Exception as e:
                logger.warning(f"Erro ao configurar Tesseract: {e}")

        # Configurar EasyOCR se disponível
        if EASYOCR_AVAILABLE:
            try:
                self.models[OCREngine.EASYOCR] = easyocr.Reader(['pt', 'en'])
                self.available_engines.append(OCREngine.EASYOCR)
                logger.info("EasyOCR inicializado")
            except Exception as e:
                logger.warning(f"Erro ao configurar EasyOCR: {e}")

        # Configurar docTR se disponível
        if DOCTR_AVAILABLE:
            try:
                self.models[OCREngine.DOCTR] = ocr_predictor(pretrained=True)
                self.available_engines.append(OCREngine.DOCTR)
                logger.info("docTR inicializado")
            except Exception as e:
                logger.warning(f"Erro ao configurar docTR: {e}")

        # Configurar TrOCR se disponível
        if TROCR_AVAILABLE:
            try:
                self.models[OCREngine.TROCR] = {
                    'processor': TrOCRProcessor.from_pretrained('microsoft/trocr-base-printed'),
                    'model': VisionEncoderDecoderModel.from_pretrained('microsoft/trocr-base-printed')
                }
                self.available_engines.append(OCREngine.TROCR)
                logger.info("TrOCR inicializado")
            except Exception as e:
                logger.warning(f"Erro ao configurar TrOCR: {e}")

        # Cliente OpenAI para extração avançada
        if OPENAI_AVAILABLE and OPENAI_API_KEY:
            self.openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)
            self.openai_available = True
            logger.info("OpenAI OCR inicializado")
        else:
            self.openai_client = None
            self.openai_available = False

        # Validadores brasileiros
        if DOCBR_AVAILABLE:
            self.cpf_validator = CPF()
            self.cnpj_validator = CNPJ()
            self.docbr_available = True
            logger.info("Validadores brasileiros inicializados")
        else:
            self.docbr_available = False

    async def process_document_from_base64(
        self, 
        image_base64: str, 
        document_type_hint: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Processa documento a partir de string base64.
        
        Args:
            image_base64: Imagem em formato base64
            document_type_hint: Dica do tipo de documento para otimizar processamento
            
        Returns:
            Dict com dados extraídos e validações
        """
        try:
            # Decodificar imagem base64
            image_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(image_data))
            
            # Preprocessar imagem
            processed_image = self._preprocess_image(image)
            
            # Extrair texto
            text = await self._extract_text(processed_image)
            
            # Processar dados
            result = await self._process_extracted_text(text, document_type_hint)
            
            # Adicionar metadados
            result.update({
                "processing_timestamp": datetime.now().isoformat(),
                "ocr_method": self._get_ocr_method(),
                "image_processed": True,
            })
            
            logger.info(f"Documento processado com sucesso. Tipo detectado: {result.get('document_type')}")
            return result
            
        except Exception as e:
            logger.error(f"Erro no processamento do documento: {e}")
            return {
                "success": False,
                "error": str(e),
                "extracted_text": "",
                "extracted_data": {},
                "document_type": DocumentType.OUTROS,
                "validation_errors": ["Erro no processamento da imagem"]
            }

    async def validate_document_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Valida dados extraídos de documentos.
        
        Args:
            data: Dados extraídos para validação
            
        Returns:
            Dict com resultados da validação
        """
        validation_result = {
            "is_valid": True,
            "errors": [],
            "warnings": [],
            "validated_fields": {}
        }

        # Validar CPF
        if "cpf" in data and data["cpf"]:
            cpf_validation = self._validate_cpf(data["cpf"])
            validation_result["validated_fields"]["cpf"] = cpf_validation
            if not cpf_validation["is_valid"]:
                validation_result["is_valid"] = False
                validation_result["errors"].append(f"CPF inválido: {cpf_validation['error']}")

        # Validar CNPJ
        if "cnpj" in data and data["cnpj"]:
            cnpj_validation = self._validate_cnpj(data["cnpj"])
            validation_result["validated_fields"]["cnpj"] = cnpj_validation
            if not cnpj_validation["is_valid"]:
                validation_result["is_valid"] = False
                validation_result["errors"].append(f"CNPJ inválido: {cnpj_validation['error']}")

        # Validar OAB
        if "oab" in data and data["oab"]:
            oab_validation = self._validate_oab(data["oab"])
            validation_result["validated_fields"]["oab"] = oab_validation
            if not oab_validation["is_valid"]:
                validation_result["warnings"].append(f"OAB pode estar incorreta: {oab_validation['error']}")

        # Validar emails
        if "emails" in data and data["emails"]:
            for email in data["emails"]:
                email_validation = self._validate_email(email)
                if not email_validation["is_valid"]:
                    validation_result["warnings"].append(f"Email inválido: {email}")

        return validation_result

    async def enhance_with_ai(self, text: str, document_type: str) -> Dict[str, Any]:
        """
        Usa IA para extrair dados estruturados do texto OCR.
        
        Args:
            text: Texto extraído via OCR
            document_type: Tipo do documento
            
        Returns:
            Dict com dados estruturados pela IA
        """
        if not self.openai_available:
            logger.warning("OpenAI não disponível para enhancement")
            return {"enhanced": False, "reason": "OpenAI não configurada"}

        try:
            prompt = self._build_ai_extraction_prompt(text, document_type)
            
            response = await self.openai_client.chat.completions.create(
                model="gpt-4o-mini",
                response_format={"type": "json_object"},
                messages=[
                    {
                        "role": "system",
                        "content": "Você é um especialista em extração de dados de documentos brasileiros. "
                                 "Retorne apenas JSON válido com os dados extraídos."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.1,
                max_tokens=1000
            )
            
            import json
            ai_result = json.loads(response.choices[0].message.content)
            ai_result["enhanced"] = True
            ai_result["ai_confidence"] = self._calculate_ai_confidence(ai_result)
            
            logger.info("Enhancement via IA concluído com sucesso")
            return ai_result
            
        except Exception as e:
            logger.error(f"Erro no enhancement via IA: {e}")
            return {"enhanced": False, "error": str(e)}

    def _preprocess_image(self, image: Image.Image) -> Image.Image:
        """Preprocessa imagem para melhorar OCR"""
        try:
            # Converter para RGB se necessário
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Redimensionar se muito grande
            max_size = 2000
            if max(image.size) > max_size:
                image.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
            # Aplicar filtros para melhorar OCR
            image = image.filter(ImageFilter.MedianFilter())
            
            # Melhorar contraste
            enhancer = ImageEnhance.Contrast(image)
            image = enhancer.enhance(1.2)
            
            # Melhorar nitidez
            enhancer = ImageEnhance.Sharpness(image)
            image = enhancer.enhance(1.1)
            
            logger.debug("Imagem preprocessada com sucesso")
            return image
            
        except Exception as e:
            logger.warning(f"Erro no preprocessamento: {e}")
            return image

    async def _extract_text(self, image: Image.Image) -> str:
        """
        Extrai texto da imagem usando múltiplos engines OCR.
        Tenta diferentes engines e retorna o melhor resultado.
        """
        if not self.available_engines:
            logger.warning("Nenhum engine de OCR disponível")
            return ""

        results = {}
        
        # Tentar cada engine disponível
        for engine in self.available_engines:
            try:
                text = await self._extract_with_engine(image, engine)
                if text and len(text.strip()) > 0:
                    results[engine] = text
                    logger.info(f"Sucesso com {engine}: {len(text)} caracteres")
            except Exception as e:
                logger.warning(f"Erro com engine {engine}: {e}")
                continue

        # Se nenhum engine funcionou
        if not results:
            logger.error("Nenhum engine de OCR funcionou")
            return ""

        # Se apenas um engine funcionou, usar esse
        if len(results) == 1:
            return list(results.values())[0]

        # Se múltiplos engines funcionaram, escolher o melhor
        return self._select_best_result(results)

    async def _extract_with_engine(self, image: Image.Image, engine: str) -> str:
        """Extrai texto usando um engine específico"""
        
        if engine == OCREngine.TESSERACT and TESSERACT_AVAILABLE:
            config = '--psm 6 -l por'
            return pytesseract.image_to_string(image, config=config)
            
        elif engine == OCREngine.EASYOCR and EASYOCR_AVAILABLE:
            results = self.models[OCREngine.EASYOCR].readtext(image)
            return " ".join([item[1] for item in results])
            
        elif engine == OCREngine.DOCTR and DOCTR_AVAILABLE:
            # Salvar imagem temporariamente para docTR
            import tempfile
            with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
                image.save(tmp.name)
                doc = DocumentFile.from_images([tmp.name])
                result = self.models[OCREngine.DOCTR](doc)
                # Extrair texto das páginas e blocos
                text_parts = []
                for page in result.pages:
                    for block in page.blocks:
                        for line in block.lines:
                            for word in line.words:
                                text_parts.append(word.value)
                os.unlink(tmp.name)  # Limpar arquivo temporário
                return " ".join(text_parts)
                
        elif engine == OCREngine.TROCR and TROCR_AVAILABLE:
            processor = self.models[OCREngine.TROCR]['processor']
            model = self.models[OCREngine.TROCR]['model']
            
            pixel_values = processor(images=image, return_tensors="pt").pixel_values
            generated_ids = model.generate(pixel_values)
            generated_text = processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            return generated_text
            
        return ""

    def _select_best_result(self, results: Dict[str, str]) -> str:
        """
        Seleciona o melhor resultado entre múltiplos engines.
        Prioriza resultados com mais informações estruturadas.
        """
        # Scoring baseado em critérios de qualidade
        scores = {}
        
        for engine, text in results.items():
            score = 0
            
            # Pontuação por comprimento (mais texto = melhor, até um limite)
            length_score = min(len(text) / 1000, 1.0) * 30
            score += length_score
            
            # Pontuação por documentos brasileiros detectados
            if re.search(r'\d{3}\.\d{3}\.\d{3}-\d{2}', text):  # CPF
                score += 20
            if re.search(r'\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}', text):  # CNPJ
                score += 20
            if re.search(r'OAB|OAB/[A-Z]{2}', text, re.IGNORECASE):  # OAB
                score += 15
                
            # Pontuação por palavras-chave legais
            legal_keywords = ['advogado', 'cliente', 'contrato', 'processo', 'tribunal', 'ação']
            for keyword in legal_keywords:
                if keyword.lower() in text.lower():
                    score += 5
                    
            # Bonificação por engine preferido
            engine_preference = {
                OCREngine.EASYOCR: 10,    # Bom para documentos gerais
                OCREngine.TESSERACT: 8,   # Confiável e estável
                OCREngine.DOCTR: 12,      # Excelente para documentos
                OCREngine.TROCR: 15,      # Estado da arte para texto manuscrito
            }
            score += engine_preference.get(engine, 0)
            
            scores[engine] = score
            logger.info(f"Score para {engine}: {score:.1f}")

        # Retornar o texto do engine com maior score
        best_engine = max(scores.keys(), key=lambda k: scores[k])
        logger.info(f"Melhor engine selecionado: {best_engine} (score: {scores[best_engine]:.1f})")
        
        return results[best_engine]

    def _clean_extracted_text(self, text: str) -> str:
        """Limpa e normaliza texto extraído"""
        if not text:
            return ""
        
        # Remover quebras de linha desnecessárias
        text = re.sub(r'\n+', '\n', text)
        
        # Remover espaços extras
        text = re.sub(r' +', ' ', text)
        
        # Remover caracteres especiais problemáticos
        text = re.sub(r'[^\w\s\-\.,;:()\[\]/@]', '', text)
        
        return text.strip()

    async def _process_extracted_text(
        self, 
        text: str, 
        document_type_hint: Optional[str] = None
    ) -> Dict[str, Any]:
        """Processa texto extraído e retorna dados estruturados"""
        
        # Detectar tipo de documento
        detected_type = self._detect_document_type(text, document_type_hint)
        
        # Extrair dados básicos
        extracted_data = self._extract_basic_data(text)
        
        # Validar dados extraídos
        validation_result = await self.validate_document_data(extracted_data)
        
        # Enhancement via IA se disponível
        ai_enhancement = await self.enhance_with_ai(text, detected_type)
        
        result = {
            "success": True,
            "extracted_text": text,
            "document_type": detected_type,
            "extracted_data": extracted_data,
            "validation": validation_result,
            "ai_enhancement": ai_enhancement,
            "confidence_score": self._calculate_confidence_score(text, extracted_data)
        }
        
        return result

    def _detect_document_type(self, text: str, hint: Optional[str] = None) -> str:
        """Detecta tipo de documento baseado no texto"""
        text_lower = text.lower()
        
        # Se há hint, verificar se é compatível
        if hint and hint in [getattr(DocumentType, attr) for attr in dir(DocumentType) if not attr.startswith('_')]:
            return hint
        
        # Detectar baseado em palavras-chave
        type_keywords = {
            DocumentType.CPF: ['cpf', 'cadastro de pessoa física', 'receita federal'],
            DocumentType.CNPJ: ['cnpj', 'cadastro nacional', 'pessoa jurídica'],
            DocumentType.RG: ['rg', 'registro geral', 'carteira de identidade'],
            DocumentType.OAB: ['oab', 'ordem dos advogados', 'carteira'],
            DocumentType.CONTRATO_TRABALHO: ['contrato de trabalho', 'clt', 'empregado'],
            DocumentType.HOLERITE: ['holerite', 'contracheque', 'folha de pagamento'],
            DocumentType.COMPROVANTE_PAGAMENTO: ['comprovante', 'pagamento', 'transferência'],
            DocumentType.COMPROVANTE_RESIDENCIA: ['comprovante', 'residência', 'endereço'],
            DocumentType.PROCURACAO: ['procuração', 'outorga', 'representação'],
            DocumentType.PETICAO: ['petição', 'excelentíssimo', 'meritíssimo'],
        }
        
        for doc_type, keywords in type_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                return doc_type
        
        return DocumentType.OUTROS

    def _extract_basic_data(self, text: str) -> Dict[str, Any]:
        """Extrai dados básicos do texto"""
        data = {}
        
        # Extrair CPF
        cpf_match = re.search(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b', text)
        if cpf_match:
            data['cpf'] = cpf_match.group(0)
        
        # Extrair CNPJ
        cnpj_match = re.search(r'\b\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}\b', text)
        if cnpj_match:
            data['cnpj'] = cnpj_match.group(0)
        
        # Extrair RG
        rg_patterns = [
            r'rg[:\s]*(\d{1,2}\.?\d{3}\.?\d{3}-?\w?)',
            r'registro geral[:\s]*(\d{1,2}\.?\d{3}\.?\d{3}-?\w?)',
        ]
        for pattern in rg_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                data['rg'] = match.group(1)
                break
        
        # Extrair OAB
        oab_match = re.search(r'oab[/\s]*([a-z]{2})[:\s]*(\d+)', text, re.IGNORECASE)
        if oab_match and len(oab_match.groups()) >= 2:
            data['oab'] = f"{oab_match.group(2)}/{oab_match.group(1).upper()}"
        
        # Extrair nome
        name_patterns = [
            r'nome[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙÃÕÇ\s]+)',
            r'nome completo[:\s]+([A-ZÁÉÍÓÚÂÊÎÔÛÀÈÌÒÙÃÕÇ\s]+)',
        ]
        for pattern in name_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                name = match.group(1).strip()
                if len(name.split()) >= 2:  # Pelo menos nome e sobrenome
                    data['nome'] = name
                    break
        
        # Extrair emails
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        emails = re.findall(email_pattern, text)
        if emails:
            data['emails'] = list(set(emails))  # Remover duplicatas
        
        # Extrair telefones
        phone_pattern = r'\(?\d{2}\)?[\s-]?\d{4,5}[\s-]?\d{4}'
        phones = re.findall(phone_pattern, text)
        if phones:
            data['telefones'] = list(set(phones))
        
        return data

    def _validate_cpf(self, cpf: str) -> Dict[str, Any]:
        """Valida CPF"""
        if not self.docbr_available:
            return {"is_valid": True, "formatted": cpf, "warning": "Validação não disponível"}
        
        try:
            # Limpar CPF
            clean_cpf = re.sub(r'[^\d]', '', cpf)
            
            # Validar
            is_valid = self.cpf_validator.validate(clean_cpf)
            
            return {
                "is_valid": is_valid,
                "formatted": self.cpf_validator.mask(clean_cpf) if is_valid else cpf,
                "clean": clean_cpf
            }
        except Exception as e:
            return {"is_valid": False, "error": str(e), "original": cpf}

    def _validate_cnpj(self, cnpj: str) -> Dict[str, Any]:
        """Valida CNPJ"""
        if not self.docbr_available:
            return {"is_valid": True, "formatted": cnpj, "warning": "Validação não disponível"}
        
        try:
            # Limpar CNPJ
            clean_cnpj = re.sub(r'[^\d]', '', cnpj)
            
            # Validar
            is_valid = self.cnpj_validator.validate(clean_cnpj)
            
            return {
                "is_valid": is_valid,
                "formatted": self.cnpj_validator.mask(clean_cnpj) if is_valid else cnpj,
                "clean": clean_cnpj
            }
        except Exception as e:
            return {"is_valid": False, "error": str(e), "original": cnpj}

    def _validate_oab(self, oab: str) -> Dict[str, Any]:
        """Valida formato OAB (validação básica de formato)"""
        # Padrão: números/UF
        oab_pattern = r'^\d{4,6}/[A-Z]{2}$'
        
        if re.match(oab_pattern, oab):
            return {"is_valid": True, "formatted": oab}
        else:
            return {"is_valid": False, "error": "Formato inválido. Esperado: 123456/UF"}

    def _validate_email(self, email: str) -> Dict[str, Any]:
        """Valida formato de email"""
        email_pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'
        
        if re.match(email_pattern, email):
            return {"is_valid": True, "email": email.lower()}
        else:
            return {"is_valid": False, "error": "Formato de email inválido"}

    def _calculate_confidence_score(self, text: str, extracted_data: Dict[str, Any]) -> float:
        """Calcula score de confiança baseado no texto e dados extraídos"""
        if not text:
            return 0.0
        
        confidence = 0.5  # Base
        
        # Aumentar confiança baseado na quantidade de dados extraídos
        data_points = sum(1 for value in extracted_data.values() if value)
        confidence += min(data_points * 0.1, 0.3)
        
        # Aumentar confiança baseado no tamanho do texto
        if len(text) > 100:
            confidence += 0.1
        if len(text) > 500:
            confidence += 0.1
        
        # Reduzir confiança se o texto tem muitos caracteres especiais
        special_chars = len(re.findall(r'[^\w\s]', text))
        if special_chars > len(text) * 0.3:
            confidence -= 0.2
        
        return max(0.0, min(1.0, confidence))

    def _build_ai_extraction_prompt(self, text: str, document_type: str) -> str:
        """Constrói prompt para extração via IA"""
        return f"""
Analise o seguinte texto extraído de um documento brasileiro e extraia os dados estruturados.
Tipo de documento: {document_type}

Texto do documento:
{text}

Retorne um JSON com os seguintes campos (apenas preencha os que estiverem presentes no texto):
{{
    "nome": "Nome completo da pessoa",
    "cpf": "CPF no formato 000.000.000-00",
    "cnpj": "CNPJ no formato 00.000.000/0000-00",
    "rg": "RG",
    "oab": "Número OAB no formato 000000/UF",
    "endereco": "Endereço completo",
    "telefones": ["Lista de telefones"],
    "emails": ["Lista de emails"],
    "data_nascimento": "Data no formato DD/MM/AAAA",
    "estado_civil": "Estado civil",
    "profissao": "Profissão",
    "outros_dados": {{
        "campo_customizado": "valor"
    }}
}}

Seja preciso e retorne apenas dados que estão claramente visíveis no texto.
"""

    def _calculate_ai_confidence(self, ai_result: Dict[str, Any]) -> float:
        """Calcula confiança baseada no resultado da IA"""
        if not ai_result or "enhanced" not in ai_result or not ai_result["enhanced"]:
            return 0.0
        
        # Contar campos preenchidos
        filled_fields = sum(1 for key, value in ai_result.items() 
                          if key not in ["enhanced", "ai_confidence"] and value)
        
        # Confiança baseada na quantidade de dados extraídos
        return min(filled_fields * 0.15, 0.9)

    def _get_ocr_method(self) -> str:
        """Retorna método de OCR utilizado"""
        if self.available_engines:
            return f"Multi-engine: {', '.join(self.available_engines)}"
        else:
            return "fallback"

    def get_available_engines(self) -> Dict[str, bool]:
        """Retorna informações sobre engines OCR disponíveis"""
        return {
            OCREngine.TESSERACT: TESSERACT_AVAILABLE and OCREngine.TESSERACT in self.available_engines,
            OCREngine.EASYOCR: EASYOCR_AVAILABLE and OCREngine.EASYOCR in self.available_engines,
            OCREngine.DOCTR: DOCTR_AVAILABLE and OCREngine.DOCTR in self.available_engines,
            OCREngine.TROCR: TROCR_AVAILABLE and OCREngine.TROCR in self.available_engines,
            OCREngine.SURYA: SURYA_AVAILABLE and OCREngine.SURYA in self.available_engines,
        }

    def get_engine_info(self) -> Dict[str, Any]:
        """Retorna informações detalhadas sobre engines OCR"""
        return {
            "available_engines": self.available_engines,
            "total_engines": len(self.available_engines),
            "engine_status": self.get_available_engines(),
            "openai_available": self.openai_available,
            "recommended_engine": self._get_recommended_engine(),
        }

    def _get_recommended_engine(self) -> str:
        """Retorna o engine recomendado baseado na disponibilidade"""
        if OCREngine.TROCR in self.available_engines:
            return OCREngine.TROCR
        elif OCREngine.DOCTR in self.available_engines:
            return OCREngine.DOCTR
        elif OCREngine.EASYOCR in self.available_engines:
            return OCREngine.EASYOCR
        elif OCREngine.TESSERACT in self.available_engines:
            return OCREngine.TESSERACT
        else:
            return "none" 