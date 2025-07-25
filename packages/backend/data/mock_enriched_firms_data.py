"""
Mock data for enriched law firms - comprehensive dataset for testing and demonstrations
"""

from datetime import datetime, timedelta
from typing import Dict, Any

def generate_mock_firm_data() -> Dict[str, Any]:
    """Generate comprehensive mock data for law firms"""
    
    base_date = datetime.utcnow()
    
    return {
        "firm_001": {
            "id": "firm_001",
            "name": "Silva, Machado & Associados",
            "description": "Escritório de excelência em Direito Empresarial e Tributário, com mais de 25 anos de tradição no mercado brasileiro. Especialistas em fusões e aquisições, reestruturações societárias e planejamento tributário estratégico.",
            "logo_url": "https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?w=400",
            "specializations": ["Direito Empresarial", "Direito Tributário", "Fusões e Aquisições", "Compliance Corporativo", "Direito Societário"],
            "partners": [
                {
                    "id": "lawyer_001",
                    "nome": "Dr. Eduardo Silva",
                    "avatarUrl": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
                    "especialidades": ["Direito Empresarial", "M&A", "Direito Societário"],
                    "fair": 0.95,
                    "features": {
                        "successRate": 0.94,
                        "responseTime": 2,
                        "softSkills": 0.92
                    }
                },
                {
                    "id": "lawyer_002", 
                    "nome": "Dra. Carmen Machado",
                    "avatarUrl": "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150",
                    "especialidades": ["Direito Tributário", "Compliance", "Planejamento Fiscal"],
                    "fair": 0.93,
                    "features": {
                        "successRate": 0.91,
                        "responseTime": 1,
                        "softSkills": 0.89
                    }
                },
                {
                    "id": "lawyer_003",
                    "nome": "Dr. Ricardo Oliveira",
                    "avatarUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                    "especialidades": ["Fusões e Aquisições", "Direito Societário"],
                    "fair": 0.91,
                    "features": {
                        "successRate": 0.88,
                        "responseTime": 3,
                        "softSkills": 0.85
                    }
                }
            ],
            "associates": [
                {
                    "id": "lawyer_004",
                    "nome": "Dr. Felipe Santos",
                    "avatarUrl": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
                    "especialidades": ["Direito Empresarial", "Compliance"],
                    "fair": 0.84,
                    "features": {
                        "successRate": 0.82,
                        "responseTime": 4,
                        "softSkills": 0.83
                    }
                },
                {
                    "id": "lawyer_005",
                    "nome": "Dra. Juliana Costa",
                    "avatarUrl": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
                    "especialidades": ["Direito Tributário", "Contencioso"],
                    "fair": 0.86,
                    "features": {
                        "successRate": 0.84,
                        "responseTime": 3,
                        "softSkills": 0.87
                    }
                }
            ],
            "total_lawyers": 28,
            "partners_count": 3,
            "associates_count": 12,
            "specialists_count": 13,
            "specialists_by_area": {
                "Direito Empresarial": 10,
                "Direito Tributário": 8,
                "Fusões e Aquisições": 5,
                "Compliance Corporativo": 4,
                "Direito Societário": 6
            },
            "certifications": [
                {
                    "name": "ISO 27001 - Segurança da Informação",
                    "issuer": "ABNT",
                    "valid_until": "2025-12-31T23:59:59Z",
                    "certificate_url": "https://example.com/cert/iso27001.pdf",
                    "is_active": True
                },
                {
                    "name": "Certificação OAB Compliance",
                    "issuer": "OAB-SP",
                    "valid_until": "2024-12-31T23:59:59Z",
                    "is_active": True
                },
                {
                    "name": "Best Practice Certificate - Corporate Law",
                    "issuer": "Brazilian Bar Association",
                    "valid_until": "2025-06-30T23:59:59Z",
                    "is_active": True
                }
            ],
            "awards": [
                {
                    "name": "Melhor Escritório de Direito Empresarial 2023",
                    "category": "Direito Empresarial",
                    "date_received": "2023-11-15T00:00:00Z",
                    "issuer": "Chambers & Partners Brazil",
                    "description": "Reconhecimento pela excelência em assessoria jurídica empresarial e transações de M&A"
                },
                {
                    "name": "Top Law Firm Brasil 2023",
                    "category": "Geral",
                    "date_received": "2023-08-20T00:00:00Z",
                    "issuer": "The Legal 500 Latin America"
                },
                {
                    "name": "Excellence in Tax Law 2022",
                    "category": "Direito Tributário",
                    "date_received": "2022-12-10T00:00:00Z",
                    "issuer": "International Tax Review"
                }
            ],
            "location": {
                "address": "Av. Paulista, 1000 - Conjunto 1501-1510",
                "city": "São Paulo",
                "state": "SP",
                "zip_code": "01310-100",
                "country": "Brasil",
                "latitude": -23.5505,
                "longitude": -46.6333,
                "is_main_office": True,
                "nearby_landmarks": ["Estação Trianon-MASP", "MASP", "Parque Trianon", "Shopping Cidade São Paulo"]
            },
            "contact_info": {
                "phone": "+55 11 3456-7890",
                "email": "contato@silvamachado.com.br",
                "website": "https://www.silvamachado.com.br",
                "linkedin_url": "https://linkedin.com/company/silva-machado-associados",
                "social_media_urls": [
                    "https://instagram.com/silvamachadoadvocacia",
                    "https://twitter.com/silvamachado_adv"
                ],
                "whatsapp": "+55 11 99999-9999"
            },
            "data_sources": {
                "oab": {
                    "source_name": "OAB",
                    "last_updated": (base_date - timedelta(hours=2)).isoformat() + "Z",
                    "quality_score": 0.96,
                    "has_error": False
                },
                "receita_federal": {
                    "source_name": "Receita Federal",
                    "last_updated": (base_date - timedelta(hours=8)).isoformat() + "Z",
                    "quality_score": 0.92,
                    "has_error": False
                },
                "linkedin": {
                    "source_name": "LinkedIn",
                    "last_updated": (base_date - timedelta(minutes=30)).isoformat() + "Z",
                    "quality_score": 0.88,
                    "has_error": False
                },
                "website": {
                    "source_name": "Website",
                    "last_updated": (base_date - timedelta(hours=1)).isoformat() + "Z",
                    "quality_score": 0.85,
                    "has_error": False
                },
                "chambers": {
                    "source_name": "Chambers & Partners",
                    "last_updated": (base_date - timedelta(days=2)).isoformat() + "Z",
                    "quality_score": 0.94,
                    "has_error": False
                }
            },
            "overall_quality_score": 0.91,
            "completeness_score": 0.94,
            "last_consolidated": (base_date - timedelta(minutes=15)).isoformat() + "Z",
            "financial_info": {
                "revenue_range": "R$ 75M - R$ 150M",
                "founded_year": 1998,
                "legal_structure": "Sociedade Simples",
                "is_publicly_traded": False,
                "employee_count": 85,
                "office_locations": ["São Paulo", "Rio de Janeiro", "Brasília", "Porto Alegre"]
            },
            "partnerships": [
                {
                    "partner_firm_id": "firm_international_001",
                    "partner_firm_name": "Baker McKenzie",
                    "partnership_type": "International Referral",
                    "start_date": "2019-06-15T00:00:00Z",
                    "is_active": True,
                    "description": "Parceria estratégica para casos de direito internacional e transações cross-border",
                    "collaboration_areas": ["Direito Internacional", "M&A Transnacional", "Arbitragem"]
                },
                {
                    "partner_firm_id": "firm_002",
                    "partner_firm_name": "Andrade & Figueira Advocacia",
                    "partnership_type": "Regional Collaboration",
                    "start_date": "2021-03-10T00:00:00Z",
                    "is_active": True,
                    "description": "Colaboração em casos do interior de São Paulo",
                    "collaboration_areas": ["Direito Empresarial Regional"]
                }
            ],
            "stats": {
                "total_cases": 2850,
                "active_cases": 320,
                "won_cases": 2450,
                "success_rate": 0.86,
                "average_rating": 4.8,
                "total_reviews": 247,
                "average_response_time": 2.1,
                "cases_this_year": 380
            }
        },
        
        "firm_002": {
            "id": "firm_002",
            "name": "Advocacia Criminal Excellence",
            "description": "Escritório boutique especializado exclusivamente em Direito Penal e Processo Penal, com reconhecida expertise em crimes econômicos, defesa empresarial e compliance penal.",
            "logo_url": "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400",
            "specializations": ["Direito Penal", "Processo Penal", "Direito Penal Econômico", "Compliance Penal", "Defesa Empresarial"],
            "partners": [
                {
                    "id": "lawyer_010",
                    "nome": "Dr. Roberto Mendes",
                    "avatarUrl": "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150",
                    "especialidades": ["Direito Penal", "Processo Penal", "Crimes Econômicos"],
                    "fair": 0.94,
                    "features": {
                        "successRate": 0.89,
                        "responseTime": 1,
                        "softSkills": 0.95
                    }
                },
                {
                    "id": "lawyer_011",
                    "nome": "Dra. Patricia Alves",
                    "avatarUrl": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150",
                    "especialidades": ["Compliance Penal", "Direito Penal Empresarial"],
                    "fair": 0.92,
                    "features": {
                        "successRate": 0.87,
                        "responseTime": 2,
                        "softSkills": 0.91
                    }
                }
            ],
            "associates": [
                {
                    "id": "lawyer_012",
                    "nome": "Dr. André Ferreira",
                    "avatarUrl": "https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=150",
                    "especialidades": ["Direito Penal Econômico", "Lavagem de Dinheiro"],
                    "fair": 0.88,
                    "features": {
                        "successRate": 0.85,
                        "responseTime": 2,
                        "softSkills": 0.89
                    }
                }
            ],
            "total_lawyers": 12,
            "partners_count": 2,
            "associates_count": 7,
            "specialists_count": 3,
            "specialists_by_area": {
                "Direito Penal": 6,
                "Processo Penal": 5,
                "Direito Penal Econômico": 3,
                "Compliance Penal": 2,
                "Defesa Empresarial": 4
            },
            "certifications": [
                {
                    "name": "Especialização em Direito Penal",
                    "issuer": "OAB-RJ",
                    "valid_until": "2025-06-30T23:59:59Z",
                    "is_active": True
                },
                {
                    "name": "Criminal Defense Excellence Certificate",
                    "issuer": "International Association of Defense Counsel",
                    "valid_until": "2024-12-31T23:59:59Z",
                    "is_active": True
                }
            ],
            "awards": [
                {
                    "name": "Melhor Defesa Criminal 2023",
                    "category": "Direito Penal",
                    "date_received": "2023-10-10T00:00:00Z",
                    "issuer": "Revista Consultor Jurídico",
                    "description": "Reconhecimento pela excelência em defesa criminal complexa"
                },
                {
                    "name": "Top Criminal Law Firm",
                    "category": "Direito Penal",
                    "date_received": "2023-05-20T00:00:00Z",
                    "issuer": "Análise Editorial"
                }
            ],
            "location": {
                "address": "Rua da Assembleia, 50 - Sala 1020-1025",
                "city": "Rio de Janeiro",
                "state": "RJ",
                "zip_code": "20011-000",
                "country": "Brasil",
                "latitude": -22.9068,
                "longitude": -43.1729,
                "is_main_office": True,
                "nearby_landmarks": ["Centro do Rio", "Praça XV de Novembro", "Tribunal de Justiça RJ", "Palácio da Justiça"]
            },
            "contact_info": {
                "phone": "+55 21 2345-6789",
                "email": "contato@criminalexcellence.com.br",
                "website": "https://www.criminalexcellence.com.br",
                "linkedin_url": "https://linkedin.com/company/criminal-excellence",
                "whatsapp": "+55 21 98888-8888"
            },
            "data_sources": {
                "oab": {
                    "source_name": "OAB",
                    "last_updated": (base_date - timedelta(hours=3)).isoformat() + "Z",
                    "quality_score": 0.95,
                    "has_error": False
                },
                "website": {
                    "source_name": "Website",
                    "last_updated": (base_date - timedelta(hours=2)).isoformat() + "Z",
                    "quality_score": 0.82,
                    "has_error": False
                },
                "consultor_juridico": {
                    "source_name": "Consultor Jurídico",
                    "last_updated": (base_date - timedelta(days=1)).isoformat() + "Z",
                    "quality_score": 0.88,
                    "has_error": False
                }
            },
            "overall_quality_score": 0.88,
            "completeness_score": 0.79,
            "last_consolidated": (base_date - timedelta(minutes=45)).isoformat() + "Z",
            "financial_info": {
                "revenue_range": "R$ 15M - R$ 30M",
                "founded_year": 2012,
                "legal_structure": "Sociedade Simples",
                "is_publicly_traded": False,
                "employee_count": 24,
                "office_locations": ["Rio de Janeiro", "São Paulo"]
            },
            "partnerships": [
                {
                    "partner_firm_id": "firm_compliance_001",
                    "partner_firm_name": "Compliance & Integrity Partners",
                    "partnership_type": "Specialized Referral",
                    "start_date": "2020-08-15T00:00:00Z",
                    "is_active": True,
                    "description": "Parceria para casos de compliance e investigações internas",
                    "collaboration_areas": ["Compliance Penal", "Investigações Internas"]
                }
            ],
            "stats": {
                "total_cases": 890,
                "active_cases": 95,
                "won_cases": 760,
                "success_rate": 0.85,
                "average_rating": 4.9,
                "total_reviews": 124,
                "average_response_time": 1.5,
                "cases_this_year": 180
            }
        },

        "firm_003": {
            "id": "firm_003",
            "name": "Trabalhista & Previdenciário Especializado",
            "description": "Escritório de referência em Direito do Trabalho e Previdenciário, com atuação abrangente desde consultoria preventiva até grandes contenciosos trabalhistas e previdenciários.",
            "logo_url": "https://images.unsplash.com/photo-1521791055366-0d553872125f?w=400",
            "specializations": ["Direito do Trabalho", "Direito Previdenciário", "Sindical", "Segurança do Trabalho", "Contencioso Trabalhista"],
            "partners": [
                {
                    "id": "lawyer_020",
                    "nome": "Dra. Mariana Souza",
                    "avatarUrl": "https://images.unsplash.com/photo-1551836022-deb4988cc6c0?w=150",
                    "especialidades": ["Direito do Trabalho", "Contencioso Trabalhista"],
                    "fair": 0.90,
                    "features": {
                        "successRate": 0.87,
                        "responseTime": 3,
                        "softSkills": 0.88
                    }
                }
            ],
            "associates": [
                {
                    "id": "lawyer_021",
                    "nome": "Dr. Lucas Pereira",
                    "avatarUrl": "https://images.unsplash.com/photo-1559566439-85e2c0a97c1c?w=150",
                    "especialidades": ["Direito Previdenciário", "INSS"],
                    "fair": 0.86,
                    "features": {
                        "successRate": 0.84,
                        "responseTime": 4,
                        "softSkills": 0.82
                    }
                }
            ],
            "total_lawyers": 18,
            "partners_count": 1,
            "associates_count": 12,
            "specialists_count": 5,
            "specialists_by_area": {
                "Direito do Trabalho": 8,
                "Direito Previdenciário": 6,
                "Sindical": 3,
                "Segurança do Trabalho": 2,
                "Contencioso Trabalhista": 7
            },
            "certifications": [
                {
                    "name": "Especialização em Direito do Trabalho",
                    "issuer": "OAB-MG",
                    "valid_until": "2025-03-31T23:59:59Z",
                    "is_active": True
                }
            ],
            "awards": [
                {
                    "name": "Melhor Escritório Trabalhista MG 2023",
                    "category": "Direito do Trabalho",
                    "date_received": "2023-09-15T00:00:00Z",
                    "issuer": "OAB-MG"
                }
            ],
            "location": {
                "address": "Rua da Bahia, 1200 - 8º andar",
                "city": "Belo Horizonte",
                "state": "MG",
                "zip_code": "30160-012",
                "country": "Brasil",
                "latitude": -19.9167,
                "longitude": -43.9345,
                "is_main_office": True,
                "nearby_landmarks": ["Centro de BH", "Praça da Savassi", "Tribunal Regional do Trabalho"]
            },
            "contact_info": {
                "phone": "+55 31 3456-7890",
                "email": "contato@trabalhistamg.com.br",
                "website": "https://www.trabalhistamg.com.br",
                "whatsapp": "+55 31 97777-7777"
            },
            "data_sources": {
                "oab": {
                    "source_name": "OAB",
                    "last_updated": (base_date - timedelta(hours=6)).isoformat() + "Z",
                    "quality_score": 0.89,
                    "has_error": False
                },
                "trt": {
                    "source_name": "TRT",
                    "last_updated": (base_date - timedelta(hours=12)).isoformat() + "Z",
                    "quality_score": 0.85,
                    "has_error": False
                }
            },
            "overall_quality_score": 0.87,
            "completeness_score": 0.72,
            "last_consolidated": (base_date - timedelta(hours=1)).isoformat() + "Z",
            "financial_info": {
                "revenue_range": "R$ 8M - R$ 15M",
                "founded_year": 2008,
                "legal_structure": "Sociedade Simples",
                "is_publicly_traded": False,
                "employee_count": 32,
                "office_locations": ["Belo Horizonte"]
            },
            "partnerships": [],
            "stats": {
                "total_cases": 1250,
                "active_cases": 180,
                "won_cases": 1050,
                "success_rate": 0.84,
                "average_rating": 4.6,
                "total_reviews": 89,
                "average_response_time": 3.2,
                "cases_this_year": 320
            }
        },

        "firm_004": {
            "id": "firm_004", 
            "name": "Inovação Jurídica & Tecnologia",
            "description": "Escritório full-service de nova geração, especializado em Direito Digital, Proteção de Dados, Propriedade Intelectual e assessoria jurídica para startups e scale-ups.",
            "logo_url": "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=400",
            "specializations": ["Direito Digital", "LGPD", "Propriedade Intelectual", "Startups", "Contratos de Tecnologia"],
            "partners": [
                {
                    "id": "lawyer_030",
                    "nome": "Dr. Gabriel Tech",
                    "avatarUrl": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
                    "especialidades": ["Direito Digital", "LGPD", "Contratos Tech"],
                    "fair": 0.89,
                    "features": {
                        "successRate": 0.86,
                        "responseTime": 2,
                        "softSkills": 0.90
                    }
                }
            ],
            "associates": [
                {
                    "id": "lawyer_031",
                    "nome": "Dra. Sofia Innovation",
                    "avatarUrl": "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150",
                    "especialidades": ["Propriedade Intelectual", "Startups"],
                    "fair": 0.85,
                    "features": {
                        "successRate": 0.83,
                        "responseTime": 3,
                        "softSkills": 0.88
                    }
                }
            ],
            "total_lawyers": 15,
            "partners_count": 1,
            "associates_count": 9,
            "specialists_count": 5,
            "specialists_by_area": {
                "Direito Digital": 6,
                "LGPD": 4,
                "Propriedade Intelectual": 3,
                "Startups": 5,
                "Contratos de Tecnologia": 4
            },
            "certifications": [
                {
                    "name": "LGPD Specialist Certificate",
                    "issuer": "IAPP - International Association of Privacy Professionals",
                    "valid_until": "2024-12-31T23:59:59Z",
                    "is_active": True
                }
            ],
            "awards": [
                {
                    "name": "Most Innovative Law Firm 2023",
                    "category": "Inovação",
                    "date_received": "2023-11-30T00:00:00Z",
                    "issuer": "Legal Innovation Awards"
                }
            ],
            "location": {
                "address": "Rua Fidêncio Ramos, 308 - Vila Olímpia",
                "city": "São Paulo",
                "state": "SP",
                "zip_code": "04551-010",
                "country": "Brasil",
                "latitude": -23.5955,
                "longitude": -46.6890,
                "is_main_office": True,
                "nearby_landmarks": ["Vila Olímpia", "Shopping Vila Olímpia", "Estação Vila Olímpia"]
            },
            "contact_info": {
                "phone": "+55 11 3456-7890",
                "email": "hello@inovacaojuridica.com.br",
                "website": "https://www.inovacaojuridica.com.br",
                "linkedin_url": "https://linkedin.com/company/inovacao-juridica",
                "whatsapp": "+55 11 96666-6666"
            },
            "data_sources": {
                "website": {
                    "source_name": "Website",
                    "last_updated": (base_date - timedelta(minutes=20)).isoformat() + "Z",
                    "quality_score": 0.91,
                    "has_error": False
                },
                "linkedin": {
                    "source_name": "LinkedIn",
                    "last_updated": (base_date - timedelta(minutes=35)).isoformat() + "Z",
                    "quality_score": 0.88,
                    "has_error": False
                }
            },
            "overall_quality_score": 0.83,
            "completeness_score": 0.68,
            "last_consolidated": (base_date - timedelta(minutes=10)).isoformat() + "Z",
            "financial_info": {
                "revenue_range": "R$ 5M - R$ 12M",
                "founded_year": 2019,
                "legal_structure": "Sociedade Simples",
                "is_publicly_traded": False,
                "employee_count": 28,
                "office_locations": ["São Paulo"]
            },
            "partnerships": [
                {
                    "partner_firm_id": "tech_accelerator_001",
                    "partner_firm_name": "TechStars Brazil",
                    "partnership_type": "Strategic Partnership",
                    "start_date": "2022-01-15T00:00:00Z",
                    "is_active": True,
                    "description": "Parceria para assessoria jurídica de startups aceleradas",
                    "collaboration_areas": ["Startups", "Venture Capital", "Contratos Tech"]
                }
            ],
            "stats": {
                "total_cases": 450,
                "active_cases": 85,
                "won_cases": 380,
                "success_rate": 0.84,
                "average_rating": 4.7,
                "total_reviews": 67,
                "average_response_time": 2.8,
                "cases_this_year": 150
            }
        }
    }

# Export the data
ENRICHED_FIRMS_MOCK_DATA = generate_mock_firm_data() 