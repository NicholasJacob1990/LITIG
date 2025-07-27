"""create case_feedback table for automl

Revision ID: 9b088d7bc53b
Revises: 2abe36c774a1
Create Date: 2025-01-26 16:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '9b088d7bc53b'
down_revision = '2abe36c774a1'
branch_labels = None
depends_on = None


def upgrade():
    """
    Criar tabela case_feedback para AutoML do algoritmo de matching.
    
    Baseado na dataclass CaseFeedback do case_match_ml_service.py
    com boas práticas de MLOps conforme plano validado.
    """
    op.create_table(
        "case_feedback",
        
        # Primary key
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        
        # Identificadores principais
        sa.Column("case_id", sa.String, nullable=False),
        sa.Column("lawyer_id", sa.String, nullable=False),
        sa.Column("client_id", sa.String, nullable=False),
        
        # Outcomes principais
        sa.Column("hired", sa.Boolean, nullable=False),
        sa.Column("client_satisfaction", sa.Numeric(2, 1), 
                 sa.CheckConstraint("client_satisfaction >= 0 AND client_satisfaction <= 5"),
                 nullable=False),
        sa.Column("case_success", sa.Boolean, nullable=False, default=False),
        sa.Column("case_outcome_value", sa.Numeric(12, 2), nullable=True),
        
        # Métricas de processo
        sa.Column("response_time_hours", sa.Numeric(5, 2), nullable=True),
        sa.Column("negotiation_rounds", sa.Integer, nullable=True),
        sa.Column("case_duration_days", sa.Integer, nullable=True),
        
        # Contexto do caso
        sa.Column("case_area", sa.String, nullable=False),
        sa.Column("case_complexity", sa.String, nullable=False, default='MEDIUM'),
        sa.Column("case_urgency_hours", sa.Integer, nullable=False, default=48),
        sa.Column("case_value_range", sa.String, nullable=False, default='unknown'),
        
        # Contexto do match
        sa.Column("lawyer_rank_position", sa.Integer, nullable=False, default=1),
        sa.Column("total_candidates", sa.Integer, nullable=False, default=5),
        sa.Column("match_score", sa.Numeric(4, 3), 
                 sa.CheckConstraint("match_score >= 0 AND match_score <= 1"),
                 nullable=False, default=0.0),
        sa.Column("features_used", postgresql.JSONB, nullable=True),
        sa.Column("preset_used", sa.String, nullable=False, default='balanced'),
        
        # Metadata
        sa.Column("feedback_source", sa.String, nullable=False, default='client'),
        sa.Column("feedback_notes", sa.Text, nullable=True),
        sa.Column("timestamp", sa.TIMESTAMP(timezone=True), nullable=False, 
                 server_default=sa.text("NOW()")),
    )
    
    # Índices otimizados conforme plano
    op.create_index("idx_case_feedback_case_id", "case_feedback", ["case_id"])
    op.create_index("idx_case_feedback_lawyer_id", "case_feedback", ["lawyer_id"])
    op.create_index("idx_case_feedback_timestamp", "case_feedback", ["timestamp"])
    
    # Índice composto para queries de ML (feedback por advogado em período)
    op.create_index("idx_case_feedback_ml_query", "case_feedback", 
                   ["lawyer_id", "timestamp", "hired"])
    
    # Índice para buffer mínimo (últimos feedbacks por timestamp)
    op.create_index("idx_case_feedback_recent", "case_feedback", 
                   ["timestamp", "feedback_source"])


def downgrade():
    """Remover tabela case_feedback e todos os índices."""
    op.drop_index("idx_case_feedback_recent", table_name="case_feedback")
    op.drop_index("idx_case_feedback_ml_query", table_name="case_feedback")
    op.drop_index("idx_case_feedback_timestamp", table_name="case_feedback")
    op.drop_index("idx_case_feedback_lawyer_id", table_name="case_feedback")
    op.drop_index("idx_case_feedback_case_id", table_name="case_feedback")
    op.drop_table("case_feedback") 