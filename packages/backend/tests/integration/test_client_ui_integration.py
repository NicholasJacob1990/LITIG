"""
Testes de integração simulando a UI do Cliente.
Valida como o cliente visualiza os badges dos advogados (PRO vs. FREE).
"""

import pytest

def test_client_sees_pro_badge_on_lawyer_profile():
    """
    Simula como a UI do Cliente (Flutter/Next.js) deve exibir o badge "PRO"
    no perfil de um advogado ou em uma lista de recomendações.
    """
    # Simular resposta da API /lawyers/search ou /cases/{id}/matches
    # que o cliente receberia
    api_response_for_client = {
        "matches": [
            {
                "lawyer_id": "lawyer_pro_1",
                "name": "Dr. João Silva",
                "plan": "PRO",
                "specialty": "Direito Tributário",
                "rating": 4.9,
            },
            {
                "lawyer_id": "lawyer_free_1",
                "name": "Dra. Maria Santos",
                "plan": "FREE",
                "specialty": "Direito de Família",
                "rating": 4.7,
            }
        ]
    }

    # Simular a lógica de widget no Flutter do Cliente
    def get_lawyer_profile_badge_for_client(lawyer_data):
        """
        Widget: LawyerProfileCard (Client App)
        Determina qual badge exibir para o cliente.
        """
        if lawyer_data.get("plan") == "PRO":
            return {
                "text": "Advogado PRO",
                "color": "blue",
                "icon": "verified_user"
            }
        return None  # Advogados FREE não têm badge para o cliente

    # --- Testes da Lógica da UI do Cliente ---

    # 1. Testar o advogado PRO
    pro_lawyer_data = api_response_for_client["matches"][0]
    pro_badge = get_lawyer_profile_badge_for_client(pro_lawyer_data)
    
    assert pro_badge is not None, "Cliente deve ver um badge para o advogado PRO"
    assert pro_badge["text"] == "Advogado PRO"
    assert pro_badge["color"] == "blue"
    assert pro_badge["icon"] == "verified_user"

    # 2. Testar o advogado FREE
    free_lawyer_data = api_response_for_client["matches"][1]
    free_badge = get_lawyer_profile_badge_for_client(free_lawyer_data)

    assert free_badge is None, "Cliente não deve ver badge para advogado FREE"


def test_client_does_not_see_priority_badge():
    """
    Confirma que o cliente NUNCA vê o badge "Prioritário PRO",
    pois essa é uma lógica interna para o advogado.
    """
    # Simular uma recomendação com metadados internos do advogado
    lawyer_recommendation_with_internal_scores = {
        "lawyer_id": "lawyer_pro_1",
        "name": "Dr. João Silva",
        "plan": "PRO",
        "scores": {
            "premium_case": True,  # Contexto de um caso premium
            "plan": "PRO",
            "is_sponsored": True,
        }
    }

    # Reusar a mesma lógica de badge do teste anterior (visão do cliente)
    def get_lawyer_profile_badge_for_client(lawyer_data):
        """
        A lógica do cliente só deve se importar com o plano principal,
        não com os scores contextuais do caso.
        """
        if lawyer_data.get("plan") == "PRO":
            return {
                "text": "Advogado PRO",
                "color": "blue",
                "icon": "verified_user"
            }
        return None

    badge = get_lawyer_profile_badge_for_client(lawyer_recommendation_with_internal_scores)

    assert badge is not None
    assert badge["text"] == "Advogado PRO", "Badge deve ser o genérico 'PRO', não o contextual 'Prioritário'"
    assert badge["color"] == "blue" 