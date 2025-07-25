"""
Testes de integração simulando como a UI Flutter deve consumir 
os metadados de casos premium e exibir badges corretos.
"""

import pytest
from unittest.mock import Mock


def test_flutter_case_card_premium_badge():
    """
    Simula como o Flutter deve renderizar badges baseado nos metadados da API.
    """
    # Simular resposta da API /cases/{id}/recommendations
    api_response = {
        "case": {
            "id": "case_123",
            "is_premium": True,
            "area": "Direito Tributário",
            "status": "ABERTO"
        },
        "recommendations": [
            {
                "lawyer_id": "lawyer_pro_1",
                "name": "Dr. João Silva",
                "plan": "PRO",
                "scores": {
                    "premium_case": True,
                    "plan": "PRO", 
                    "is_sponsored": True,
                    "fair_base": 0.78
                }
            },
            {
                "lawyer_id": "lawyer_free_1", 
                "name": "Dra. Maria Santos",
                "plan": "FREE",
                "scores": {
                    "premium_case": True,
                    "plan": "FREE",
                    "is_sponsored": False,
                    "fair_base": 0.70
                }
            }
        ]
    }
    
    # Simular lógica Flutter para badges
    def get_case_badge(case_data):
        """Widget: CaseBadge - determina badge do cabeçalho do caso"""
        if case_data.get("is_premium"):
            return {
                "text": "💎 Premium",
                "color": "amber",
                "icon": "star"
            }
        return None
    
    def get_lawyer_badge(recommendation):
        """Widget: LawyerCard - determina badge do advogado"""
        scores = recommendation.get("scores", {})
        
        if scores.get("premium_case") and scores.get("plan") == "PRO":
            return {
                "text": "Prioritário PRO",
                "color": "amber", 
                "icon": "priority_high"
            }
        elif scores.get("plan") == "PRO":
            return {
                "text": "PRO",
                "color": "blue",
                "icon": "verified"
            }
        return None
    
    # Testes da lógica Flutter
    case_badge = get_case_badge(api_response["case"])
    assert case_badge is not None
    assert case_badge["text"] == "💎 Premium"
    assert case_badge["color"] == "amber"
    
    # Teste advogado PRO em caso premium
    pro_lawyer = api_response["recommendations"][0]
    pro_badge = get_lawyer_badge(pro_lawyer)
    assert pro_badge is not None
    assert pro_badge["text"] == "Prioritário PRO"
    assert pro_badge["color"] == "amber"
    
    # Teste advogado FREE em caso premium (sem badge especial)
    free_lawyer = api_response["recommendations"][1]
    free_badge = get_lawyer_badge(free_lawyer)
    assert free_badge is None  # FREE não ganha badge em caso premium


def test_flutter_case_preview_vs_accepted():
    """
    Simula como Flutter deve mostrar diferentes estados do caso.
    """
    # Caso em preview (antes do aceite)
    preview_response = {
        "id": "case_456",
        "is_premium": True,
        "area": "Direito Trabalhista",
        "valor_faixa": "R$ 100-300 mil",  # Valor em faixa
        "complexity": "HIGH",
        "status": "ABERTO",
        # Dados sensíveis ausentes:
        # "cliente_nome", "cliente_email", "valor_causa"
    }
    
    # Caso após aceite (dados completos)
    accepted_response = {
        "id": "case_456", 
        "is_premium": True,
        "area": "Direito Trabalhista",
        "valor_causa": 150000,  # Valor exato
        "complexity": "HIGH",
        "status": "ACEITO",
        "cliente_nome": "João Silva",
        "cliente_email": "joao@example.com",
        "accepted_by": "lawyer_pro_1"
    }
    
    # Simular lógica Flutter de exibição
    def should_show_client_data(case_data):
        """Determina se pode mostrar dados do cliente"""
        return case_data.get("status") == "ACEITO" and "cliente_nome" in case_data
    
    def get_valor_display(case_data):
        """Determina como mostrar o valor"""
        if "valor_causa" in case_data:
            # Formatação brasileira: R$ 150.000,00
            valor = case_data['valor_causa']
            return f"R$ {valor:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.')
        elif "valor_faixa" in case_data:
            return case_data["valor_faixa"]
        return "Valor não informado"
    
    # Testes de exibição
    # Preview: dados limitados
    assert not should_show_client_data(preview_response)
    assert get_valor_display(preview_response) == "R$ 100-300 mil"
    
    # Aceito: dados completos
    assert should_show_client_data(accepted_response)
    assert get_valor_display(accepted_response) == "R$ 150.000,00"


def test_flutter_premium_exclusive_window():
    """
    Simula como Flutter deve exibir janela exclusiva PRO.
    """
    # Caso premium na janela exclusiva
    case_in_window = {
        "id": "case_exclusive",
        "is_premium": True,
        "area": "Direito Civil",
        "exclusive_window_remaining_min": 45,  # 45 min restantes
        "status": "ABERTO"
    }
    
    # Caso premium fora da janela
    case_out_window = {
        "id": "case_open",
        "is_premium": True, 
        "area": "Direito Civil",
        "exclusive_window_remaining_min": 0,  # Janela expirou
        "status": "ABERTO"
    }
    
    # Simular lógica Flutter
    def get_exclusive_window_widget(case_data, user_plan):
        """Widget: ExclusiveWindow - mostra status da janela PRO"""
        remaining = case_data.get("exclusive_window_remaining_min", 0)
        is_premium = case_data.get("is_premium", False)
        
        if is_premium and remaining > 0:
            if user_plan == "PRO":
                return {
                    "type": "countdown",
                    "message": f"Acesso exclusivo PRO - {remaining}min restantes",
                    "color": "green",
                    "can_accept": True
                }
            else:
                return {
                    "type": "blocked", 
                    "message": f"Acesso exclusivo PRO - disponível em {remaining}min",
                    "color": "orange",
                    "can_accept": False
                }
        return None
    
    # Testes para usuário PRO
    pro_widget_in = get_exclusive_window_widget(case_in_window, "PRO")
    assert pro_widget_in["type"] == "countdown"
    assert pro_widget_in["can_accept"] is True
    assert "45min" in pro_widget_in["message"]
    
    # Testes para usuário FREE
    free_widget_in = get_exclusive_window_widget(case_in_window, "FREE")
    assert free_widget_in["type"] == "blocked"
    assert free_widget_in["can_accept"] is False
    assert "disponível em 45min" in free_widget_in["message"]
    
    # Caso fora da janela (todos podem ver)
    widget_out = get_exclusive_window_widget(case_out_window, "FREE")
    assert widget_out is None  # Sem widget especial


def test_flutter_recommendation_list_filtering():
    """
    Simula como Flutter deve implementar toggle de "opções patrocinadas".
    """
    # Lista de recomendações mista
    recommendations = [
        {
            "lawyer_id": "lawyer_1",
            "name": "Dr. Carlos PRO",
            "plan": "PRO",
            "scores": {"premium_case": True, "is_sponsored": True, "fair_base": 0.85}
        },
        {
            "lawyer_id": "lawyer_2", 
            "name": "Dra. Ana PRO",
            "plan": "PRO",
            "scores": {"premium_case": True, "is_sponsored": True, "fair_base": 0.80}
        },
        {
            "lawyer_id": "lawyer_3",
            "name": "Dr. João FREE",
            "plan": "FREE", 
            "scores": {"premium_case": True, "is_sponsored": False, "fair_base": 0.75}
        }
    ]
    
    # Simular filtro Flutter
    def filter_recommendations(recs, include_sponsored=True):
        """Filtro: toggle 'Incluir opções patrocinadas'"""
        if include_sponsored:
            return recs
        
        # Filtrar apenas não-patrocinados
        return [r for r in recs if not r["scores"].get("is_sponsored", False)]
    
    # Com patrocinados (padrão)
    full_list = filter_recommendations(recommendations, include_sponsored=True)
    assert len(full_list) == 3
    
    # Sem patrocinados (toggle desligado)
    organic_list = filter_recommendations(recommendations, include_sponsored=False)
    assert len(organic_list) == 1
    assert organic_list[0]["plan"] == "FREE"
    assert organic_list[0]["scores"]["is_sponsored"] is False


def test_flutter_badge_color_priority():
    """
    Testa hierarquia de cores de badges no Flutter.
    """
    test_cases = [
        {
            "scores": {"premium_case": True, "plan": "PRO", "is_sponsored": True},
            "expected_badge": {"text": "Prioritário PRO", "color": "amber"},
            "description": "Caso premium + PRO = badge dourado"
        },
        {
            "scores": {"premium_case": False, "plan": "PRO", "is_sponsored": False},  
            "expected_badge": {"text": "PRO", "color": "blue"},
            "description": "Apenas PRO = badge azul"
        },
        {
            "scores": {"premium_case": True, "plan": "FREE", "is_sponsored": False},
            "expected_badge": None,
            "description": "FREE em caso premium = sem badge"
        },
        {
            "scores": {"premium_case": False, "plan": "FREE", "is_sponsored": False},
            "expected_badge": None, 
            "description": "FREE normal = sem badge"
        }
    ]
    
    def get_priority_badge(scores):
        """Determina badge baseado em prioridade"""
        if scores.get("premium_case") and scores.get("plan") == "PRO":
            return {"text": "Prioritário PRO", "color": "amber"}
        elif scores.get("plan") == "PRO":
            return {"text": "PRO", "color": "blue"}
        return None
    
    for test_case in test_cases:
        result = get_priority_badge(test_case["scores"])
        assert result == test_case["expected_badge"], test_case["description"] 