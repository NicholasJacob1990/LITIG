"""add premium_criteria table

Revision ID: 2abe36c774a1
Revises: 
Create Date: 2024-07-23 20:25:31.428445

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2abe36c774a1'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "premium_criteria",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("service_code", sa.Text, nullable=False),
        sa.Column("subservice_code", sa.Text, nullable=True),
        sa.Column("name", sa.Text, nullable=False),
        sa.Column("enabled", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("min_valor_causa", sa.Numeric, nullable=True),
        sa.Column("max_valor_causa", sa.Numeric, nullable=True),
        sa.Column("min_urgency_h", sa.Integer, nullable=True),
        sa.Column("complexity_levels", sa.ARRAY(sa.Text), server_default="{}", nullable=False),
        sa.Column("vip_client_plans", sa.ARRAY(sa.Text), server_default="{}", nullable=False),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True),
                  server_default=sa.func.now()),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True),
                  onupdate=sa.func.now()),
    )
    op.create_index("criteria_service_idx", "premium_criteria", ["service_code"])
    op.create_index("criteria_subservice_idx", "premium_criteria", ["subservice_code"])


def downgrade():
    op.drop_table("premium_criteria")
