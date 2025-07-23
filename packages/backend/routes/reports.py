"""
Endpoints para geração de relatórios em PDF.
"""
from fastapi import APIRouter, Depends, HTTPException, Response
from supabase import Client

from config import get_supabase_client
from services.report_service import ReportService

router = APIRouter(
    prefix="/reports",
    tags=["Reports"],
)

@router.get("/case/{case_id}",
    summary="Gerar relatório de caso em PDF",
    description="Gera e retorna um relatório detalhado de um caso específico em formato PDF.",
    responses={
        200: {
            "content": {"application/pdf": {}},
            "description": "Relatório em PDF gerado com sucesso."
        },
        404: {"description": "Caso não encontrado."},
        500: {"description": "Erro ao gerar o relatório."}
    }
)
async def get_case_report(
    case_id: str,
    db: Client = Depends(get_supabase_client)
):
    try:
        report_service = ReportService(db)
        pdf_bytes = report_service.generate_case_report_pdf(case_id)
        
        headers = {
            'Content-Disposition': f'inline; filename="relatorio_caso_{case_id}.pdf"'
        }
        
        return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        # Log do erro seria ideal aqui
        raise HTTPException(status_code=500, detail=f"Erro interno ao gerar PDF: {e}")

@router.get("/lawyer/{lawyer_id}/performance",
    summary="Gerar relatório de performance do advogado em PDF",
    description="Gera e retorna um relatório de performance de um advogado específico em formato PDF.",
    responses={
        200: {
            "content": {"application/pdf": {}},
            "description": "Relatório em PDF gerado com sucesso."
        },
        404: {"description": "Advogado não encontrado."},
        500: {"description": "Erro ao gerar o relatório."}
    }
)
async def get_lawyer_performance_report(
    lawyer_id: str,
    db: Client = Depends(get_supabase_client)
):
    try:
        report_service = ReportService(db)
        pdf_bytes = report_service.generate_lawyer_performance_report_pdf(lawyer_id)
        
        headers = {
            'Content-Disposition': f'inline; filename="relatorio_performance_{lawyer_id}.pdf"'
        }
        
        return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno ao gerar PDF: {e}")

@router.get("/client/{client_id}/cases",
    summary="Gerar relatório de casos de um cliente em PDF",
    description="Gera e retorna um relatório com todos os casos de um cliente específico em formato PDF.",
    responses={
        200: {
            "content": {"application/pdf": {}},
            "description": "Relatório em PDF gerado com sucesso."
        },
        404: {"description": "Cliente não encontrado."},
        500: {"description": "Erro ao gerar o relatório."}
    }
)
async def get_client_cases_report(
    client_id: str,
    db: Client = Depends(get_supabase_client)
):
    try:
        report_service = ReportService(db)
        pdf_bytes = report_service.generate_client_cases_report_pdf(client_id)
        
        headers = {
            'Content-Disposition': f'inline; filename="relatorio_casos_cliente_{client_id}.pdf"'
        }
        
        return Response(content=pdf_bytes, media_type="application/pdf", headers=headers)

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno ao gerar PDF: {e}") 